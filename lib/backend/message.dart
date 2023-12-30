import 'package:rsa_test/backend/encrypted_message.dart';

class Message {
  final String sender;
  final String receiver;
  final String message;
  final DateTime timestamp;

  Message(this.sender, this.receiver, this.message, this.timestamp);

  Message.fromEncrypted(String decryptedMessage,
      EncryptedMessage encryptedMessage)
      :
        sender = encryptedMessage.sender,
        receiver = encryptedMessage.receiver,
        message = decryptedMessage,
        timestamp = encryptedMessage.timestamp;

}