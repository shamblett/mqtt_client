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

/// General library wide utilties
class MqttUtilities {
  /// Sleep function that allows asynchronous activity to continue.
  /// Time units are seconds
  static Future<void> asyncSleep(int seconds) =>
      Future<void>.delayed(Duration(seconds: seconds));

  /// Sleep function that block asynchronous activity.
  /// Time units are seconds
  static void syncSleep(int seconds) {
    sleep(Duration(seconds: seconds));
  }

  /// Qos conversion, always use this to get a Qos
  /// enumeration from a value
  static MqttQos getQosLevel(int value) {
    switch (value) {
      case 0:
        return MqttQos.atMostOnce;
      case 1:
        return MqttQos.atLeastOnce;
      case 2:
        return MqttQos.exactlyOnce;
      case 0x80:
        return MqttQos.failure;
      default:
        return MqttQos.reserved1;
    }
  }
}

/// Cancellable asynchronous sleep support class
class MqttCancellableAsyncSleep {
  /// Timeout value in milliseconds
  MqttCancellableAsyncSleep(this._timeout);

  /// Millisecond timeout
  final int _timeout;

  /// Timeout
  int get timeout => _timeout;

  /// The completer
  final Completer<void> _completer = Completer<void>();

  /// The timer
  Timer _timer;

  /// Timer running flag
  bool _running = false;

  /// Running
  bool get isRunning => _running;

  /// Start the timer
  Future<void> sleep() {
    if (!_running) {
      _timer = Timer(Duration(milliseconds: _timeout), _timerCallback);
      _running = true;
    }
    return _completer.future;
  }

  /// Cancel the timer
  void cancel() {
    if (_running) {
      _timer.cancel();
      _running = false;
      _completer.complete();
    }
  }

  /// The timer callback
  void _timerCallback() {
    _running = false;
    _completer.complete();
  }
}
