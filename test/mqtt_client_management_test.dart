/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/02/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';

void main() {
  group('Topic filtering', () {
    final StreamController<List<MqttReceivedMessage<MqttMessage>>>
        clientUpdates =
        StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast(
            sync: true);
    final MqttMessage payload = MqttMessage();
    test('Exact match', () {
      const String topicToFilter = 'testtopic';
      bool called = false;
      final MqttReceivedMessage<MqttMessage> message =
          MqttReceivedMessage<MqttMessage>(topicToFilter, payload);
      final MqttClientTopicFilter filter =
          MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[0].topic, topicToFilter);
        called = true;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message]);
      expect(called, isTrue);
    });
    test('No match', () {
      const String topicToFilter = 'testtopic';
      bool called = false;
      final MqttReceivedMessage<MqttMessage> message =
          MqttReceivedMessage<MqttMessage>('NoMatch', payload);
      final MqttClientTopicFilter filter =
          MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        called = true;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message]);
      expect(called, isFalse);
    });
    test('Wildcard - All match', () {
      const String topicToFilter = 'testtopic/#';
      int called = 0;
      final MqttReceivedMessage<MqttMessage> message0 =
          MqttReceivedMessage<MqttMessage>('testtopic/0', payload);
      final MqttReceivedMessage<MqttMessage> message1 =
          MqttReceivedMessage<MqttMessage>('testtopic/1', payload);
      final MqttClientTopicFilter filter =
          MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[called].topic, 'testtopic/$called');
        called++;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message0, message1]);
      expect(called, 1);
    });
    test('Wildcard - Some match', () {
      const String topicToFilter = 'testtopic/#';
      int called = 0;
      final MqttReceivedMessage<MqttMessage> message0 =
          MqttReceivedMessage<MqttMessage>('testtopic/0', payload);
      final MqttReceivedMessage<MqttMessage> message1 =
          MqttReceivedMessage<MqttMessage>('testtopic/1', payload);
      final MqttReceivedMessage<MqttMessage> message2 =
          MqttReceivedMessage<MqttMessage>('testtopic1/1', payload);
      final MqttClientTopicFilter filter =
          MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[called].topic, 'testtopic/$called');
        called++;
      });
      clientUpdates.add(
          <MqttReceivedMessage<MqttMessage>>[message0, message1, message2]);
      expect(called, 1);
    });
    test('Multiple filters - valid topics received', () {
      const String topicNumberOfSystems1 = 'PLCs/1/numberOfSystems';
      const String topicNumberOfSystems2 = 'PLCs/2/numberOfSystems';
      const String topicSystemStructure = 'PLCs/+/numberOfSystems';
      int called = 0;
      payload.header = MqttHeader();
      payload.header.qos = MqttQos.atLeastOnce;
      payload.header.retain = true;

      final MqttReceivedMessage<MqttMessage> message0 =
          MqttReceivedMessage<MqttMessage>(topicNumberOfSystems1, payload);

      final MqttReceivedMessage<MqttMessage> message1 =
          MqttReceivedMessage<MqttMessage>(topicNumberOfSystems2, payload);

      final MqttClientTopicFilter topicFilterSystemStructure =
          MqttClientTopicFilter(topicSystemStructure, clientUpdates.stream);
      topicFilterSystemStructure.updates
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[0].topic, 'PLCs/1/numberOfSystems');
        expect(c[1].topic, 'PLCs/2/numberOfSystems');
        called++;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message0, message1]);
      expect(called, 1);
    });
    test('Multiple filters - invalid topic received', () {
      const String topicNumberOfSystems = 'PLCs/numberOfSystems';
      const String topicSystemStructure = 'PLCs/+/systemStructure';
      int called1 = 0;
      int called2 = 0;
      payload.header = MqttHeader();
      payload.header.qos = MqttQos.atLeastOnce;
      payload.header.retain = true;

      final MqttReceivedMessage<MqttMessage> message0 =
          MqttReceivedMessage<MqttMessage>(topicNumberOfSystems, payload);

      final MqttClientTopicFilter topicFilterSystemStructure =
          MqttClientTopicFilter(topicSystemStructure, clientUpdates.stream);

      final MqttClientTopicFilter topicFilterNumberOfSystems =
          MqttClientTopicFilter(topicNumberOfSystems, clientUpdates.stream);
      topicFilterNumberOfSystems.updates
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[called1].topic, 'PLCs/numberOfSystems');
        called1++;
      });
      topicFilterSystemStructure.updates
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[called2].topic, 'PLCs/+/systemStructure');
        called2++;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message0]);
      expect(called1, 1);
      expect(called2, 0);
    });
  });
}
