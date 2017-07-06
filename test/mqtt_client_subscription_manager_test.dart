/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'mqtt_client_test_connection_handler.dart';
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
  });
}
