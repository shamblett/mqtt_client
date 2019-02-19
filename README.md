# mqtt_client
[![Build Status](https://travis-ci.org/shamblett/mqtt_client.svg?branch=master)](https://travis-ci.org/shamblett/mqtt_client)

A server side MQTT client for Dart.

The client is an MQTT v3(3.1 and 3.1.1) implementation supporting subscription/publishing at all QOS levels,
keep alive and synchronous connection. The client is designed to take as much MQTT protocol work
off the user as possible, connection protocol is handled automatically as are the message exchanges needed
to support the different QOS levels and the keep alive mechanism. This allows the user to concentrate on
publishing/subscribing and not the details of MQTT itself.

Examples of usage can be found in the examples directory.  An example is also provided
showing how to use the client to connect to the mqtt-bridge of Google's IoT-Core suite. This demonstrates
how to use secure connections and switch MQTT protocols. The test directory also contains standalone runnable scripts demonstrating subscription, publishing and topic filtering.

The client supports both normal and secure TCP connections and server side secure(wss) and non-secure(ws) websocket connections.

The client has been used successfully with the MQTT brokers from several of the major cloud providers IOT/MQTT
platforms, including :-
* Google IOT Core
* Amazon AWS
* Microsoft Azure
* IBM

It has also been used with a range of both publicly available brokers such as Mosquitto and proprietary ones.
An example using the adafruit MQTT broker for flutter can be found [here](https://github.com/BitKnitting/flutter_adafruit_mqtt).

The code is a port from the C# [nMQTT](https://www.openhub.net/p/nMQTT) client library to Dart.




