# mqtt_client
[![Build Status](https://travis-ci.org/shamblett/mqtt_client.svg?branch=master)](https://travis-ci.org/shamblett/mqtt_client)

A server side MQTT client for Dart.

The client is an MQTT v3 implementation supporting subscription/publishing at all QOS levels,
keep alive and synchronous connection. An example of usage can be found in the examples directory,
the test directory also contains runnable publish/subscription examples, currently using the Mosquitto
MQTT server.

The client does not yet support web sockets or encrypted connections.

The code is a port from the C# [nMQTT](https://www.openhub.net/p/nMQTT) client library to Dart.



