#9.3.0
Issues 273, 275 and 276

#9.2.0
Issue 154 

#9.1.0
Issues 263, 247, 255 and 253

#9.0.0
Issue 241(NNBD) and issue 242

#8.2.0
Issues 231 and 243

#8.1.0
Issues 213, 230, 229

# 8.0.0
Issues 209, 210<br>
Note that auto reconnect will now automatically re subscribe
any active confirmed subscriptions by default, if you do not want this
behaviour see the documentation for the new resubscribeOnAutoReconnect
setting.

# 7.3.0
Issue 203

# 7.2.1
Pull request 191 bug fix

# 7.2.0
Pull request 191, mac connection attempts is now configurable.

# 7.1.1
Pull request 190 bug fix

# 7.1.0
Issue 172 bug fix

# 7.0.0
Issue 172 + 177 + 181
issue 172 introduces a breaking API change in the connection 
status class MqttClientConnectionStatus

# 6.2.1
Issue 173

# 6.2.0
Issue 90

# 6.1.0
Issue 163 and Issue 90

# 6.0.0
Addition of web based client, issue 144

If you are an existing user this is a breaking update, the MqttClient class has
now been replaced by the MqttServerClient class. This has exactly the same API as the 
MqttClient class so except for the class rename there should be no other changes.
If you are setting your own websocket protocols the protocol strings now reside
in the MqttConstants class.

# 5.6.3
Issue 142, correct misleading logging.
Issue 145, disconnection code tidy up.
Linter updates

# 5.6.2 
Issue 138, WS2 protocol string error

# 5.6.1
Issue 128, unsubscribe header error

# 5.6.0
Issue 127, callback added for bad certificate error

# 5.5.4
Fix for dart 2.5 usage (issue 99), remove flutter example  and issue 115.
Note that from here on in the client is not compatible with
Dart 2.4.x, if you want to stay on 2.4.x use client version
5.5.4 or lower.

# 5.5.3
Issues 85 and 87

# 5.5.2
Fix for dart 2.2 usage

# 5.5.1
Issue 81

# 5.5.0
Issues 69, 74 and 79

# 5.4.0
Issues 67 and 68

# 5.3.0
Issues 61, 62 and 63

# 5.2.0
Issues 59 + 60

# 5.1.0
Issues 54, 55 and 56

# 5.0.0
Roll up release for issues 48, 49, 50, 52 and 53, warning - breaking API change for connection state and security context
in secure mode hence the major version bump.

# 4.0.0
Issue 45, better connection fail reporting, update linter, note breaking API change
for turning logging on/off

# 3.3.6
Formatting

# 3.3.5
Issue 40, disconnected clients

# 3.3.4
Formatting

# 3.3.3
Issue 26, example code for flutter

# 3.3.2
Issue 38 QOS1 + 2 protocol handling bugs, Issue 34 Flutter buffers

# 3.3.1
Issue 38 QOS1 + 2 protocol handling bugs

# 3.3.0
Issue 37 onSubscribed and OnUnsubscribed callbacks

# 3.2.1
Issues 32 bug fix

# 3.2.0
Issues 32 and 35

# 3.1.0
Issues 27 and 29, pull request 30

# 3.0.0
Update to Dart 2, major version bump only to create a clean break from Dart 1

# 2.0.0
Issue 23, all subscriptions  are now on one client level observable, not on seperate ones per
subscription, this change is NOT backwards compatible

# 1.9.1
Issue 22, don't disconnect if we have no connection established

# 1.9.0
Issue 19, multitopic subscriptions + other more minor updates, API changed on this version.

# 1.8.0
Pull request 14, Making library more compliant to work with VerneMQ - explicit setting of will qos.

# 1.7.2
Issue 10, add library prefix for observable

# 1.7.1
Issue 10, update Observable version to 'any'

# 1.7.0
Add the payload builder utility.

# 1.6.1
Update Observable version

# 1.6.0
Remove eventable and its dependency on mirrors, replace with event_bus, issue 10

# 1.5.0
Fixes for issue 8, pub suggestions fixed.

# 1.4.0
Fixes for issues 5 and 6

# 1.3.0
Fixes for issues 3 and 4

# 1.2.0
Add secure sockets, server side only
Add ability to select the MQTT protocol between 3.1 and 3.1.1
A few code and test tidy ups
Tested to work with iot-core MQTT bridge

# 1.1.0
Add websockets as an alternative network connection
server side only

# 1.0.1
Fix unit tests on Travis

# 1.0.0
Initial release