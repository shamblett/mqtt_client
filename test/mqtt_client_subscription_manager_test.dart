@Timeout(const Duration(seconds: 1))
/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'mqtt_client_test_connection_handler.dart';
import 'package:observable/observable.dart';
import 'package:typed_data/typed_data.dart' as typed;

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {}

class MockCON extends Mock implements MqttConnection {}

final TestConnectionHandlerNoSend testCHNS = new TestConnectionHandlerNoSend();
final TestConnectionHandlerSend testCHS = new TestConnectionHandlerSend();

void main() {
  group("Manager", () {
    test("Subscription request creates pending subscription", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const String topic = "testtopic";
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(testCHS.sentMessages[0], new isInstanceOf<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atMostOnce);
    });
    test("Acknowledged subscription request creates active subscription", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const String topic = "testtopic";
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(testCHS.sentMessages[0], new isInstanceOf<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atMostOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = new MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
    });
    test(
        "Acknowledged subscription request for no pending subscription is ignored",
            () {
          testCHS.sentMessages.clear();
          final PublishingManager pm = new PublishingManager(testCHS);
          const String topic = "testtopic";
          const MqttQos qos = MqttQos.atLeastOnce;
          final SubscriptionsManager subs = new SubscriptionsManager(
              testCHS, pm);
          subs.registerSubscription(topic, qos);
          expect(
              subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
          expect(testCHS.sentMessages[0],
              new isInstanceOf<MqttSubscribeMessage>());
          final MqttSubscribeMessage msg = testCHS.sentMessages[0];
          expect(msg.payload.subscriptions.containsKey(topic), isTrue);
          expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
          expect(msg.variableHeader.messageIdentifier, 1);
          expect(msg.header.qos, MqttQos.atMostOnce);
          // Confirm the subscription
          final MqttSubscribeAckMessage subAckMsg = new MqttSubscribeAckMessage()
              .withMessageIdentifier(2)
              .addQosGrant(MqttQos.atLeastOnce);
          subs.confirmSubscription(subAckMsg);
          expect(
              subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
        });
    test("Get subscription with valid topic returns subscription", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const String topic = "testtopic";
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(testCHS.sentMessages[0], new isInstanceOf<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atMostOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = new MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      expect(subs.subscriptions[topic], new isInstanceOf<Subscription>());
    });
    test("Get subscription with invalid topic returns null", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const String topic = "testtopic";
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(testCHS.sentMessages[0], new isInstanceOf<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atMostOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = new MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      expect(subs.subscriptions["abc_badTopic"], isNull);
    });
    test("Get subscription for pending subscription returns null", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const String topic = "testtopic";
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(testCHS.sentMessages[0], new isInstanceOf<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atMostOnce);
      expect(subs.subscriptions[topic], isNull);
    });
    test("Unsubscribe with ack", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const String topic = "testtopic";
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(testCHS.sentMessages[0], new isInstanceOf<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atMostOnce);
      expect(subs.subscriptions[topic], isNull);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = new MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      // Unsubscribe
      subs.unsubscribe(topic);
      expect(
          testCHS.sentMessages[1], new isInstanceOf<MqttUnsubscribeMessage>());
      final MqttUnsubscribeMessage unSub = testCHS.sentMessages[1];
      expect(unSub.variableHeader.messageIdentifier, 1);
      expect(unSub.payload.subscriptions.length, 1);
      expect(unSub.payload.subscriptions[0], topic);
      // Unsubscribe ack
      final MqttUnsubscribeAckMessage unsubAck =
      new MqttUnsubscribeAckMessage().withMessageIdentifier(1);
      subs.confirmUnsubscribe(unsubAck);
      expect(
          subs.getSubscriptionsStatus(topic), SubscriptionStatus.doesNotExist);
    });
    test("Change notification", () {
      int recCount = 0;
      const String topic = "testtopic";
      StreamSubscription st;
      ChangeNotifier<MqttReceivedMessage> cn;
      void subRec(List<MqttReceivedMessage> c) {
        expect(c[0].topic, topic);
        expect(c[0].payload, new isInstanceOf<MqttPublishMessage>());
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        if (recCount == 0) {
          expect(recMess.variableHeader.messageIdentifier, 1);
          expect(MqttPublishPayload.bytesToString(recMess.payload.message),
              "<100><101><97><100>");
          expect(recMess.header.qos, MqttQos.atLeastOnce);
          recCount++;
        } else {
          expect(recMess.variableHeader.messageIdentifier, 2);
          expect(MqttPublishPayload.bytesToString(recMess.payload.message),
              "<109><101><97><116>");
          expect(recMess.header.qos, MqttQos.atMostOnce);
        }
      }
      final t1 = expectAsync1(subRec, count: 1);
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs = new SubscriptionsManager(testCHS, pm);
      cn = subs.registerSubscription(topic, qos);
      // Start listening
      st = cn.changes.listen(subRec);
      // Publish messages on the topic
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 'd'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'a'.codeUnitAt(0);
      buff[3] = 'd'.codeUnitAt(0);
      final MqttPublishMessage pubMess = new MqttPublishMessage()
          .publishData(buff)
          .toTopic(topic)
          .withMessageIdentifier(1)
          .withQos(MqttQos.atLeastOnce);
      pm.handlePublish(pubMess);
      buff[0] = 'm'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'a'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final MqttPublishMessage pubMess1 = new MqttPublishMessage()
          .publishData(buff)
          .toTopic(topic)
          .withMessageIdentifier(2)
          .withQos(MqttQos.atMostOnce);
      pm.handlePublish(pubMess1);
      //Stop listening
      st.cancel();
    });
  });
}
