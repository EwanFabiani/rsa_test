import 'package:pointycastle/asymmetric/api.dart';
import 'package:http/http.dart' as http;
import 'package:rsa_test/backend/storage.dart';
import 'package:rsa_test/backend/user.dart';
import 'dart:convert';
import '../backend/rsa_keygen.dart';

const String endpoint = "http://45.84.196.211:8080";

void createAccount(String username) {

  final RSAPublicKey publicKey = generateAndStoreKeys();

  User current = User.fromKey(username, publicKey);

  storeUser(current);

  final response = _sendPublicKeyToServer(publicKey, username);
}

//Actually creates the account
Future<void> _sendPublicKeyToServer(RSAPublicKey publicKey, String username) async {

  String modulus = base64Encode(utf8.encode(publicKey.modulus.toString()));
  String exponent = base64Encode(utf8.encode(publicKey.exponent.toString()));

  try {
    final response = await http.post(
      Uri.parse("$endpoint/user/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "username": username,
        "modulus": modulus,
        "exponent": exponent
      }),
    );

    if (response.statusCode == 200) {
      print('Public key sent to server successfully.');
    } else {
      print('Failed to send public key to server. Status code: ${response
          .statusCode}');
    }
  } catch (e) {
    print('An error occurred: $e');
  }
}