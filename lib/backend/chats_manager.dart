import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_test/backend/secure_storage.dart';
import 'package:rsa_test/backend/storage.dart';
import 'dart:convert';
import 'auth_challenge.dart';
import 'chat.dart';
import 'message.dart';
import 'user.dart';
import 'encrypted_message.dart';

const String endpoint = "http://45.84.196.211:8080";

Future<List<Chat>> getCurrentChats() async {
  List<User> contacts = await getContacts();
  List<EncryptedMessage> messages = await getServerUnreadMessages();

  List<Chat> chats = _buildChats(contacts, messages);

  return chats;
}

List<Chat> _buildChats(List<User> contacts, List<EncryptedMessage> messages) {
  List<Chat> chats = [];
  for (User contact in contacts) {
    List<EncryptedMessage> unreadMessages = [];
    for (EncryptedMessage message in messages) {
      if (message.sender == contact.username) {
        unreadMessages.add(message);
      }
    }
    chats.add(Chat(contact, unreadMessages));
  }
  return chats;
}

//THIS IS ALSO INCOMPATIBLE WITH CURRENT STANDARDS
List<User> _usersFromJsonList(List<dynamic> jsonList) {
  return jsonList.map((user) => User.fromJson(user)).toList();
}

List<String> usernameFromUsers(List<User> users) {
  return users.map((user) => user.username).toList();
}

Future<List<Message>> getMessages(User target) async {
  User current = await getCurrentUser();
  List<EncryptedMessage> encryptedMessages = await localGetMessages(current, target);
  List<Message> messages = await _decryptMessages(encryptedMessages);
  return messages;
}

Future<List<Message>> _decryptMessages(List<EncryptedMessage> encryptedMessages) async {
  List<Message> messages = [];
  for (EncryptedMessage encryptedMessage in encryptedMessages) {
    User sender = await getUser(encryptedMessage.sender);
    if (encryptedMessage.verifySignature(sender.getPublicKey())) {
      Message decryptedMessage = encryptedMessage.decrypt(await getPrivateKey());
      messages.add(decryptedMessage);
    }else {
      //TO IMPLEMENT IF VERIFICATION FAILS
      print("Verification failed1");
    }
  }
  return messages;
}

Future<List<EncryptedMessage>> _getServerMessages(User current, String challengeSignature) async {
  final response = await http.post(
    Uri.parse("$endpoint/message/get_all"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "user": current.username,
      "challengeSolve": challengeSignature,
    }),
  );
  String json = response.body;
  print(json);
  return _messagesFromJsonList(jsonDecode(json));
}

void _verifyAndStoreMessages(List<EncryptedMessage> messages) async {
  for (EncryptedMessage encryptedMessage in messages) {
    User sender = await getUser(encryptedMessage.sender);
    if (encryptedMessage.verifySignature(sender.getPublicKey())) {
      _storeMessage(encryptedMessage);
    }else {
      //TO IMPLEMENT IF VERIFICATION FAILS
      print("Verification failed2");
    }
  }
}

List<EncryptedMessage> _sortMessages(List<EncryptedMessage> messages) {
  messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return messages;
}

List<EncryptedMessage> _messagesFromJsonList(List<dynamic> jsonList) {
  return jsonList.map((message) => EncryptedMessage.fromJson(message)).toList();
}



Future<void> sendMessage(User current, User target, String message) async {

  //Prevent seeing your own message twice in your own chat
  if (current.username == target.username) {
    return;
  }

  RSAPrivateKey privateKey = await getPrivateKey();

  Message messageObject = Message(current.username, target.username, message, DateTime.now());

  //This is encrypted for the receiver, sending to server
  EncryptedMessage sendingMessage = messageObject.encryptAndSign(target.getPublicKey(), privateKey);

  //This is encrypted for the sender, storing in local database
  EncryptedMessage storedMessage = messageObject.encryptAndSign(current.getPublicKey(), privateKey);

  _transferMessage(sendingMessage);

  _storeMessage(storedMessage);
}

Future<void> _transferMessage(EncryptedMessage message) async {
  final response = await http.post(
    Uri.parse("$endpoint/message/send"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "sender": message.sender,
      "receiver": message.receiver,
      "data": message.encryptedMessage,
      "signature": message.signature,
    }),
  );
  //HANDLE RESPONSE!!!
}

Future<void> _storeMessage(EncryptedMessage message) async {
  await localStoreMessage(message);
}

Future<List<EncryptedMessage>> getServerUnreadMessages() async {
  User current = await getCurrentUser();

  String solvedChallenge = await doChallenge(current);

  List<EncryptedMessage> messages = await _getServerMessages(current, solvedChallenge);

  _verifyAndStoreMessages(messages);

  return messages;

}
