/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 28/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

/// Library wide logging class
class MqttLogger {
  /// Log or not
  static bool loggingOn = false;

  /// Unique per client identifier
  static int clientId = 0;

  /// Test output
  static String testOutput = '';

  /// Log publish message payload data
  static bool logPayloads = true;

  static bool _testMode = false;

  /// Test mode
  static bool get testMode => _testMode;

  static set testMode(bool state) {
    _testMode = state;
    testOutput = '';
  }

  /// Log method
  /// If the optimise parameter is supplied it must have a toString method,
  /// this allows large objects such as lots of payload data not to be
  /// converted into a string in the message parameter if logging is not enabled.
  static void log(String message, [dynamic optimise = false]) {
    if (loggingOn) {
      final now = DateTime.now();
      var output = '';
      output = optimise is bool
          ? '${clientId.toString()}-$now -- $message'
          : '${clientId.toString()}-$now -- $message$optimise';
      if (testMode) {
        testOutput = output;
      } else {
        print(output);
      }
    }
  }
}
