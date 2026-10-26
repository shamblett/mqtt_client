import 'package:event_bus/event_bus.dart' as events;
import 'package:mocktail/mocktail.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart';

// MQTT 3.1.1 section 2.3.1, MQTT-2.3.1-2 and MQTT-2.3.1-3:
// https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html
// New outbound exchanges need an unused ID until their final acknowledgement.
class _Connection extends Mock implements MqttConnectionHandlerBase {
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus()
    ..state = MqttConnectionState.connected;

  final sent = <MqttMessage>[];
  int qos0Count = 0;
  void Function(MqttMessage)? onSend;

  @override
  void sendMessage(MqttMessage? message) {
    if (message is MqttPublishMessage &&
        message.header!.qos == MqttQos.atMostOnce) {
      qos0Count++;
    } else {
      sent.add(message!);
    }
    onSend?.call(message!);
  }
}

class _Client extends MqttClient {
  _Client(
    _Connection connection,
    PublishingManager publishing,
    SubscriptionsManager subscriptions,
  ) : super('localhost', 'packet-id-test') {
    connectionHandler = connection;
    publishingManager = publishing;
    subscriptionsManager = subscriptions;
  }
}

void main() {
  late MqttEventBus bus;
  late _Connection connection;
  late PublishingManager publishing;
  late SubscriptionsManager subscriptions;
  final payload = Uint8Buffer()..add(42);

  setUp(() {
    MessageIdentifierDispenser().reset();
    bus = MqttEventBus.fromEventBus(events.EventBus());
    connection = _Connection();
    publishing = PublishingManager(connection, bus);
    subscriptions = SubscriptionsManager(connection, publishing, bus);
    addTearDown(() {
      publishing.published.close();
      subscriptions.closeSubscriptionNotifier();
      bus.destroy();
    });
  });

  int publish([MqttQos qos = MqttQos.atLeastOnce]) =>
      publishing.publish(PublicationTopic('telemetry'), qos, payload);

  void before(int id) {
    final dispenser = MessageIdentifierDispenser();
    final previous = id == 1
        ? MessageIdentifierDispenser.maxMessageIdentifier - 1
        : id - 1;
    for (var i = 0; i < MessageIdentifierDispenser.maxMessageIdentifier; i++) {
      if (dispenser.mid == previous) return;
      dispenser.getNextMessageIdentifier();
    }
    fail('Could not position the shared cursor before $id');
  }

  Subscription subscribe(String topic) =>
      subscriptions.registerSubscription(topic, MqttQos.atLeastOnce)!;

  void suback(Subscription sub, [MqttQos grant = MqttQos.atLeastOnce]) {
    subscriptions.confirmSubscription(
      MqttSubscribeAckMessage()
          .withMessageIdentifier(sub.messageIdentifier!)
          .addQosGrant(grant),
    );
  }

  void occupyAllPublishIds() {
    final message = MqttPublishMessage();
    for (
      var id = 1;
      id < MessageIdentifierDispenser.maxMessageIdentifier;
      id++
    ) {
      publishing.publishedMessages[id] = message;
    }
  }

  test(
    'preserves the range, singleton and allocation sequence across clients',
    () {
      final dispenser = MessageIdentifierDispenser();
      final other = PublishingManager(_Connection(), bus);
      addTearDown(other.published.close);
      expect(MessageIdentifierDispenser.maxMessageIdentifier, 32768);
      expect(publishing.messageIdentifierDispenser, same(dispenser));
      expect(subscriptions.messageIdentifierDispenser, same(dispenser));
      expect(other.messageIdentifierDispenser, same(dispenser));
      expect(publish(), 1);
      expect(
        other.publish(PublicationTopic('other'), MqttQos.atLeastOnce, payload),
        2,
      );
      expect(subscribe('commands').messageIdentifier, 3);
    },
  );

  test('MQTT-2.3.1-3: PUBACK releases only its own publish', () async {
    final completed = <MqttPublishMessage>[];
    final listener = publishing.published.stream.listen(completed.add);
    addTearDown(listener.cancel);
    final first = publish();
    final original = publishing.publishedMessages[first];
    final second = publish();
    publishing.handlePublishAcknowledgement(
      MqttPublishAckMessage().withMessageIdentifier(first),
    );
    await pumpEventQueue();
    expect(completed, [same(original)]);
    expect(publishing.publishedMessages.keys, [second]);
    before(first);
    expect(publish(), first);
    expect(publishing.publishedMessages, hasLength(2));
  });

  test('MQTT-2.3.1-3: PUBREC retains a QoS 2 ID until PUBCOMP', () {
    final first = publish(MqttQos.exactlyOnce);
    publishing.handlePublishReceived(
      MqttPublishReceivedMessage().withMessageIdentifier(first),
    );
    final release = connection.sent.last as MqttPublishReleaseMessage;
    expect(release.variableHeader.messageIdentifier, first);
    before(first);
    expect(publish(), isNot(first));
    publishing.handlePublishComplete(
      MqttPublishCompleteMessage().withMessageIdentifier(first),
    );
    before(first);
    expect(publish(), first);
  });

  for (final batch in [false, true]) {
    test(
      'PUBLISH and SUBSCRIBE exclude each other while pending (batch: $batch)',
      () {
        final first = publish();
        before(first);
        final sub = batch
            ? subscriptions.registerBatchSubscription([
                BatchSubscription('commands', MqttQos.atLeastOnce),
              ])!
            : subscribe('commands');
        expect(sub.messageIdentifier, 2);
        before(first);
        expect(publish(), 3);
      },
    );
  }

  test('a confirmed SUBSCRIBE ID is available for publishing', () {
    final sub = subscribe('commands');
    suback(sub);
    before(sub.messageIdentifier!);
    expect(publish(), sub.messageIdentifier);
    expect(subscriptions.subscriptions[sub.messageIdentifier], same(sub));
  });

  test('a failed SUBACK releases its identifier', () {
    final sub = subscribe('commands');
    suback(sub, MqttQos.failure);
    before(sub.messageIdentifier!);
    expect(publish(), sub.messageIdentifier);
  });

  test(
    'new subscriptions do not overwrite confirmed subscription map keys',
    () {
      final first = subscribe('one');
      suback(first);
      before(first.messageIdentifier!);
      final second = subscribe('two');
      suback(second);
      expect(second.messageIdentifier, isNot(first.messageIdentifier));
      expect(subscriptions.subscriptions.values, containsAll([first, second]));
    },
  );

  for (final multi in [false, true]) {
    for (final expectAcknowledge in [false, true]) {
      test(
        'UNSUBSCRIBE stays occupied until UNSUBACK (multi: $multi, callback waits: $expectAcknowledge)',
        () {
          final sub = subscribe('one');
          suback(sub);
          var callbacks = 0;
          subscriptions.onUnsubscribed = (_) => callbacks++;
          if (multi) {
            subscriptions.unsubscribeMulti([
              MultiUnsubscription('one', MqttQos.atLeastOnce),
            ], expectAcknowledge: expectAcknowledge);
          } else {
            subscriptions.unsubscribe(
              'one',
              expectAcknowledge: expectAcknowledge,
            );
          }
          final request = connection.sent.last as MqttUnsubscribeMessage;
          final id = request.variableHeader!.messageIdentifier!;
          expect(callbacks, expectAcknowledge ? 0 : 1);
          before(id);
          expect(publish(), isNot(id));
          before(id);
          expect(subscribe('two').messageIdentifier, isNot(id));
          subscriptions.confirmUnsubscribe(
            MqttUnsubscribeAckMessage().withMessageIdentifier(id),
          );
          before(id);
          expect(publish(), id);
          expect(callbacks, 1);
          expect(subscriptions.pendingUnsubscriptions, isEmpty);
        },
      );
    }
  }

  test('UNSUBSCRIBE skips an ID belonging to a pending publish', () {
    final sub = subscribe('one');
    suback(sub);
    final id = publish();
    before(id);
    subscriptions.unsubscribe('one');
    final request = connection.sent.last as MqttUnsubscribeMessage;
    expect(request.variableHeader!.messageIdentifier, isNot(id));
  });

  test('UNSUBSCRIBE is tracked before synchronous send callbacks run', () {
    final sub = subscribe('one');
    suback(sub);
    int? publishId;
    int? unsubscribeId;
    connection.onSend = (message) {
      if (message is MqttUnsubscribeMessage) {
        unsubscribeId = message.variableHeader!.messageIdentifier;
        before(unsubscribeId!);
        publishId = publish();
      }
    };
    subscriptions.unsubscribe('one');
    expect(publishId, isNotNull);
    expect(publishId, isNot(unsubscribeId));
  });

  test('occupancy belongs to a client, not the shared cursor', () {
    final first = publish();
    final other = PublishingManager(_Connection(), bus);
    addTearDown(other.published.close);
    before(first);
    expect(
      other.publish(PublicationTopic('other'), MqttQos.atLeastOnce, payload),
      first,
    );
    expect(publishing.publishedMessages, hasLength(1));
    expect(other.publishedMessages, hasLength(1));
  });

  test('inbound identifiers do not reserve outbound identifiers', () {
    publishing.manuallyAcknowledgeQos1 = true;
    publishing.handlePublish(
      MqttPublishMessage()
          .toTopic('incoming')
          .withMessageIdentifier(1)
          .withQos(MqttQos.atLeastOnce)
          .publishData(payload),
    );
    expect(publishing.awaitingManualAcknowledge.containsKey(1), isTrue);
    expect(publish(), 1);
  });

  test('public publish reports exhaustion and can retry after PUBACK', () {
    final client = _Client(connection, publishing, subscriptions);
    occupyAllPublishIds();
    final original = publishing.publishedMessages[1];
    for (final qos in [MqttQos.atLeastOnce, MqttQos.exactlyOnce]) {
      expect(
        () => client.publishMessage('telemetry', qos, payload),
        throwsA(isA<NoMessageIdentifiersException>()),
      );
    }
    expect(connection.sent, isEmpty);
    expect(
      () => client.publishMessage('telemetry', MqttQos.atMostOnce, payload),
      returnsNormally,
    );
    expect(connection.qos0Count, 1);
    expect(publishing.publishedMessages[1], same(original));
    expect(publishing.publishedMessages, hasLength(32767));

    publishing.handlePublishAcknowledgement(
      MqttPublishAckMessage().withMessageIdentifier(1),
    );
    expect(client.publishMessage('telemetry', MqttQos.atLeastOnce, payload), 1);
    expect(connection.sent, hasLength(1));
  });

  test('public publish still reports invalid topics', () {
    final client = _Client(connection, publishing, subscriptions);
    expect(
      () => client.publishMessage('invalid/#', MqttQos.atLeastOnce, payload),
      throwsA(isA<InvalidTopicException>()),
    );
    expect(connection.sent, isEmpty);
    expect(publishing.publishedMessages, isEmpty);
  });

  test('exhaustion preserves single and batch subscribe failure behavior', () {
    occupyAllPublishIds();
    final failed = <String>[];
    subscriptions.onSubscribeFail = failed.add;
    expect(
      subscriptions.registerSubscription('single', MqttQos.atLeastOnce),
      isNull,
    );
    expect(failed, ['single']);
    expect(
      subscriptions.registerBatchSubscription([
        BatchSubscription('batch', MqttQos.atLeastOnce),
      ]),
      isNull,
    );
    expect(failed, ['single']);
    expect(connection.sent, isEmpty);
    expect(subscriptions.pendingSubscriptions, isEmpty);
  });

  test('exhaustion leaves unsubscribe state and callbacks untouched', () {
    final sub = subscribe('one');
    suback(sub);
    connection.sent.clear();
    var callbacks = 0;
    subscriptions.onUnsubscribed = (_) => callbacks++;
    occupyAllPublishIds();
    final client = _Client(connection, publishing, subscriptions);
    expect(
      () => client.unsubscribe('one'),
      throwsA(isA<NoMessageIdentifiersException>()),
    );
    expect(
      () => client.unsubscribeMulti([
        MultiUnsubscription('one', MqttQos.atLeastOnce),
      ]),
      throwsA(isA<NoMessageIdentifiersException>()),
    );
    expect(connection.sent, isEmpty);
    expect(subscriptions.subscriptions.values, [same(sub)]);
    expect(subscriptions.pendingUnsubscriptions, isEmpty);
    expect(callbacks, 0);
  });

  test(
    'reconnect retains existing pending-unsubscribe callback tracking',
    () async {
      final sub = subscribe('one');
      suback(sub);
      subscriptions.unsubscribe('one', expectAcknowledge: true);
      final request = connection.sent.last as MqttUnsubscribeMessage;
      final id = request.variableHeader!.messageIdentifier!;
      subscriptions.resubscribeOnAutoReconnect = false;
      bus.fire(Resubscribe(fromAutoReconnect: true));
      await pumpEventQueue();
      expect(subscriptions.pendingUnsubscriptions[id], same(sub));
      before(id);
      expect(publish(), isNot(id));
    },
  );

  test(
    'reconnect releases tracking for unsubscriptions with immediate callbacks',
    () async {
      final sub = subscribe('one');
      suback(sub);
      subscriptions.unsubscribe('one');
      final request = connection.sent.last as MqttUnsubscribeMessage;
      final id = request.variableHeader!.messageIdentifier!;
      subscriptions.resubscribeOnAutoReconnect = false;
      bus.fire(Resubscribe(fromAutoReconnect: true));
      await pumpEventQueue();
      before(id);
      expect(publish(), id);
    },
  );
}
