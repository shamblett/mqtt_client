# mqtt_client
[![Build Status](https://travis-ci.org/shamblett/mqtt_client.svg?branch=master)](https://travis-ci.org/shamblett/mqtt_client)

A server side MQTT client for Dart.

The client is an MQTT v3 implementation supporting subscription/publishing at all QOS levels,
keep alive and synchronous connection. The client is designed to take as much MQTT protocol work
off the user as possible, connection protocol is handled automatically as are the message exchanges needed
to support the different QOS levels and the keep alive mechanism. This allows the user to concentrate on
publishing/subscribing and not the details of MQTT itself.

An example of usage can be found in the examples directory, this example is runnable. The test directory
also contains standalone runnable scripts for subscription and publishing.

The client does not yet support web sockets or encrypted connections.

The code is a port from the C# [nMQTT](https://www.openhub.net/p/nMQTT) client library to Dart.




