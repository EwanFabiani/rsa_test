import 'package:flutter/material.dart';
import 'package:rsa_test/backend/block_nfc_service.dart';
import 'package:rsa_test/backend/secure_storage.dart';
import 'package:rsa_test/frontend/qr.dart';
import 'backend/account_manager.dart';
import 'backend/chat.dart';
import 'backend/message.dart';
import 'backend/rsa_keygen.dart';
import 'backend/chats_manager.dart';
import 'backend/user.dart';
import 'frontend/chat_rooms.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isSetup = await isPrivateKeySetup();

  print("isSetup: $isSetup");

  startBlock();

  runApp(MyApp(isSetup));

}

class MyApp extends StatelessWidget {
  const MyApp(this.isSetup, {super.key});

  final bool isSetup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isSetup? ChatRoomsPage() : const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  final String _labelText = '';
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    // Create a TextEditingController
    final usernameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create my account'),
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: usernameController,  // Use the controller here
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                return isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: () async {
                    _isLoading.value = true;
                    createAccount(usernameController.text);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatRoomsPage()),
                    );
                  },
                  child: const Text('Create My Account'),
                );
              },
            ),
            Text(_labelText),
          ],
        ),
      ),
    );
  }
}