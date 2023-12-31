import 'package:flutter/material.dart';
import 'package:rsa_test/backend/secure_storage.dart';
import 'package:rsa_test/frontend/qr.dart';
import 'backend/account_manager.dart';
import 'backend/message.dart';
import 'backend/rsa_keygen.dart';
import 'backend/chats_manager.dart';
import 'backend/user.dart';
import 'frontend/qr.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isSetup = await isPrivateKeySetup();

  print("isSetup: $isSetup");

  runApp(MyApp(isSetup));

}

class MyApp extends StatelessWidget {
  MyApp(this.isSetup, {super.key});

  final bool isSetup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isSetup? const ChatRoomsPage() : const StartScreen(),
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
            ElevatedButton(
              onPressed: () {
                // Use the controller's value here
                createAccount(usernameController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatRoomsPage()),
                );
              },
              child: const Text('Create My Account'),
            ),
            Text(_labelText),
          ],
        ),
      ),
    );
  }
}



class ChatRoomsPage extends StatelessWidget {
  const ChatRoomsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: getCurrentChats(),
      builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // or your own loading widget
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final List<User> rooms = snapshot.data != null ? snapshot.data! : [];
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Chat Rooms'),
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 1.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: Text(
                          rooms[index].username[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        rooms[index].username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatPage(user: rooms[index])),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            floatingActionButton: SizedBox(
              width: 60.0,  // Set the width of the button
              height: 60.0,  // Set the height of the button
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QRScannerWidget(),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.secondary,
                mini: false,
                child: const Icon(
                  Icons.qr_code,
                  size: 35.0,  // Increase the icon size here
                ),
              ),
            ),


          );
        }
      },
    );
  }
}



class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.user}) : super(key: key);
  final User user;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final List<String> _messages = [];
  final _textController = TextEditingController();

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    User current = await getCurrentUser();
    sendMessage(current, widget.user, text);

    setState(() {
      _messages.insert(0, text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Message>>(
        future: getMessages(widget.user),
        builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // or your own loading widget
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final List<Message> messages = snapshot.data != null ? snapshot.data! : [];
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.user.username),
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .secondary,
              ),
              body: Column(
                children: <Widget>[
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (_, int index) =>
                          _buildMessage(messages[index]),
                    ),
                  ),
                  const Divider(height: 1.0),
                  _buildTextComposer(),
                ],
              ),
            );
          }
        }
    );
  }


  Widget _buildMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              message.sender[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              color: Theme.of(context).colorScheme.secondary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Text(
                  message.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: "Send a message",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            FloatingActionButton(
              onPressed: () => _handleSubmitted(_textController.text),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
