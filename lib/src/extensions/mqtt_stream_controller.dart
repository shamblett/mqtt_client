/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 07/01/2026
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

///
/// StramController extension that provides a guarded add method.
///
extension type MqttStreamController<T>._(StreamController controller) {
  MqttStreamController.fromStreamController(this.controller);
  void add(dynamic event) {
    if (controller.isClosed) {
      MqttLogger.log('Guarded add - stream is closed - event not added');
      return;
    }
    if (!controller.hasListener) {
      MqttLogger.log('Guarded add - stream has no listeners - adding anyway');
    }
    controller.add(event);
  }

  Future close() => controller.close();

  Stream<T> get stream => controller.stream as Stream<T>;

  bool get hasListener => controller.hasListener;
}
