import 'package:nfc_manager/nfc_manager.dart';

void startBlock() {
  NfcManager.instance.startSession(
    onDiscovered: (NfcTag tag) async {

    },
  );
}

void stopBlock() {
  NfcManager.instance.stopSession();
}