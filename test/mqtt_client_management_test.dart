/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/02/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';

@TestOn('vm')

void main() {
  group('Topic filtering', () {
    final clientUpdates =
        StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast(
            sync: true);
    final payload = MqttMessage();
    test('Exact match', () {
      const topicToFilter = 'testtopic';
      var called = false;
      final message = MqttReceivedMessage<MqttMessage>(topicToFilter, payload);
      final filter = MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[0].topic, topicToFilter);
        called = true;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message]);
      expect(called, isTrue);
    });
    test('No match', () {
      const topicToFilter = 'testtopic';
      var called = false;
      final message = MqttReceivedMessage<MqttMessage>('NoMatch', payload);
      final filter = MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        called = true;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message]);
      expect(called, isFalse);
    });
    test('Wildcard - All match', () {
      const topicToFilter = 'testtopic/#';
      var called = 0;
      final message0 = MqttReceivedMessage<MqttMessage>('testtopic/0', payload);
      final message1 = MqttReceivedMessage<MqttMessage>('testtopic/1', payload);
      final filter = MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[called].topic, 'testtopic/$called');
        called++;
      });
      clientUpdates.add(<MqttReceivedMessage<MqttMessage>>[message0, message1]);
      expect(called, 1);
    });
    test('Wildcard - Some match', () {
      const topicToFilter = 'testtopic/#';
      var called = 0;
      final message0 = MqttReceivedMessage<MqttMessage>('testtopic/0', payload);
      final message1 = MqttReceivedMessage<MqttMessage>('testtopic/1', payload);
      final message2 =
          MqttReceivedMessage<MqttMessage>('testtopic1/1', payload);
      final filter = MqttClientTopicFilter(topicToFilter, clientUpdates.stream);
      filter.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        expect(c[called].topic, 'testtopic/$called');
        called++;
      });
      clientUpdates.add(
          <MqttReceivedMessage<MqttMessage>>[message0, message1, message2]);
      expect(called, 1);
    });
    test('Multiple filters - valid topics received', () {
      const topicNumberOfSystems1 = 'PLCs/1/numberOfSystems';
      const topicNumberOfSystems2 = 'PLCs/2/numberOfSystems';
      const topicSystemStructure = 'PLCs/+/numberOfSystems';
      var called = 0;
      payload.header = MqttHeader();
      payload.header.qos = MqttQos.atLeastOnce;
      payload.header.retain = true;

      final message0 =
          MqttReceivedMessage<MqttMessage>(topicNumberOfSystems1, payload);

      final message1 =
          MqttReceivedMessage<MqttMessage>(topicNumberOfSystems2, payload);

      final topicFilterSystemStructure =
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
      const topicNumberOfSystems = 'PLCs/numberOfSystems';
      const topicSystemStructure = 'PLCs/+/systemStructure';
      var called1 = 0;
      var called2 = 0;
      payload.header = MqttHeader();
      payload.header.qos = MqttQos.atLeastOnce;
      payload.header.retain = true;

      final message0 =
          MqttReceivedMessage<MqttMessage>(topicNumberOfSystems, payload);

      final topicFilterSystemStructure =
          MqttClientTopicFilter(topicSystemStructure, clientUpdates.stream);

      final topicFilterNumberOfSystems =
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
