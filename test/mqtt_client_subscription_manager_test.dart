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
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_test_connection_handler.dart';

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {}

class MockCON extends Mock implements MqttNormalConnection {}

final TestConnectionHandlerNoSend testCHNS = TestConnectionHandlerNoSend();
final TestConnectionHandlerSend testCHS = TestConnectionHandlerSend();

void main() {
  group('Manager', () {
    test('Subscription request creates pending subscription', () {
      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
    });
    test('Acknowledged subscription request creates active subscription', () {
      bool cbCalled = false;
      void subCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onSubscribed = subCallback;
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      expect(cbCalled, isTrue);
    });
    test(
        'Acknowledged subscription request for no pending subscription is ignored',
        () {
      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
    });
    test('Get subscription with valid topic returns subscription', () {
      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      expect(subs.subscriptions[topic], const TypeMatcher<Subscription>());
    });
    test('Get subscription with invalid topic returns null', () {
      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      expect(subs.subscriptions['abc_badTopic'], isNull);
    });
    test('Get subscription for pending subscription returns null', () {
      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      expect(subs.subscriptions[topic], isNull);
    });
    test('Unsubscribe with ack', () {
      bool cbCalled = false;
      void unsubCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const String topic = 'testtopic';
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      subs.onUnsubscribed = unsubCallback;
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      expect(subs.subscriptions[topic], isNull);
      // Confirm the subscription
      final MqttSubscribeAckMessage subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), SubscriptionStatus.active);
      // Unsubscribe
      subs.unsubscribe(topic);
      expect(
          testCHS.sentMessages[1], const TypeMatcher<MqttUnsubscribeMessage>());
      final MqttUnsubscribeMessage unSub = testCHS.sentMessages[1];
      expect(unSub.variableHeader.messageIdentifier, 2);
      expect(unSub.payload.subscriptions.length, 1);
      expect(unSub.payload.subscriptions[0], topic);
      // Unsubscribe ack
      final MqttUnsubscribeAckMessage unsubAck =
          MqttUnsubscribeAckMessage().withMessageIdentifier(1);
      subs.confirmUnsubscribe(unsubAck);
      expect(
          subs.getSubscriptionsStatus(topic), SubscriptionStatus.doesNotExist);
      expect(cbCalled, isTrue);
    });
    test('Change notification', () {
      int recCount = 0;
      const String topic = 'testtopic';
      StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> st;
      // The subscription receive callback
      void subRec(List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[0].topic, topic);
        print('Change notification:: topic is $topic');
        expect(c[0].payload, const TypeMatcher<MqttPublishMessage>());
        final MqttPublishMessage recMess = c[0].payload;
        if (recCount == 0) {
          expect(recMess.variableHeader.messageIdentifier, 1);
          final String pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          expect(pt, 'dead');
          print('Change notification:: payload is $pt');
          expect(recMess.header.qos, MqttQos.atLeastOnce);
          recCount++;
        } else {
          expect(recMess.variableHeader.messageIdentifier, 2);
          final String pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          expect(pt, 'meat');
          print('Change notification:: payload is $pt');
          expect(recMess.header.qos, MqttQos.atMostOnce);
          //Stop listening
          st.cancel();
        }
      }

      // Wrap the callback
      final dynamic t1 = expectAsync1(subRec, count: 2);
      testCHS.sentMessages.clear();
      final events.EventBus clientEventBus = events.EventBus();
      final PublishingManager pm = PublishingManager(testCHS, clientEventBus);
      const MqttQos qos = MqttQos.atLeastOnce;
      final SubscriptionsManager subs =
          SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      // Start listening
      st = subs.subscriptionNotifier.changes.listen(t1);
      // Publish messages on the topic
      final typed.Uint8Buffer buff = typed.Uint8Buffer(4);
      buff[0] = 'd'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'a'.codeUnitAt(0);
      buff[3] = 'd'.codeUnitAt(0);
      final MqttPublishMessage pubMess = MqttPublishMessage()
          .publishData(buff)
          .toTopic(topic)
          .withMessageIdentifier(1)
          .withQos(MqttQos.atLeastOnce);
      pm.handlePublish(pubMess);
      buff[0] = 'm'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'a'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final MqttPublishMessage pubMess1 = MqttPublishMessage()
          .publishData(buff)
          .toTopic(topic)
          .withMessageIdentifier(2)
          .withQos(MqttQos.atMostOnce);
      pm.handlePublish(pubMess1);
    });
  });
}
