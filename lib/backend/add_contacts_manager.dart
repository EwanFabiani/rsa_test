import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha256.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rsa_test/backend/secure_storage.dart';

import 'package:rsa_test/backend/user.dart';

const String endpoint = "http://45.84.196.211:8080";

bool isValidUserJsonData(String data) {
  try {
    //check if data has the correct format
    //It has to have 3 keys: username, modulus and exponent
    Map<String, dynamic> json = jsonDecode(data);
    if (json.length != 3) {
      return false;
    }
    if (!json.containsKey("username") || !json.containsKey("public_fingerprint") || !json.containsKey("exponent")) {
      return false;
    }
    //username should be between max. 32 characters
    if (json["username"].length > 32) {
      return false;
    }
    //modulus and exponent should be base64 encoded
    if (base64Decode(json["public_fingerprint"]).length != 32) {
      return false;
    }
    if (utf8.decode(base64Decode(json["exponent"])) != "65537") {
      return false;
    }
    return true;
  } catch (e) {
    return false;
  }
}

Future<User> getUserFromData(String data) async {
  Map<String, dynamic> json = jsonDecode(data);
  final username = json["username"];
  final publicFingerprint = json["public_fingerprint"];
  final exponent = json["exponent"];

  User user = await _requestUserFromUsername(username);

  if (verifyUser(user, publicFingerprint, exponent)) {
    return user;
  }
  throw Exception("User verification failed");
}

bool verifyUser(User user, String publicFingerprint, String exponent) {
  if (user.exponent != exponent) {
    return false;
  }
  Uint8List publicFingerprintBytes = base64Decode(publicFingerprint);
  Uint8List userFingerprintBytes = _sha256Digest(utf8.encode(user.modulus));
  return base64Encode(publicFingerprintBytes) == base64Encode(userFingerprintBytes);
}

String getHexFingerprintFromData(String data) {
  Map<String, dynamic> json = jsonDecode(data);
  String publicKeyFingerprint = json["public_fingerprint"];
  Uint8List publicFingerprintBytes = base64Decode(publicKeyFingerprint);
  //turning it into hex
  publicKeyFingerprint = "0x${publicFingerprintBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}";
  return publicKeyFingerprint;

}

Future<User> _requestUserFromUsername(String username) async {
  final response = await http.post(Uri.parse("$endpoint/user/get_user"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "username": username,
      })
  );

  //Create user from response
  String json = response.body;
  Map<String, dynamic> jsonMap = jsonDecode(json);
  return User.fromJson(jsonMap);

}

Uint8List _sha256Digest(Uint8List dataToDigest) {
  final d = SHA256Digest();

  return d.process(dataToDigest);
}

Future<QrImageView> createQrCode() async {
  User user = await getCurrentUser();
  String username = user.username;
  Uint8List publicFingerprintBytes = _sha256Digest(utf8.encode(user.modulus));
  String publicFingerprint = base64Encode(publicFingerprintBytes);
  String exponent = user.exponent;

  Map<String, dynamic> json = {
    "username": username,
    "public_fingerprint": publicFingerprint,
    "exponent": exponent
  };

  String data = jsonEncode(json);

  return QrImageView(data: data);
}

String getStringFromAscii(Uint8List bytes) {
  String result = "";
  //the first character is a NUL character, and it breaks the string
  for (int i = 1; i < bytes.length; i++) {
    result = result + ascii.decode([bytes[i]]);
    print(ascii.decode([bytes[i]]));
  }
  return result;
}