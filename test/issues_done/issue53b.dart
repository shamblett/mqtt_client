import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

const clientId = '5bc71e3ea74ad804cc04a856';
const token = '2844865:b08b650bdef3774426b2b718f6ab2d6e';
const id = '2844865';

void main() async {
  Mqtt.init();

  MqttClientConnectionStatus val = await Mqtt.connect();
  print('===> Connection Result: $val');
  if (val != null) {
    Mqtt.subscribe();
    for (var i = 0; i <= 10; i++) {
      await Mqtt.subAndPub();
      print('Publish Attempt $i ......\n');
      await MqttUtilities.asyncSleep(2);
    }
  }
}

class Mqtt {
  static MqttServerClient client;

  static void init() {
    client = MqttServerClient('wss://m4.gap.im/mqtt', clientId);
    client.setProtocolV311();
    client.keepAlivePeriod = 60;
    client.port = 443;
    client.useWebSocket = true;
    client.logging(on: true);

    client.onDisconnected = () {
      print('\n\n\n==> Disconnected | Time: ${DateTime.now().toUtc()}\n\n\n');
      // client.disconnect();
    };

    client.connectionMessage = MqttConnectMessage()
        .authenticateAs(id, token)
        .withClientIdentifier(clientId);

    client.connectionMessage.startClean();
  }

  static Future connect() async {
    MqttClientConnectionStatus status;
    try {
      status = await client.connect();

      print('===> Connection Status: $status');
      return status;
    } catch (e) {
      print(e);
      return status;
    }
  }

  static dynamic subscribe() {
    return client.subscribe('u/$id', MqttQos.exactlyOnce);
  }

  static void subAndPub() async {
    // await MqttUtilities.asyncSleep(1);

    // This Works!
    var builder1 = MqttClientPayloadBuilder();
    builder1.addString(
      json.encode(
        {
          'type': 'msgText',
          'data': 'Works!',
          'identifier': Random().nextInt(1000000),
        },
      ),
    );

    client.publishMessage('u/$id', MqttQos.exactlyOnce, builder1.payload);
  }
}
