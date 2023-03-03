/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 03/03/2023
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// Helper enumeration for socket options
enum MqttSocketOptionType { boolean, integer }

// Helper class for socket options
class MqttSocketOptionValue {
  var type = MqttSocketOptionType.integer;
  var level = 0;
  var option = 0;
  var intValue = 0;
  var boolValue = false;
}

/// A class to allow socket options to be set on server TCP sockets.
///
/// This class supports setting of both integer and boolean raw socket options
/// as supported by the Dart IO library [RawSocketOption](https://api.dart.dev/stable/2.19.3/dart-io/RawSocketOption-class.html) class.
/// Please consult the documentation for the above class before using this class.
///
/// The socket options are set on both the initial connect and auto reconnect.
///
/// This class performs no sanity checking of the values provided, what values are set are
/// passed on to the socket untouched, as such, care should be used when using this feature,
/// socket options are usually platform specific and can cause numerous failures at the network
/// level for the unwary.
class MqttSocketOption {

  MqttSocketOption();

  /// Option value
  MqttSocketOption.fromOptionValue(MqttSocketOptionValue option) {
    _options.add(option);
  }

  /// Boolean socket option
  void fromBool(int level, int option, bool value) {
    final socketOptionValue = MqttSocketOptionValue();
    socketOptionValue.type = MqttSocketOptionType.boolean;
    socketOptionValue.level = level;
    socketOptionValue.option = option;
    socketOptionValue.boolValue = value;
    _options.add(socketOptionValue);
  }

  /// Integer socket option
  void fromInt(int level, int option, int value) {
    final socketOptionValue = MqttSocketOptionValue();
    socketOptionValue.type = MqttSocketOptionType.integer;
    socketOptionValue.level = level;
    socketOptionValue.option = option;
    socketOptionValue.intValue = value;
    _options.add(socketOptionValue);
  }

  final List<MqttSocketOptionValue> _options = <MqttSocketOptionValue>[];

  /// The options
  List<MqttSocketOptionValue> get options => _options;

  /// Any options set, true if any set
  bool get hasOptions => _options.isNotEmpty;
}
