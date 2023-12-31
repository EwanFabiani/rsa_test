import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_test/backend/encrypted_message.dart';
import 'package:rsa_test/backend/user.dart';
import 'package:sqflite/sqflite.dart';

var db = openDatabase('rsa.db');

Future<void> createTables() async {
  await db.then((value) => value.execute(
      'CREATE TABLE IF NOT EXISTS contacts (username VARCHAR(32) PRIMARY KEY, public_modulus TEXT, public_exponent TEXT)'));
  await db.then((value) => value.execute(
      'CREATE TABLE IF NOT EXISTS messages (sender TEXT, receiver TEXT, message TEXT, signature TEXT, timestamp INTEGER)'));
}

Future<void> addContact(User user) async {
  await db.then((value) => value.transaction((txn) async {
        await txn.rawInsert(
            'INSERT INTO contacts(username, public_modulus, public_exponent) VALUES(?, ?, ?)',
            [user.username, user.modulus.toString(), user.exponent.toString()]);
      }));
}

Future<List<User>> getContacts() async {
  List<Map<String, dynamic>> contacts = await db.then((value) =>
      value.rawQuery('SELECT * FROM contacts ORDER BY username ASC'));
  return contacts
      .map((contact) => User(contact['username'], contact['public_modulus'],
          contact['public_exponent']))
      .toList();
}

Future<User> getUser(String username) async {
  List<Map<String, dynamic>> contacts = await db.then((value) => value.rawQuery(
      'SELECT * FROM contacts WHERE username = ? LIMIT 1', [username]));
  if (contacts.isEmpty) {
    throw Exception("User not found");
  }
  return User(contacts[0]['username'], contacts[0]['public_modulus'],
      contacts[0]['public_exponent']);
}

//Only add messages encrypted with the users public key
//Otherwise the messages cannot be decrypted
//Sign the messages with the senders private key
Future<void> localStoreMessage(EncryptedMessage message) async {
  await db.then((value) => value.transaction((txn) async {
        await txn.rawInsert(
            'INSERT INTO messages(sender, receiver, message, signature, timestamp) VALUES(?, ?, ?, ?, ?)',
            [
              message.sender,
              message.receiver,
              message.encryptedMessage,
              message.signature,
              message.timestamp.millisecondsSinceEpoch
            ]);
      }));
}

//get 10 latest messages between current user and target
Future<List<EncryptedMessage>> localGetMessages(
    User current, User target) async {
  List<Map<String, dynamic>> messages = await db.then((value) => value.rawQuery(
      'SELECT * FROM messages WHERE (sender = ? AND receiver = ?) OR (sender = ? AND receiver = ?) ORDER BY timestamp DESC LIMIT 10',
      [current.username, target.username, target.username, current.username]));
  return messages
      .map((message) => EncryptedMessage(
          message['sender'],
          message['receiver'],
          message['message'],
          message['signature'],
          DateTime.fromMillisecondsSinceEpoch(message['timestamp'])))
      .toList();
}