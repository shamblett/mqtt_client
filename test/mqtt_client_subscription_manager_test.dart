/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_test_connection_handler.dart';

@TestOn('vm')

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {}

class MockCON extends Mock implements MqttServerNormalConnection {}

void main() {
  group('Manager', () {
    test('Invalid topic returns null subscription', () {
      var cbCalled = false;
      void subCallback(String topic) {
        expect(topic, 'house#');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'house#';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onSubscribeFail = subCallback;
      final ret = subs.registerSubscription(topic, qos);
      expect(ret, isNull);
      expect(cbCalled, isTrue);
    });
    test('Subscription request creates pending subscription', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
    });
    test('Acknowledged subscription request creates active subscription', () {
      var cbCalled = false;
      void subCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onSubscribed = subCallback;
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      expect(cbCalled, isTrue);
    });
    test(
        'Acknowledged subscription request for no pending subscription is ignored',
        () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce);
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isFalse);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
    });
    test(
        'Acknowledged but failed subscription request removed pending subscription',
        () {
      var cbCalled = false;
      void subFailCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onSubscribeFail = subFailCallback;
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.failure);
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isFalse);
      expect(subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.doesNotExist);
      expect(cbCalled, isTrue);
    });
    test(
        'Acknowledged but no Qos grants in payload removes pending subscription',
        () {
      var cbCalled = false;
      void subFailCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onSubscribeFail = subFailCallback;
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage().withMessageIdentifier(1);
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isFalse);
      expect(subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.doesNotExist);
      expect(cbCalled, isTrue);
    });
    test('Re subscribe', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      // Confirm the subscription
      var subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      var ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      testCHS.sentMessages.clear();
      // Resubscribe
      subs.resubscribe();
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce);
      ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
    });
    test('Get subscription with valid topic returns subscription', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      expect(subs.subscriptions[topic], const TypeMatcher<Subscription>());
    });
    test('Get subscription with invalid topic returns null', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      expect(subs.subscriptions['abc_badTopic'], isNull);
    });
    test('Get subscription for pending subscription returns null', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      expect(subs.subscriptions[topic], isNull);
    });
    test('Unsubscribe with ack', () {
      var cbCalled = false;
      void unsubCallback(String? topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      subs.onUnsubscribed = unsubCallback;
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      expect(subs.subscriptions[topic], isNull);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      // Unsubscribe
      subs.unsubscribe(topic);
      expect(
          testCHS.sentMessages[1], const TypeMatcher<MqttUnsubscribeMessage>());
      final MqttUnsubscribeMessage unSub = testCHS.sentMessages[1] as MqttUnsubscribeMessage;
      expect(unSub.variableHeader!.messageIdentifier, 2);
      expect(unSub.payload.subscriptions.length, 1);
      expect(unSub.payload.subscriptions[0], topic);
      expect(subs.pendingUnsubscriptions.length, 1);
      expect(subs.pendingUnsubscriptions[2], topic);
      // Unsubscribe ack
      final unsubAck = MqttUnsubscribeAckMessage().withMessageIdentifier(2);
      subs.confirmUnsubscribe(unsubAck);
      expect(subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.doesNotExist);
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalled, isTrue);
    });
    test('Change notification', () {
      var recCount = 0;
      const topic = 'testtopic';
      late StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>?> st;
      // The subscription receive callback
      void subRec(List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[0].topic, topic);
        print('Change notification:: topic is $topic');
        expect(c[0].payload, const TypeMatcher<MqttPublishMessage>());
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        if (recCount == 0) {
          expect(recMess.variableHeader!.messageIdentifier, 1);
          final pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
          expect(pt, 'dead');
          print('Change notification:: payload is $pt');
          expect(recMess.header!.qos, MqttQos.atLeastOnce);
          recCount++;
        } else {
          expect(recMess.variableHeader!.messageIdentifier, 2);
          final pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
          expect(pt, 'meat');
          print('Change notification:: payload is $pt');
          expect(recMess.header!.qos, MqttQos.atMostOnce);
          //Stop listening
          st.cancel();
        }
      }

      // Wrap the callback
      final dynamic t1 = expectAsync1(subRec, count: 2);
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      // Start listening
      st = subs.subscriptionNotifier.changes.listen(t1);
      // Publish messages on the topic
      final buff = typed.Uint8Buffer(4);
      buff[0] = 'd'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'a'.codeUnitAt(0);
      buff[3] = 'd'.codeUnitAt(0);
      final pubMess = MqttPublishMessage()
          .publishData(buff)
          .toTopic(topic)
          .withMessageIdentifier(1)
          .withQos(MqttQos.atLeastOnce);
      pm.handlePublish(pubMess);
      buff[0] = 'm'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'a'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final pubMess1 = MqttPublishMessage()
          .publishData(buff)
          .toTopic(topic)
          .withMessageIdentifier(2)
          .withQos(MqttQos.atMostOnce);
      pm.handlePublish(pubMess1);
    });
  });
}
