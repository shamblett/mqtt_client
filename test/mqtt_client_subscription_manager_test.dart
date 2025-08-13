/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:io';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_test_connection_handler.dart';

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {}

class MockCON extends Mock implements MqttServerNormalConnection {}

void main() {
  List<RawSocketOption> socketOptions = <RawSocketOption>[];
  group('Batch Subscription', () {
    test('Construction and equality', () {
      final sub = BatchSubscription('mytopic', MqttQos.exactlyOnce);
      expect(sub.topic, 'mytopic');
      expect(sub.qos, MqttQos.exactlyOnce);
      final sub1 = BatchSubscription('mytopic', MqttQos.exactlyOnce);
      expect(sub, sub1);
    });
  });
  group('Subscription', () {
    test('Construction', () {
      final sub = Subscription();
      expect(sub.messageIdentifier, isNull);
      expect(sub.topic.rawTopic, 'rawtopic');
      expect(sub.subscriptions.isEmpty, isTrue);
      expect(sub.totalBatchSubscriptions, 0);
      expect(sub.totalSucceededSubscriptions, 0);
      expect(sub.totalFailedSubscriptions, 0);
      expect(sub.batch, isFalse);
    });
    test('Subscription single', () {
      final sub = Subscription();
      sub.messageIdentifier = 1;
      sub.qos = MqttQos.exactlyOnce;
      sub.topic = SubscriptionTopic('rawtopic');
      expect(sub.messageIdentifier, 1);
      expect(sub.topic.rawTopic, 'rawtopic');
      expect(sub.qos, MqttQos.exactlyOnce);
      expect(sub.subscriptions.isEmpty, isTrue);
      expect(sub.totalBatchSubscriptions, 0);
      expect(sub.totalSucceededSubscriptions, 0);
      expect(sub.totalFailedSubscriptions, 0);
      expect(sub.batch, isFalse);
    });
    test('Equality', () {
      final sub1 = Subscription();
      sub1.messageIdentifier = 1;
      sub1.qos = MqttQos.exactlyOnce;
      sub1.topic = SubscriptionTopic('mytopic1');
      final sub2 = Subscription();
      sub2.messageIdentifier = 1;
      sub2.qos = MqttQos.exactlyOnce;
      sub2.topic = SubscriptionTopic('mytopic1');
      expect(sub1, sub2);
    });
    test('Equality fail', () {
      final sub1 = Subscription();
      sub1.messageIdentifier = 1;
      sub1.qos = MqttQos.exactlyOnce;
      sub1.topic = SubscriptionTopic('mytopic1');
      final sub2 = Subscription();
      sub2.messageIdentifier = 2;
      sub2.qos = MqttQos.exactlyOnce;
      sub2.topic = SubscriptionTopic('mytopic1');
      expect(sub1 == sub2, isFalse);
    });
    test('Equality fail batch', () {
      final sub1 = Subscription();
      sub1.messageIdentifier = 1;
      sub1.qos = MqttQos.exactlyOnce;
      sub1.topic = SubscriptionTopic('mytopic1');
      final sub2 = Subscription();
      sub2.messageIdentifier = 1;
      sub2.batch = true;
      sub2.qos = MqttQos.exactlyOnce;
      sub2.topic = SubscriptionTopic('mytopic1');
      expect(sub1 == sub2, isFalse);
    });
    test('Subscription batch', () {
      final sub = Subscription();
      sub.messageIdentifier = 1;
      sub.qos = MqttQos.exactlyOnce;
      sub.topic = SubscriptionTopic('rawtopic');
      sub.batch = true;
      final sub1 = BatchSubscription('mytopic1', MqttQos.exactlyOnce);
      final sub2 = BatchSubscription('mytopic2', MqttQos.atMostOnce);
      final sub3 = BatchSubscription('mytopic3', MqttQos.atLeastOnce);
      sub.subscriptions.addAll([sub1, sub2, sub3]);
      expect(sub.messageIdentifier, 1);
      expect(sub.topic.rawTopic, 'mytopic1');
      expect(sub.qos, MqttQos.exactlyOnce);
      expect(sub.subscriptions.isEmpty, isFalse);
      expect(sub.totalBatchSubscriptions, 3);
      expect(sub.totalSucceededSubscriptions, 3);
      expect(sub.totalFailedSubscriptions, 0);
      expect(sub.batch, isTrue);
      expect(sub.allTopics, ['mytopic1', 'mytopic2', 'mytopic3']);
    });
    test('Subscription batch update QoS', () {
      final sub = Subscription();
      sub.messageIdentifier = 1;
      sub.topic = SubscriptionTopic('rawtopic');
      sub.batch = true;
      final sub1 = BatchSubscription('mytopic1', MqttQos.exactlyOnce);
      final sub2 = BatchSubscription('mytopic2', MqttQos.atMostOnce);
      final sub3 = BatchSubscription('mytopic3', MqttQos.atLeastOnce);
      sub.subscriptions.addAll([sub1, sub2, sub3]);
      expect(sub.messageIdentifier, 1);
      expect(sub.topic.rawTopic, 'mytopic1');
      final qosList = <MqttQos>[
        MqttQos.atLeastOnce,
        MqttQos.exactlyOnce,
        MqttQos.failure,
      ];
      final res = sub.updateBatchQos(qosList);
      expect(res, isTrue);
      expect(sub.qos, MqttQos.atLeastOnce);
      expect(sub.subscriptions.isEmpty, isFalse);
      expect(sub.totalBatchSubscriptions, 3);
      expect(sub.totalSucceededSubscriptions, 2);
      expect(sub.totalFailedSubscriptions, 1);
      expect(sub.subscriptions[1].qos, MqttQos.exactlyOnce);
      expect(sub.subscriptions[2].qos, MqttQos.failure);
      expect(sub.batch, isTrue);
    });
    test('Subscription Batch update QoS unequal lengths', () {
      final sub = Subscription();
      sub.messageIdentifier = 1;
      sub.qos = MqttQos.exactlyOnce;
      sub.topic = SubscriptionTopic('rawtopic');
      sub.batch = true;
      final sub1 = BatchSubscription('mytopic1', MqttQos.exactlyOnce);
      final sub2 = BatchSubscription('mytopic2', MqttQos.atMostOnce);
      final sub3 = BatchSubscription('mytopic3', MqttQos.atLeastOnce);
      sub.subscriptions.addAll([sub1, sub2, sub3]);
      expect(sub.messageIdentifier, 1);
      expect(sub.topic.rawTopic, 'mytopic1');
      final qosList = <MqttQos>[MqttQos.atLeastOnce, MqttQos.exactlyOnce];
      final res = sub.updateBatchQos(qosList);
      expect(res, isFalse);
      expect(sub.qos, MqttQos.exactlyOnce);
      expect(sub.subscriptions.isEmpty, isFalse);
      expect(sub.totalBatchSubscriptions, 3);
      expect(sub.totalSucceededSubscriptions, 3);
      expect(sub.totalFailedSubscriptions, 0);
      expect(sub.batch, isTrue);
    });
  });
  group('Manager', () {
    test('Invalid topic returns null subscription single', () {
      var cbCalled = false;
      void subCallback(String topic) {
        expect(topic, 'house#');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
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
    test('Invalid topic returns null subscription batch', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'house#';
      const qos = MqttQos.atLeastOnce;
      final batchSubscription = BatchSubscription(topic, qos);
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      final ret = subs.registerBatchSubscription([batchSubscription]);
      expect(ret, isNull);
    });
    test('Subscription request creates pending subscription single', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
    });
    test('Subscription request creates pending subscription batch', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final subscriptions = <BatchSubscription>[
        BatchSubscription('topic1', MqttQos.atLeastOnce),
        BatchSubscription('topic2', MqttQos.atMostOnce),
        BatchSubscription('topic3', MqttQos.exactlyOnce),
      ];
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      final subRet = subs.registerBatchSubscription(subscriptions);
      expect(subRet, isNotNull);
      expect(subRet?.batch, isTrue);
      expect(subRet?.qos, MqttQos.atLeastOnce);
      expect(subRet?.topic.rawTopic, 'topic1');
      expect(subRet?.totalBatchSubscriptions, 3);
      expect(subRet?.failedSubscriptions.length, 0);
      expect(subRet?.succeededSubscriptions.length, 3);
      expect(
        subRet?.subscriptions.first ==
            BatchSubscription('topic1', MqttQos.atLeastOnce),
        isTrue,
      );
      expect(
        subRet?.subscriptions[1] ==
            BatchSubscription('topic2', MqttQos.atMostOnce),
        isTrue,
      );
      expect(
        subRet?.subscriptions.last ==
            BatchSubscription('topic3', MqttQos.exactlyOnce),
        isTrue,
      );
      expect(
        subs.getSubscriptionsStatusBySubscription(subRet!),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey('topic1'), isTrue);
      expect(msg.payload.subscriptions['topic1'], MqttQos.atLeastOnce);
      expect(msg.payload.subscriptions.containsKey('topic2'), isTrue);
      expect(msg.payload.subscriptions['topic2'], MqttQos.atMostOnce);
      expect(msg.payload.subscriptions.containsKey('topic3'), isTrue);
      expect(msg.payload.subscriptions['topic3'], MqttQos.exactlyOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
    });
    test(
      'Acknowledged subscription request creates active subscription batch',
      () {
        var cbCalled = false;
        void subCallback(String topic) {
          expect(topic, 'topic1');
          cbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.onSubscribed = subCallback;
        final subscriptions = <BatchSubscription>[
          BatchSubscription('topic1', MqttQos.atLeastOnce),
          BatchSubscription('topic2', MqttQos.atMostOnce),
          BatchSubscription('topic3', MqttQos.exactlyOnce),
        ];
        final subRet = subs.registerBatchSubscription(subscriptions);
        expect(
          subs.getSubscriptionsStatusBySubscription(subRet!),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
        expect(msg.payload.subscriptions.length, 3);
        expect(msg.payload.subscriptions['topic1'], MqttQos.atLeastOnce);
        expect(msg.payload.subscriptions['topic2'], MqttQos.atMostOnce);
        expect(msg.payload.subscriptions['topic3'], MqttQos.exactlyOnce);
        expect(msg.variableHeader!.messageIdentifier, 1);
        expect(msg.header!.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage()
            .withMessageIdentifier(1)
            .addQosGrant(MqttQos.atLeastOnce)
            .addQosGrant(MqttQos.atMostOnce)
            .addQosGrant(MqttQos.exactlyOnce);
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isTrue);
        expect(
          subs.getSubscriptionsStatusBySubscription(subRet),
          MqttSubscriptionStatus.active,
        );
        expect(subRet.batch, isTrue);
        expect(subRet.subscriptions.length, 3);
        expect(subRet.requestedSubscriptions.length, 3);
        expect(cbCalled, isTrue);
      },
    );
    test(
      'Acknowledged subscription request creates active subscription single',
      () {
        var cbCalled = false;
        void subCallback(String topic) {
          expect(topic, 'testtopic');
          cbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.onSubscribed = subCallback;
        subs.registerSubscription(topic, qos);
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.active,
        );
        expect(cbCalled, isTrue);
      },
    );
    test(
      'Acknowledged subscription request for no pending subscription is ignored',
      () {
        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.registerSubscription(topic, qos);
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.pending,
        );
      },
    );
    test(
      'Acknowledged but failed subscription request removed pending subscription single',
      () {
        var cbCalled = false;
        void subFailCallback(String topic) {
          expect(topic, 'testtopic');
          cbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.onSubscribeFail = subFailCallback;
        subs.registerSubscription(topic, qos);
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.doesNotExist,
        );
        expect(cbCalled, isTrue);
      },
    );
    test(
      'Acknowledged but failed subscription request removed pending subscription batch',
      () {
        var cbCalled = false;
        void subFailCallback(String topic) {
          expect(topic, 'topic1');
          cbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.onSubscribeFail = subFailCallback;
        final subscriptions = <BatchSubscription>[
          BatchSubscription('topic1', MqttQos.atLeastOnce),
          BatchSubscription('topic2', MqttQos.atMostOnce),
          BatchSubscription('topic3', MqttQos.exactlyOnce),
        ];
        final subRet = subs.registerBatchSubscription(subscriptions);
        expect(
          subs.getSubscriptionsStatusBySubscription(subRet!),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
        expect(msg.payload.subscriptions['topic1'], MqttQos.atLeastOnce);
        expect(msg.payload.subscriptions['topic2'], MqttQos.atMostOnce);
        expect(msg.payload.subscriptions['topic3'], MqttQos.exactlyOnce);
        expect(msg.variableHeader!.messageIdentifier, 1);
        expect(msg.header!.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage()
            .withMessageIdentifier(1)
            .addQosGrant(MqttQos.failure)
            .addQosGrant(MqttQos.failure)
            .addQosGrant(MqttQos.failure);
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isFalse);
        expect(
          subs.getSubscriptionsStatusBySubscription(subRet),
          MqttSubscriptionStatus.doesNotExist,
        );
        expect(cbCalled, isTrue);
      },
    );
    test(
      'Acknowledged but no Qos grants in payload removes pending subscription single',
      () {
        var cbCalled = false;
        void subFailCallback(String topic) {
          expect(topic, 'testtopic');
          cbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.onSubscribeFail = subFailCallback;
        subs.registerSubscription(topic, qos);
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
        expect(msg.payload.subscriptions.containsKey(topic), isTrue);
        expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
        expect(msg.variableHeader!.messageIdentifier, 1);
        expect(msg.header!.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage().withMessageIdentifier(1);
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isFalse);
        expect(
          subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.doesNotExist,
        );
        expect(cbCalled, isTrue);
      },
    );
    test(
      'Acknowledged but no Qos grants in payload removes pending subscription batch',
      () {
        var cbCalled = false;
        void subFailCallback(String topic) {
          expect(topic, 'topic1');
          cbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final testCHS = TestConnectionHandlerSend(
          clientEventBus,
          socketOptions: socketOptions,
        );
        final pm = PublishingManager(testCHS, clientEventBus);
        pm.messageIdentifierDispenser.reset();
        final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
        subs.onSubscribeFail = subFailCallback;
        final subscriptions = <BatchSubscription>[
          BatchSubscription('topic1', MqttQos.atLeastOnce),
          BatchSubscription('topic2', MqttQos.atMostOnce),
          BatchSubscription('topic3', MqttQos.exactlyOnce),
        ];
        final subRet = subs.registerBatchSubscription(subscriptions);
        expect(
          subs.getSubscriptionsStatusBySubscription(subRet!),
          MqttSubscriptionStatus.pending,
        );
        expect(
          testCHS.sentMessages[0],
          const TypeMatcher<MqttSubscribeMessage>(),
        );
        final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
        expect(msg.variableHeader!.messageIdentifier, 1);
        expect(msg.header!.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage().withMessageIdentifier(1);
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isFalse);
        expect(
          subs.getSubscriptionsStatusBySubscription(subRet),
          MqttSubscriptionStatus.doesNotExist,
        );
        expect(cbCalled, isTrue);
      },
    );
    test('Re subscribe single', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
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
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
    test('Re subscribe batch', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      final subscriptions = <BatchSubscription>[
        BatchSubscription('topic1', MqttQos.atLeastOnce),
        BatchSubscription('topic2', MqttQos.atMostOnce),
        BatchSubscription('topic3', MqttQos.exactlyOnce),
      ];
      final subRet = subs.registerBatchSubscription(subscriptions);
      expect(
        subs.getSubscriptionsStatusBySubscription(subRet!),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      // Confirm the subscription
      var subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce)
          .addQosGrant(MqttQos.atMostOnce)
          .addQosGrant(MqttQos.exactlyOnce);
      var ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(
        subs.getSubscriptionsStatusBySubscription(subRet),
        MqttSubscriptionStatus.active,
      );
      testCHS.sentMessages.clear();
      // Resubscribe
      subs.resubscribe();
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      expect(subs.subscriptions.isEmpty, isTrue);
      expect(subs.pendingSubscriptions.length, 1);
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.variableHeader?.messageIdentifier, 2);
      expect(msg.payload.subscriptions['topic1'], MqttQos.atLeastOnce);
      expect(msg.payload.subscriptions['topic2'], MqttQos.atMostOnce);
      expect(msg.payload.subscriptions['topic3'], MqttQos.exactlyOnce);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce)
          .addQosGrant(MqttQos.atMostOnce)
          .addQosGrant(MqttQos.exactlyOnce);
      ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(
        subs.getSubscriptionsStatus('topic1'),
        MqttSubscriptionStatus.active,
      );
    });
    test('Get subscription with valid topic returns subscription', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
    });
    test('Get subscription with invalid topic returns null', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
    });
    test('Get subscription for pending subscription', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.containsKey(topic), isTrue);
      expect(msg.payload.subscriptions[topic], MqttQos.atLeastOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
    });
    test('Unsubscribe no expect acknowledge single', () {
      var cbCalled = false;
      void unsubCallback(String? topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      subs.onUnsubscribed = unsubCallback;
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
      // Unsubscribe
      subs.unsubscribe(topic);
      expect(
        testCHS.sentMessages[1],
        const TypeMatcher<MqttUnsubscribeMessage>(),
      );
      final unSub = testCHS.sentMessages[1] as MqttUnsubscribeMessage;
      expect(unSub.variableHeader!.messageIdentifier, 2);
      expect(unSub.payload.subscriptions.length, 1);
      expect(unSub.payload.subscriptions[0], topic);
      expect(unSub.header!.qos, MqttQos.atMostOnce);
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalled, isTrue);
    });
    test('Unsubscribe no expect acknowledge batch', () {
      var cbCalled = false;
      void unsubCallback(String? topic) {
        expect(topic, 'topic1');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final subscriptions = <BatchSubscription>[
        BatchSubscription('topic1', MqttQos.atLeastOnce),
        BatchSubscription('topic2', MqttQos.atMostOnce),
        BatchSubscription('topic3', MqttQos.exactlyOnce),
      ];
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      final retSub = subs.registerBatchSubscription(subscriptions);
      subs.onUnsubscribed = unsubCallback;
      expect(
        subs.getSubscriptionsStatusBySubscription(retSub!),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions['topic1'], MqttQos.atLeastOnce);
      expect(msg.payload.subscriptions['topic2'], MqttQos.atMostOnce);
      expect(msg.payload.subscriptions['topic3'], MqttQos.exactlyOnce);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce)
          .addQosGrant(MqttQos.atMostOnce)
          .addQosGrant(MqttQos.exactlyOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus('topic1'),
        MqttSubscriptionStatus.active,
      );
      // Unsubscribe
      subs.unsubscribe('topic1');
      expect(
        subs.getSubscriptionsStatus('topic1'),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(
        testCHS.sentMessages[1],
        const TypeMatcher<MqttUnsubscribeMessage>(),
      );
      final unSub = testCHS.sentMessages[1] as MqttUnsubscribeMessage;
      expect(unSub.variableHeader!.messageIdentifier, 2);
      expect(unSub.payload.subscriptions.length, 3);
      expect(unSub.payload.subscriptions[0], 'topic1');
      expect(unSub.payload.subscriptions[1], 'topic2');
      expect(unSub.payload.subscriptions[2], 'topic3');
      expect(unSub.header!.qos, MqttQos.atMostOnce);
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalled, isTrue);
    });
    test('Unsubscribe expect acknowledge single', () {
      var cbCalled = false;
      void unsubCallback(String? topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      subs.onUnsubscribed = unsubCallback;
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
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
      // Unsubscribe
      subs.unsubscribe(topic, expectAcknowledge: true);
      expect(
        testCHS.sentMessages[1],
        const TypeMatcher<MqttUnsubscribeMessage>(),
      );
      final unSub = testCHS.sentMessages[1] as MqttUnsubscribeMessage;
      expect(unSub.variableHeader!.messageIdentifier, 2);
      expect(unSub.payload.subscriptions.length, 1);
      expect(unSub.payload.subscriptions[0], topic);
      expect(unSub.header!.qos, MqttQos.atLeastOnce);
      expect(subs.pendingUnsubscriptions.length, 1);
      expect(subs.pendingUnsubscriptions.values.first.topic.rawTopic, topic);

      // Unsubscribe ack
      final unsubAck = MqttUnsubscribeAckMessage().withMessageIdentifier(2);
      subs.confirmUnsubscribe(unsubAck);
      expect(
        subs.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalled, isTrue);
    });
    test('Unsubscribe expect acknowledge multi with ack', () {
      var cbCalledCount = 0;
      void unsubCallback(String? topic) {
        cbCalledCount++;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic1 = 'testtopic1';
      const topic2 = 'testtopic2';
      const topic3 = 'testtopic3';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onUnsubscribed = unsubCallback;
      subs.registerSubscription(topic1, qos);
      subs.registerSubscription(topic2, qos);
      subs.registerSubscription(topic3, qos);
      expect(
        subs.getSubscriptionsStatus(topic1),
        MqttSubscriptionStatus.pending,
      );
      expect(
        subs.getSubscriptionsStatus(topic2),
        MqttSubscriptionStatus.pending,
      );
      expect(
        subs.getSubscriptionsStatus(topic3),
        MqttSubscriptionStatus.pending,
      );
      // Confirm
      var subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus(topic1),
        MqttSubscriptionStatus.active,
      );
      subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus(topic2),
        MqttSubscriptionStatus.active,
      );
      subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(3)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus(topic3),
        MqttSubscriptionStatus.active,
      );
      // Unsubscribe
      subs.unsubscribeMulti([
        MultiUnsubscription(topic1, qos),
        MultiUnsubscription(topic2, qos),
        MultiUnsubscription(topic3, qos),
      ], expectAcknowledge: true);
      expect(
        testCHS.sentMessages[3],
        const TypeMatcher<MqttUnsubscribeMessage>(),
      );

      // Unsubscribe ack
      final unsubAck = MqttUnsubscribeAckMessage().withMessageIdentifier(4);
      subs.confirmUnsubscribe(unsubAck);
      expect(
        subs.getSubscriptionsStatus(topic1),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(
        subs.getSubscriptionsStatus(topic2),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(
        subs.getSubscriptionsStatus(topic3),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalledCount, 3);
    });
    test('Unsubscribe expect acknowledge multi no ack', () {
      var cbCalledCount = 0;
      void unsubCallback(String? topic) {
        cbCalledCount++;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      const topic1 = 'testtopic1';
      const topic2 = 'testtopic2';
      const topic3 = 'testtopic3';
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onUnsubscribed = unsubCallback;
      subs.registerSubscription(topic1, qos);
      subs.registerSubscription(topic2, qos);
      subs.registerSubscription(topic3, qos);
      expect(
        subs.getSubscriptionsStatus(topic1),
        MqttSubscriptionStatus.pending,
      );
      expect(
        subs.getSubscriptionsStatus(topic2),
        MqttSubscriptionStatus.pending,
      );
      expect(
        subs.getSubscriptionsStatus(topic3),
        MqttSubscriptionStatus.pending,
      );
      // Confirm
      var subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus(topic1),
        MqttSubscriptionStatus.active,
      );
      subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus(topic2),
        MqttSubscriptionStatus.active,
      );
      subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(3)
          .addQosGrant(MqttQos.atLeastOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus(topic3),
        MqttSubscriptionStatus.active,
      );
      // Unsubscribe
      subs.unsubscribeMulti([
        MultiUnsubscription(topic1, qos),
        MultiUnsubscription(topic2, qos),
        MultiUnsubscription(topic3, qos),
      ]);
      expect(
        testCHS.sentMessages[3],
        const TypeMatcher<MqttUnsubscribeMessage>(),
      );
      expect(
        subs.getSubscriptionsStatus(topic1),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(
        subs.getSubscriptionsStatus(topic2),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(
        subs.getSubscriptionsStatus(topic3),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalledCount, 3);
    });
    test('Unsubscribe expect acknowledge batch', () {
      var cbCalled = false;
      void unsubCallback(String? topic) {
        expect(topic, 'topic1');
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final subscriptions = <BatchSubscription>[
        BatchSubscription('topic1', MqttQos.atLeastOnce),
        BatchSubscription('topic2', MqttQos.atMostOnce),
        BatchSubscription('topic3', MqttQos.exactlyOnce),
      ];
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.onUnsubscribed = unsubCallback;
      subs.registerBatchSubscription(subscriptions);
      expect(
        subs.getSubscriptionsStatus('topic1'),
        MqttSubscriptionStatus.pending,
      );
      expect(
        testCHS.sentMessages[0],
        const TypeMatcher<MqttSubscribeMessage>(),
      );
      final msg = testCHS.sentMessages[0] as MqttSubscribeMessage;
      expect(msg.payload.subscriptions.length, 3);
      expect(msg.variableHeader!.messageIdentifier, 1);
      expect(msg.header!.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage()
          .withMessageIdentifier(1)
          .addQosGrant(MqttQos.atLeastOnce)
          .addQosGrant(MqttQos.atMostOnce)
          .addQosGrant(MqttQos.exactlyOnce);
      subs.confirmSubscription(subAckMsg);
      expect(
        subs.getSubscriptionsStatus('topic1'),
        MqttSubscriptionStatus.active,
      );
      // Unsubscribe
      subs.unsubscribe('topic1', expectAcknowledge: true);
      expect(
        testCHS.sentMessages[1],
        const TypeMatcher<MqttUnsubscribeMessage>(),
      );
      final unSub = testCHS.sentMessages[1] as MqttUnsubscribeMessage;
      expect(unSub.variableHeader!.messageIdentifier, 2);
      expect(unSub.payload.subscriptions.length, 3);
      expect(unSub.header!.qos, MqttQos.atLeastOnce);
      expect(subs.pendingUnsubscriptions.values.first.topic.rawTopic, 'topic1');

      // Unsubscribe ack
      final unsubAck = MqttUnsubscribeAckMessage().withMessageIdentifier(2);
      subs.confirmUnsubscribe(unsubAck);
      expect(
        subs.getSubscriptionsStatus('topic1'),
        MqttSubscriptionStatus.doesNotExist,
      );
      expect(subs.pendingUnsubscriptions.length, 0);
      expect(cbCalled, isTrue);
    });
    test('Change notification', () {
      var recCount = 0;
      const topic = 'testtopic';
      late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> st;
      // The subscription receive callback
      void subRec(List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[0].topic, topic);
        print('Change notification:: topic is $topic');
        expect(c[0].payload, const TypeMatcher<MqttPublishMessage>());
        final recMess = c[0].payload as MqttPublishMessage;
        if (recCount == 0) {
          expect(recMess.variableHeader!.messageIdentifier, 1);
          final pt = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );
          expect(pt, 'dead');
          print('Change notification:: payload is $pt');
          expect(recMess.header!.qos, MqttQos.atLeastOnce);
          recCount++;
        } else {
          expect(recMess.variableHeader!.messageIdentifier, 2);
          final pt = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );
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
      final testCHS = TestConnectionHandlerSend(
        clientEventBus,
        socketOptions: socketOptions,
      );
      final pm = PublishingManager(testCHS, clientEventBus);
      const qos = MqttQos.atLeastOnce;
      final subs = SubscriptionsManager(testCHS, pm, clientEventBus);
      subs.registerSubscription(topic, qos);
      // Start listening
      st = subs.subscriptionNotifier.listen(t1);
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
