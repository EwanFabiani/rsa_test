import 'dart:convert';

import 'package:pointycastle/export.dart';
import 'package:rsa_test/backend/message.dart';
import 'package:rsa_test/backend/rsa_encrypt.dart';
import 'package:intl/intl.dart';
import 'package:rsa_test/backend/rsa_sign.dart';

//SENDER RECEIVER PLAIN TEXT
//ENCRYPTED_MESSAGE AND SIGNATURE BASE64 ENCODED
//TIMESTAMP IN MILLISECONDS SINCE EPOCH
class EncryptedMessage {
  final String sender;
  final String receiver;
  final String encryptedMessage;
  final String signature;
  final DateTime timestamp;

  static DateFormat format = DateFormat('MMM dd, yyyy, h:mm:ss a');

  EncryptedMessage(this.sender, this.receiver, this.encryptedMessage, this.signature, this.timestamp);

  EncryptedMessage.fromJson(Map<String, dynamic> json)
      : sender = json['sender'],
        receiver = json['receiver'],
        encryptedMessage = json['message'],
        signature = json['signature'],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);


  bool verifySignature(RSAPublicKey publicKey) {
    final signature = RSASignature(base64Decode(this.signature));

    return rsaVerify(publicKey, utf8.encode(encryptedMessage), signature.bytes);
  }

  //MAKE SURE TO VERIFY SIGNATURE BEFORE DECRYPTING!
  Message decrypt(RSAPrivateKey privateKey) {
    final cipher = base64Decode(encryptedMessage);
    final decrypted = rsaDecrypt(privateKey, cipher);
    return Message.fromEncrypted(utf8.decode(decrypted), this);
  }




}