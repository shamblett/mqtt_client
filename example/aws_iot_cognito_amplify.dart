/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/04/2022
 * Copyright :  S.Hamblett
 *
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';

import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:http/http.dart';
import 'package:sigv4/sigv4.dart';

/// An example of connecting to the AWS IoT Core MQTT broker and publishing to a devices topic.
/// This example uses MQTT over Websockets with AWS IAM Credentials
/// This is a proven working example, but it requires some preparation. You will need to get Cognito credentials from somewhere, and your IAM policies set up properly.
/// The first two functions are helpers, please look at the main() for the client setup
/// More instructions can be found at https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html and
/// https://docs.aws.amazon.com/iot/latest/developerguide/protocols.html, please read this
/// before setting up and running this example.

// This function is based on the one from package flutter-aws-iot, but adapted slightly
String getWebSocketURL(
    {required String accessKey,
    required String secretKey,
    required String sessionToken,
    required String region,
    required String scheme,
    required String endpoint,
    required String urlPath}) {
  final creds = AWSCredentials(accessKey, secretKey, sessionToken);

  final signer = AWSSigV4Signer(
    credentialsProvider: AWSCredentialsProvider(creds),
  );

  final scope = AWSCredentialScope(
      region: region, service: AWSService('iotdevicegateway'));

  final request = AWSHttpRequest(
    method: AWSHttpMethod.get,
    uri: Uri.https(endpoint, urlPath),
  );

  ServiceConfiguration serviceConfiguration =
      const BaseServiceConfiguration(omitSessionToken: true);

  var signed = signer.presignSync(request,
      credentialScope: scope,
      expiresIn: Duration(hours: 1),
      serviceConfiguration: serviceConfiguration);
  var finalParams = signed.query;
  return '$scheme$endpoint$urlPath?$finalParams';
}

Future<bool> attachPolicy(
    {required String accessKey,
    required String secretKey,
    required String sessionToken,
    required String identityId,
    required String iotApiUrl,
    required String region,
    required String policyName}) async {
  final sigv4Client = Sigv4Client(
      keyId: accessKey,
      accessKey: secretKey,
      sessionToken: sessionToken,
      region: region,
      serviceName: 'execute-api');

  final body = json.encode({'target': identityId});

  final request =
      sigv4Client.request('$iotApiUrl/$policyName', method: 'PUT', body: body);

  var result = await put(request.url, headers: request.headers, body: body);

  if (result.statusCode != 200) {
    print('Error attaching IoT Policy ${result.body}');
  }

  return result.statusCode == 200;
}

Future<int> main() async {
  // Your AWS region
  const region = '<region>';
  // Your AWS IoT Core endpoint url
  const baseUrl = '<your-endpoint-id>.iot.$region.amazonaws.com';
  const scheme = 'wss://';
  const urlPath = '/mqtt';
  // AWS IoT MQTT default port for websockets
  const port = 443;
  // Your AWS IoT Core control API endpoint (https://docs.aws.amazon.com/general/latest/gr/iot-core.html#iot-core-control-plane-endpoints)
  const iotApiUrl = 'https://iot.$region.amazonaws.com/target-policies';
  // The AWS IOT Core policy name that you want to attach to the identity
  const policyName = '<iot-policy-name>';

  // The necessary AWS credentials to make a connection.
  // Obtaining them is not part of this example, but you can get the below credentials via any cognito/amplify library like amazon_cognito_identity_dart_2 or amplify_auth_cognito.
  String accessKey = '<aws-access-key>';
  String secretKey = '<aws-secret-key>';
  String sessionToken = '<aws-session-token>';
  String identityId = '<identity-id>';

  // PLEASE READ CAREFULLY
  // This attaches an iot policy to an identity id to allow iot core access
  // When using Cognito Federated identity pools, there are AUTHENTICATED and UNAUTHENTICATED (guest) identities (https://docs.aws.amazon.com/cognito/latest/developerguide/identity-pools.html).
  // You MUST attach a policy for an AUTHENTICATED user to allow access to iot core (regular cognito or federated id)
  // You CAN attach a policy to an UNAUTHENTICATED user for control, but this is not necessary
  // Make sure that the the credentials that call this API have the right IAM permissions for AttachPolicy (https://docs.aws.amazon.com/iot/latest/apireference/API_AttachPolicy.html)
  if (!await attachPolicy(
      accessKey: accessKey,
      secretKey: secretKey,
      sessionToken: sessionToken,
      identityId: identityId,
      iotApiUrl: iotApiUrl,
      region: region,
      policyName: policyName)) {
    print('MQTT client setup error - attachPolicy failed');
    exit(-1);
  }

  // Transform the url into a Websocket url using SigV4 signing
  String signedUrl = getWebSocketURL(
      accessKey: accessKey,
      secretKey: secretKey,
      sessionToken: sessionToken,
      region: region,
      scheme: scheme,
      endpoint: baseUrl,
      urlPath: urlPath);

  // Create the client with the signed url
  MqttServerClient client = MqttServerClient.withPort(
      signedUrl, identityId, port,
      maxConnectionAttempts: 2);

  // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will not receive a connect ack with the response code
  client.setProtocolV311();
  // logging if you wish
  client.logging(on: false);
  client.useWebSocket = true;
  client.secure = false;
  client.autoReconnect = true;
  client.disconnectOnNoResponsePeriod = 90;
  client.keepAlivePeriod = 30;

  final MqttConnectMessage connMess =
      MqttConnectMessage().withClientIdentifier(identityId);

  client.connectionMessage = connMess;

  // Connect the client
  try {
    print('MQTT client connecting to AWS IoT using cognito....');
    await client.connect();
  } on Exception catch (e) {
    print('MQTT client exception - $e');
    client.disconnect();
    exit(-1);
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('MQTT client connected to AWS IoT');

    // Publish to a topic of your choice
    const topic = '/test/topic';
    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello World');
    // Important: AWS IoT Core can only handle QOS of 0 or 1. QOS 2 (exactlyOnce) will fail!
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    // Subscribe to the same topic
    client.subscribe(topic, MqttQos.atLeastOnce);
    // Print incoming messages from another client on this topic
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });
  } else {
    print(
        'ERROR MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
  }

  print('Sleeping....');
  await MqttUtilities.asyncSleep(10);

  print('Disconnecting');
  client.disconnect();

  return 0;
}
