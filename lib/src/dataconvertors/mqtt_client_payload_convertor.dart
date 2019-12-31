/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

///     Interface that defines the methods and properties that must be provided
///     by classes that interpret and convert inbound and outbound
///     published message data.
///
///     Types that implement this interface should be aware that for the
///     purposes of converting data from published messages
///     (byte array to object model) that the MqttSubscriptionsManager
///     creates a single instance of the data converter and uses it for
///     all messages that are received.
///
///     The same is true for the publishing of data to a broker.
///     The PublishingManager will also cache instances of the converters
///     until the MqttClient is disposed.
///     This means, in both cases you can store state in the data
///     converters if you wish, and that state will persist between messages
///     received or published, but only a default empty constructor is
///     supported.
abstract class PayloadConverter<T> {
  /// Converts received data from a raw byte array to an object graph.
  T convertFromBytes(typed.Uint8Buffer messageData);

  /// Converts sent data from an object graph to a byte array.
  typed.Uint8Buffer convertToBytes(T data);
}
