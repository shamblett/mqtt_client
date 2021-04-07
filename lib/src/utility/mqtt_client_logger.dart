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

  /// Unique per client identifier
  static int clientId = 0;

  /// Test output
  static String testOutput = '';

  /// Test mode
  static bool testMode = false;

  /// Log method
  /// If the optimise parameter is supplied it must have a toString method,
  /// this allows large objects such as lots of payload data not to be
  /// converted into a string in the message parameter if logging is not enabled.
  static void log(String message, [dynamic optimise = false]) {
    if (loggingOn) {
      final now = DateTime.now();
      var output = '';
      if (optimise is bool) {
        output = '${clientId.toString()}-$now -- $message';
        print(output);
      } else {
        output = '${clientId.toString()}-$now -- $message$optimise';
        print(output);
      }
      if (testMode) {
        testOutput = output;
      }
    }
  }
}
