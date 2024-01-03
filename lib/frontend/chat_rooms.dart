import 'package:flutter/material.dart';
import 'package:rsa_test/backend/secure_storage.dart';
import 'package:rsa_test/frontend/qr.dart';

import '../backend/chat.dart';
import '../backend/chats_manager.dart';
import '../backend/user.dart';
import 'add_contact.dart';
import 'chat_page.dart';

class ChatRoomsPage extends StatefulWidget {
  @override
  _ChatRoomsPageState createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getCurrentUser(),
        builder: (BuildContext context, AsyncSnapshot<User> userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (userSnapshot.hasError) {
            return Text('Error: ${userSnapshot.error}');
          } else {
            return FutureBuilder<List<Chat>>(
              future: getCurrentChats(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Chat>> chatsSnapshot) {
                if (chatsSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // or your own loading widget
                } else if (chatsSnapshot.hasError) {
                  return Text('Error: ${chatsSnapshot.error}');
                } else {
                  List<Chat> rooms = chatsSnapshot.data != null
                      ? chatsSnapshot.data!
                      : [];
                  return Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      title: const Text('Chat Rooms'),
                      backgroundColor: Theme.of(context).colorScheme.onSecondary,
                      actions: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0), // Add your desired padding here
                          child: IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              size: 30.0,
                            ),
                            onPressed: () {
                              setState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 16, 0), // Add your desired padding here
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              size: 30.0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRGenerator(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
                                  rooms[index].target.username[0],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                rooms[index].target.username == userSnapshot.data!.username
                                    ? "${rooms[index].target.username} (You)"
                                    : rooms[index].target.username,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              trailing: rooms[index].getUnreadMessagesCount() > 0 ? Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                child: Text(
                                  '${rooms[index].getUnreadMessagesCount()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ) : null,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(user: rooms[index].target),
                                  ),
                                );
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),



                    ),
                    floatingActionButton: SizedBox(
                      width: 60.0, // Set the width of the button
                      height: 60.0, // Set the height of the button
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddContact(),
                            ),
                          );
                        },
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .secondary,
                        mini: false,
                        child: const Icon(
                          Icons.qr_code,
                          size: 35.0, // Increase the icon size here
                        ),
                      ),

                    ),
                  );
                }
              },
            );
          }
        }
    );
  }
}