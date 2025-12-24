import 'package:event_bus/event_bus.dart';
import 'package:mqtt_client/mqtt_client.dart';

extension EventBusExtension on EventBus? {
  void safeFire(dynamic event) {
    if (this == null || this!.streamController.isClosed) {
      MqttLogger.log(
        'Event not fired, event bus closed',
      );
      return;
    }
    this!.fire(event);
  }
}
