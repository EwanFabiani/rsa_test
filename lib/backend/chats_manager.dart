import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_test/backend/storage.dart';
import 'package:rsa_test/backend/rsa_encrypt.dart';
import 'package:rsa_test/backend/rsa_sign.dart';
import 'dart:convert';
import 'message.dart';
import 'user.dart';
import 'encrypted_message.dart';

const String endpoint = "http://45.84.196.211:8080";

Future<List<User>> getCurrentChats() async {
  final response = await http.get(Uri.parse("$endpoint/user/get_all"));
  String json = response.body;
  List<User> users = _usersFromJsonList(jsonDecode(json));
  return users;

}

List<User> _usersFromJsonList(List<dynamic> jsonList) {
  return jsonList.map((user) => User.fromJson(user)).toList();
}

List<String> usernameFromUsers(List<User> users) {
  return users.map((user) => user.username).toList();
}

Future<List<Message>> getDecryptedMessages (User current, User target) async {
  List<EncryptedMessage> encryptedMessages = await _getMessages(current, target);
  List<Message> decryptedMessages = [];
  final RSAPrivateKey privateKey = await getPrivateKey();

  for (EncryptedMessage encryptedMessage in encryptedMessages) {
    if (encryptedMessage.verifySignature(target.getPublicKey())) {
      Message decryptedMessage = encryptedMessage.decryptMessage(privateKey);
      decryptedMessages.add(decryptedMessage);
    }
  }
  return decryptedMessages;
}

Future<List<EncryptedMessage>> _getMessages(User current, User target) async {
  final response = await http.post(
    Uri.parse("$endpoint/message/get_chat"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "sender": target.username,
      "receiver": current.username
    }),
  );
  String json = response.body;
  List<EncryptedMessage> messages = _messagesFromJsonList(jsonDecode(json));
  return messages;
}

List<EncryptedMessage> _messagesFromJsonList(List<dynamic> jsonList) {
  return jsonList.map((message) => EncryptedMessage.fromJson(message)).toList();
}

Future<void> sendMessage(User current, User target, String message) async {

  RSAPrivateKey privateKey = await getPrivateKey();

  String encryptedMessage = _encryptMessage(message, target.getPublicKey());
  String encodedSignature = _signMessage(encryptedMessage, privateKey);

  final response = await http.post(
    Uri.parse("$endpoint/message/send"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "sender": target.username,
      "receiver": current.username,
      "data": encryptedMessage,
      "signature": encodedSignature
    }),
  );
  print(response.body);
  print(response.statusCode);
  //HANDLE RESPONSE!!!
}

String _encryptMessage(String message, RSAPublicKey publicKey) {
  Uint8List encryptedMessage = rsaEncrypt(publicKey, utf8.encode(message));
  String encodedMessage = base64Encode(encryptedMessage);
  return encodedMessage;
}

String _signMessage(String message, RSAPrivateKey privateKey) {
  Uint8List signature = rsaSign(privateKey, utf8.encode(message));
  String encodedSignature = base64Encode(signature);
  return encodedSignature;
}