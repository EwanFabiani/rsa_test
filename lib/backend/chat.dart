import 'package:rsa_test/backend/encrypted_message.dart';

import 'user.dart';

class Chat {
  final User target;
  final List<EncryptedMessage> unreadMessages;

  Chat(this.target, this.unreadMessages);

  int getUnreadMessagesCount() {
    return unreadMessages.length;
  }

}