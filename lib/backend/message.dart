import 'dart:convert';

import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_test/backend/encrypted_message.dart';
import 'package:rsa_test/backend/rsa_encrypt.dart';
import 'package:rsa_test/backend/rsa_sign.dart';

//ALWAYS IN PLAIN TEXT
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

  EncryptedMessage encryptAndSign(RSAPublicKey receiverKey, RSAPrivateKey senderKey) {
    final encrypted = base64Encode(rsaEncrypt(receiverKey, utf8.encode(message)));
    final signature = base64Encode(rsaSign(senderKey, utf8.encode(encrypted)));
    return EncryptedMessage(sender, receiver, encrypted, signature, timestamp);
  }

}