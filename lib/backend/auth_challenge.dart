import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_test/backend/rsa_sign.dart';
import 'package:rsa_test/backend/secure_storage.dart';
import 'package:rsa_test/backend/user.dart';

const String endpoint = "http://45.84.196.211:8080";


Future<String> doChallenge(User current) async {
  String username = current.username;
  print(username);
  String challenge = await _getChallenge(username);
  String signature = await _solveChallenge(username, challenge);
  return signature;
}

Future<String> _getChallenge(String username) async {
  final response = await http.get(Uri.parse("$endpoint/auth/challenge/$username"));
  String challenge = response.body;
  print("Challenge generated: $challenge");
  return challenge;
}

Future<String> _solveChallenge(String username, String challenge) async {
  RSAPrivateKey privateKey = await getPrivateKey();
  Uint8List signature = rsaSign(privateKey, utf8.encode(challenge));
  String signatureString = base64Encode(signature);
  return signatureString;
}