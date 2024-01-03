import 'package:flutter/material.dart';
import 'package:rsa_test/frontend/qr.dart';

import 'nfc.dart';

class AddContact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new contact'),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NfcApp(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.nfc,
                    size: 30,
                  ),
                  label: const Text(
                    'Scan an NFC tag (beta)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.orange,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0), bottom: Radius.circular(10.0)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0), // Add some space between the buttons
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NfcApp(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.camera,
                    size: 30,
                  ),
                  label: const Text(
                    'Scan a QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10.0), bottom: Radius.circular(20.0)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}