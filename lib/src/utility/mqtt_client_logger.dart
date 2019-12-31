/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 28/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// ignore_for_file: cascade_invocations
// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_classes_with_only_static_members

/// Library wide logging class
class MqttLogger {
  /// Log or not
  static bool loggingOn = false;

  /// Log method
  static void log(String message) {
    if (loggingOn) {
      final DateTime now = DateTime.now();
      // ignore: avoid_print
      print('$now -- $message');
    }
  }
}
