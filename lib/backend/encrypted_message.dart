import 'dart:convert';

import 'package:pointycastle/export.dart';
import 'package:rsa_test/backend/message.dart';
import 'package:rsa_test/backend/rsa_encrypt.dart';

class EncryptedMessage {
  final String sender;
  final String receiver;
  final String encryptedMessage;
  final String signature;
  final DateTime timestamp;

  EncryptedMessage(this.sender, this.receiver, this.encryptedMessage, this.signature, this.timestamp);

  EncryptedMessage.fromJson(Map<String, dynamic> json)
      : sender = json['sender'],
        receiver = json['receiver'],
        encryptedMessage = json['encryptedMessage'],
        signature = json['signature'],
        timestamp = DateTime.parse(json['timestamp']);


  bool verifySignature(RSAPublicKey publicKey) {
    final signature = RSASignature(base64Decode(this.signature));

    final verifier = RSASigner(SHA256Digest(), "0609608648016503040201");

    verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

    try {
      return verifier.verifySignature(base64Decode(encryptedMessage), signature);
    } catch (e) {
      return false;
    }
  }

  //MAKE SURE TO VERIFY SIGNATURE BEFORE DECRYPTING!
  Message decryptMessage(RSAPrivateKey privateKey) {
    final cipher = base64Decode(encryptedMessage);
    final decrypted = rsaDecrypt(privateKey, cipher);
    return Message.fromEncrypted(utf8.decode(decrypted), this);
  }




}