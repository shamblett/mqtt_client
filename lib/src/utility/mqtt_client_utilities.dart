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

/// Cancelable aysnchronous sleep support class
class MqttCanellableAsyncSleep {
  /// Timeout value in milliseconds
  MqttCanellableAsyncSleep(this._timeout);

  /// Millisecond timeout
  int _timeout;

  int get timeout => _timeout;

  /// The completer
  Completer _completer = new Completer();

  /// The timer
  Timer _timer;

  /// Timer running flag
  bool _running = false;

  bool get isRunning => _running;

  /// Start the timer
  Future sleep() {
    if (!_running) {
      _timer = new Timer(new Duration(milliseconds: _timeout), _timerCallback);
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
