part of mqtt_server_client;

class MqttSocketException implements Exception {
  MqttSocketException(this.exception);

  final SocketException exception;

  @override
  String toString() {
    return 'MqttSocketException{exception: $exception}';
  }
}
