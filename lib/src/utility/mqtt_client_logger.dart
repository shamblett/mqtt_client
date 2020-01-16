/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 28/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Library wide logging class
class MqttLogger {
  /// Log or not
  static bool loggingOn = false;

  /// Log method
  static void log(String message) {
    if (loggingOn) {
      final now = DateTime.now();
      // ignore: avoid_print
      print('$now -- $message');
    }
  }
}
