/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 07/01/2026
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

extension type MqttStreamController<T>._(StreamController controller) {
  MqttStreamController.fromStreamController(this.controller);
  void add(dynamic event) {
    if (this == null || controller.isClosed) {
      return;
    }
    controller.add(event);
  }

  Stream<T> get stream => controller.stream as Stream<T>;
}
