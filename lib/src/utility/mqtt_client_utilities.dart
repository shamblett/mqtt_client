/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 28/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// General library wide utilties
class MqttUtilities {
  /// Sleep function that allows asynchronous activity to continue.
  /// Time units are seconds
  static Future asyncSleep(int seconds) {
    return Future.delayed(Duration(seconds: seconds));
  }

  /// Sleep function that block asynchronous activity.
  /// Time units are seconds
  static void syncSleep(int seconds) {
    sleep(Duration(seconds: seconds));
  }
}
