/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 07/04/2021
 * Copyright :  S.Hamblett
 */

/// The following scheme can be used conditionally import either the server or browser client
/// automatically.
///
/// import 'server.dart' if (dart.library.html) 'browser.dart' as mqttsetup;
/// ...
/// var client = mqttsetup.setup(serverAddress, uniqueID, port);
///
/// where server.dart will contain such as the following
///
/// MqttClient setup(String serverAddress, String uniqueID, int port) {
///   return MqttServerClient.withPort(serverAddress, uniqueID, port);
/// }
///
/// and browser.dart
///
/// MqttClient setup(String serverAddress, String uniqueID, int port) {
///  return MqttBrowserClient.withPort(serverAddress, uniqueID, port);
/// }
