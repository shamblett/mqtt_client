/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group("Exceptions", () {
    test("Client Identifier", () {
      final String clid = "ThisCLIDisMorethan23characterslong";
      final ClientIdentifierException exception = new ClientIdentifierException(
          clid);
      expect(
          exception.toString(),
          "mqtt-client::ClientIdentifierException: Client id $clid is too long at ${clid
              .length}, "
              "Maximum ClientIdentifier length is ${Constants
              .maxClientIdentifierLength}");
    });
  });
}
