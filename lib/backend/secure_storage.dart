import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_test/backend/user.dart';

Future<void> storePrivateKey(RSAPrivateKey privateKey) async {

  const storage = FlutterSecureStorage();

  final privateModulus = base64Encode(utf8.encode(privateKey.modulus.toString()));
  final privateExponent = base64Encode(utf8.encode(privateKey.exponent.toString()));
  final privateP = base64Encode(utf8.encode(privateKey.p.toString()));
  final privateQ = base64Encode(utf8.encode(privateKey.q.toString()));

  print("Private modulus: " + privateModulus);
  print("Private exponent: " + privateExponent);
  print("Private p: " + privateP);
  print("Private q: " + privateQ);

  await storage.write(key: "private_modulus", value: privateModulus);
  await storage.write(key: "private_exponent", value: privateExponent);
  await storage.write(key: "private_p", value: privateP);
  await storage.write(key: "private_q", value: privateQ);

}

Future<RSAPrivateKey> getPrivateKey() async {

  const storage = FlutterSecureStorage();

  String? privateModulus = await storage.read(key: "private_modulus");
  String? privateExponent = await storage.read(key: "private_exponent");
  String? privateP = await storage.read(key: "private_p");
  String? privateQ = await storage.read(key: "private_q");

  privateModulus = utf8.decode(base64Decode(privateModulus!));
  privateExponent = utf8.decode(base64Decode(privateExponent!));
  privateP = utf8.decode(base64Decode(privateP!));
  privateQ = utf8.decode(base64Decode(privateQ!));

  return RSAPrivateKey(
    BigInt.parse(privateModulus!),
    BigInt.parse(privateExponent!),
    BigInt.parse(privateP!),
    BigInt.parse(privateQ!),
  );
}

Future<void> storeUser(User user) async {
  const storage = FlutterSecureStorage();

  final username = user.username;
  final publicModulus = base64Encode(utf8.encode(user.modulus.toString()));
  final publicExponent = base64Encode(utf8.encode(user.exponent.toString()));

  await storage.write(key: "username", value: username);
  await storage.write(key: "public_modulus", value: publicModulus);
  await storage.write(key: "public_exponent", value: publicExponent);
}

Future<User> getCurrentUser() async {
  const storage = FlutterSecureStorage();

  String? username = await storage.read(key: "username");
  String? publicModulus = await storage.read(key: "public_modulus");
  String? publicExponent = await storage.read(key: "public_exponent");

  publicModulus = utf8.decode(base64Decode(publicModulus!));
  publicExponent = utf8.decode(base64Decode(publicExponent!));

  return User(username!, publicModulus!, publicExponent!);


}
