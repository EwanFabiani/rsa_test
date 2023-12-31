import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rsa_test/backend/qr_manager.dart';
import 'package:rsa_test/frontend/showuser.dart';

import '../backend/secure_storage.dart';

class QRCodeWidget extends StatelessWidget {

  const QRCodeWidget();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getCurrentUser(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          String userName = snapshot.data.username;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(userName),
              backgroundColor: Colors.white,
              elevation: 0.0,
            ),
            body: Center(
              child: FutureBuilder(
                future: createQrCode(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return snapshot.data;
                  }
                },
              ),
            ),
          );
        }
      },
    );
  }
}


class QRScannerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a new contact'),
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
                        builder: (context) => const QRCodeWidget(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Show my QR Code'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue,
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
                  icon: const Icon(Icons.camera),
                  label: const Text('Scan a QR code'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRViewExample(),
                      ),
                    );
                  },
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


class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Text('Flash: ${snapshot.data}');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = MediaQuery.of(context).size.width * 0.7;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      controller.pauseCamera();
      if(!isValidQrData(scanData.code!)) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Scan result"),
              content: Text(scanData.code!),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.resumeCamera();
                    },
                    child: const Text("OK"))
              ],
            );
          }
        );
      }else {
        getUserFromQrData(scanData.code!).then((user) {
          Map<String, dynamic> json = jsonDecode(scanData.code!);
          var publicKeyFingerprint = json["public_fingerprint"];
          Uint8List publicFingerprintBytes = base64Decode(publicKeyFingerprint);
          //make it into hex
          publicKeyFingerprint = "0x${publicFingerprintBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}";

          Navigator.pop(context, [user, publicKeyFingerprint]);
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

        });
      }

    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

