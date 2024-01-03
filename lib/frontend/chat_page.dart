import 'package:flutter/material.dart';

import '../backend/chats_manager.dart';
import '../backend/message.dart';
import '../backend/secure_storage.dart';
import '../backend/user.dart';

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

    //Prevents sending empty messages
    if (text.isEmpty) {
      return;
    }

    _textController.clear();

    User current = await getCurrentUser();
    await sendMessage(current, widget.user, text);

    print("SENDING MSG!");
    setState(() {});
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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
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
