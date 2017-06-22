/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT connection class
class MqttConnection {
  /// The socket that maintains the connection to the MQTT broker.
  Socket tcpClient;

  /// Sync lock object to ensure that only a single message is sent through the connection handler at once.
  Object _sendPadlock = new Object();

  /// Initializes a new instance of the MqttConnection class.
  MqttConnection(String server, int port) {
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((socket) {
        tcpClient = socket;
      });
    } catch (SocketException) {
      final String message =
          "The connection to the message broker {$server}:{$port} could not be made.";
      throw new NoConnectionException(message);
    }
  }

  /// Initiate a new connection to a message broker
  static MqttConnection connect(String server, int port) {
    return new MqttConnection(server, port);
  }
}
