/*
 * Package : mqtt_browser_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/01/2020
 * Copyright :  S.Hamblett
 */

library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:event_bus/event_bus.dart' as events;
import 'package:typed_data/typed_data.dart' as typed;
import 'package:web/web.dart';
import 'mqtt_client.dart';

part 'src/mqtt_browser_client.dart';
part 'src/connectionhandling/browser/mqtt_client_mqtt_browser_connection_handler.dart';
part 'src/connectionhandling/browser/mqtt_client_synchronous_mqtt_browser_connection_handler.dart';
part 'src/connectionhandling/browser/mqtt_client_mqtt_browser_ws_connection.dart';
part 'src/connectionhandling/browser/mqtt_client_mqtt_browser_connection.dart';
