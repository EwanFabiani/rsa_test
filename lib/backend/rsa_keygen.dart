import 'package:pointycastle/src/platform_check/platform_check.dart';
import "package:pointycastle/export.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rsa_test/backend/secure_storage.dart';

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair() {

  final keyGen = RSAKeyGenerator();
  const bitLength = 4096;

  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      getSecureRandom()));

  final pair = keyGen.generateKeyPair();

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom getSecureRandom() {

  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)));
  return secureRandom;
}

Future<bool> isPrivateKeySetup() async {

  const storage = FlutterSecureStorage();

  String? privateModulus = await storage.read(key: "private_modulus");

  if (privateModulus == null) {
    return false;
  } else {
    return true;
  }

}

RSAPublicKey generateAndStoreKeys() {

    final pair = generateRSAkeyPair();
    final publicKey = pair.publicKey;
    final privateKey = pair.privateKey;

    storePrivateKey(privateKey);
    //UNCOMMENT FOR IT TO WORK!!!

    return publicKey;
}