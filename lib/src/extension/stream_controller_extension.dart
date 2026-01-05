import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';

extension StreamControllerExtension on StreamController? {
  void safeAdd(dynamic event) {
    if (this == null || this!.isClosed) {
      MqttLogger.log('Event not added, stream controller is closed');
      return;
    }
    this!.add(event);
  }
}
