/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

///  This class provides shared connection functionality to connection handler implementations.
abstract class MqttConnectionHandler implements IMqttConnectionHandler {
  MqttConnection connection;

  /// Registry of message processors
  Map<MqttMessageType, MessageCallbackFunction> messageProcessorRegistry =
  new Map<MqttMessageType, MessageCallbackFunction>();

  /// Registry of sent message callbacks
  List<MessageCallbackFunction> sentMessageCallbacks =
  new List<MessageCallbackFunction>();

  ConnectionState connectionState = ConnectionState.disconnected;

  /// Initializes a new instance of the <see cref="MqttConnectionHandler" /> class.
  MqttConnectionHandler();

  /// Connect to the specific Mqtt Connection.
  ConnectionState connect(String server, int port, MqttConnectMessage message) {
    try {
      connectionState = internalConnect(server, port, message);
    } catch (ConnectionException) {
      connectionState = ConnectionState.faulted;
      rethrow;
    }
    return connectionState;
  }

  /// Connect to the specific Mqtt Connection.
  ConnectionState internalConnect(String hostname, int port,
      MqttConnectMessage message);

  /// Sends a message to the broker through the current connection.
  void sendMessage(MqttMessage message) {
    final typed.Uint8Buffer buff = new typed.Uint8Buffer();
    final MqttByteBuffer stream = new MqttByteBuffer(buff);
    message.writeTo(stream);
    stream.seek(0);
    connection.send(stream);
    // Let any registered people know we're doing a message.
    for (MessageCallbackFunction callback in sentMessageCallbacks) {
      callback(message);
    }
  }

  /// Runs the disconnection process to stop communicating with a message broker.
  ConnectionState disconnect();

  /// Closes the connection to the Mqtt message broker.
  void close() {
    if (connectionState == ConnectionState.connected) {
      disconnect();
    }
  }

  /// Registers for the receipt of messages when they arrive.
  void registerForMessage(MqttMessageType msgType,
      MessageCallbackFunction callback) {
    messageProcessorRegistry[msgType] = callback;
  }

  /// UnRegisters for the receipt of messages when they arrive.
  void unRegisterForMessage(MqttMessageType msgType) {
    messageProcessorRegistry.remove(msgType);
  }

  /// Registers a callback to be called whenever a message is sent.
  void registerForAllSentMessages(MessageCallbackFunction sentMsgCallback) {
    sentMessageCallbacks.add(sentMsgCallback);
  }

  /// UnRegisters a callback that is called whenever a message is sent.
  void unRegisterForAllSentMessages(MessageCallbackFunction sentMsgCallback) {
    sentMessageCallbacks.remove(sentMsgCallback);
  }

  /// Handles the DataAvailable event of the connection control for handling non connection messages
  void messageDataAvailable(events.Event<MessageDataAvailable> event) {
    try {
      // Read the message, and if it's valid, signal to the keepalive so that we don't
      // spam ping requests at the broker.
      final MqttMessage msg = MqttMessage.createFrom(event.data.stream);
      final MessageCallbackFunction callback =
      messageProcessorRegistry[msg.header.messageType];
      callback(msg);
    } catch (InvalidMessageException) {
      rethrow;
    }
  }
}
