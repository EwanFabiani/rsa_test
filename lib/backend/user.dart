import 'dart:convert';

import 'package:pointycastle/asymmetric/api.dart';

//USERNAME ALWASY PLAIN TEXT
//MODULUS AND EXPONENT ALWAYS BASE64 ENCODED
class User {
  final String username;
  final String modulus;
  final String exponent;

  User(this.username, this.modulus, this.exponent);

  User.fromJson(Map<String, dynamic> json)
      : username = json['username'],
        modulus = json['modulus'],
        exponent = json['exponent'];

  User.fromKey(this.username, RSAPublicKey publicKey)
      : modulus = base64Encode(utf8.encode(publicKey.modulus.toString())),
        exponent = base64Encode(utf8.encode(publicKey.exponent.toString()));

  RSAPublicKey getPublicKey() {
    String modulus = utf8.decode(base64Decode(this.modulus));
    String exponent = utf8.decode(base64Decode(this.exponent));
    return RSAPublicKey(BigInt.parse(modulus), BigInt.parse(exponent));
  }

}