/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Records the status of the last connection attempt
class MqttClientConnectionStatus {
  /// Connection state
  MqttConnectionState state = MqttConnectionState.disconnected;

  /// Return code
  MqttConnectReturnCode? returnCode = MqttConnectReturnCode.noneSpecified;

  /// Disconnection origin
  MqttDisconnectionOrigin disconnectionOrigin = MqttDisconnectionOrigin.none;

  @override
  String toString() {
    final s = state.toString().split('.')[1];
    final r = returnCode.toString().split('.')[1];
    final t = disconnectionOrigin.toString().split('.')[1];
    return 'Connection status is $s with return code of $r and a disconnection origin of $t';
  }
}
