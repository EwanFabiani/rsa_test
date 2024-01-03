import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:rsa_test/backend/add_contacts_manager.dart';
import 'package:rsa_test/frontend/showuser.dart';

import '../backend/user.dart';

class NfcApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NfcAppState();
}

class NfcAppState extends State<NfcApp> {
  ValueNotifier<dynamic> result = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NFC Scanner'),
        ),
        body: Center(
          child: FutureBuilder<bool>(
            future: NfcManager.instance.isAvailable(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                if (snapshot.data!) { // NFC is available
                  _handleNFC();
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.nfc,
                        size: 100.0,
                      ),
                      Text(
                        'Scan NFC Tag',
                        style: TextStyle(fontSize: 24.0),
                      ),
                    ],
                  );
                } else { // NFC is not available
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 100.0, // Bigger icon
                      ),
                      Text(
                        'NFC is not enabled on your device',
                        style: TextStyle(color: Colors.red, fontSize: 18.0),
                      ),
                    ],
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _handleNFC() {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          Ndef? potentialNdef = Ndef.from(tag);
          if (potentialNdef == null) {
            result.value = 'Tag is not ndef';
            _displayAlert("Invalid Tag Type", "This NFC Type is not compatible with this app.");
          }
          Ndef ndef = potentialNdef!;
          NdefMessage msg = await ndef.read();
          List<NdefRecord> records = msg.records;
          Uint8List bytes = records[0].payload;
          String json = getStringFromAscii(bytes);
          print(json);
          _checkValidNFC(json);
        } catch (e) {
          _displayAlert("An Unknown Error Occurred!", "The app has encountered an unknown error while trying to read the NFC Tag.");
        } finally {

        }
      },
    );
  }

  void _stopNFC() {
    super.dispose();
    NfcManager.instance.stopSession();
  }

  void _displayAlert(String title, String content) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"))
            ],
          );
        }
    );
  }

  Future<void> _checkValidNFC(String data) async {
    if (isValidUserJsonData(data)) {
      User user = await getUserFromData(data);
      String publicKeyFingerprint = getHexFingerprintFromData(data);
      _showUser(user, publicKeyFingerprint);
    }else {
      _displayAlert("Invalid User Data!", "The data on this NFC Tag is not valid user data.");
    }
  }

  void _showUser(User user, String publicKeyFingerprint) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfile(
          profilePicUrl: 'https://ewanfabiani.dev/assets/projects/bot.svg',
          user: user,
          publicKeyFingerprint: publicKeyFingerprint,
        ),
      ),
    );
  }

  void _ndefWrite() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createMime(
            'text/plain', Uint8List.fromList('Hello'.codeUnits)),
        NdefRecord.createExternal(
            'com.example', 'mytype', Uint8List.fromList('mydata'.codeUnits)),
      ]);

      try {
        await ndef.write(message);
        result.value = 'Success to "Ndef Write"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }
}