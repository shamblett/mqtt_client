/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 07/01/2026
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

///
/// Event bus extension that provides a guarded fire method.
///
extension type MqttEventBus._(events.EventBus eventbus) {
  MqttEventBus.fromEventBus(this.eventbus);

  void destroy() => eventbus.destroy();

  Stream<T> on<T>() => eventbus.on<T>();

  void fire(dynamic event) {
    if (!eventbus.streamController.isClosed) {
      eventbus.fire(event);
    } else {
      MqttLogger.log('Guarded fire - event bus is closed - event not fired');
    }
  }
}
