import 'dart:convert';

import 'package:pointycastle/asymmetric/api.dart';

class User {
  final String username;
  final String modulus;
  final String exponent;

  User(this.username, this.modulus, this.exponent);

  User.fromJson(Map<String, dynamic> json)
      : username = json['username'],
        modulus = json['modulus'],
        exponent = json['exponent'];

  RSAPublicKey getPublicKey() {
    String modulus = utf8.decode(base64Decode(this.modulus));
    String exponent = utf8.decode(base64Decode(this.exponent));
    return RSAPublicKey(BigInt.parse(modulus), BigInt.parse(exponent));
  }

}