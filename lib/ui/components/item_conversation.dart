import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heath_care/model/user.dart';
import 'package:heath_care/repository/user_repository.dart';
import 'package:heath_care/ui/components/item_image.dart';
import 'package:heath_care/utils/time_util.dart';

import '../chat_conversation.dart';

class ItemConversation extends StatelessWidget {
  String friendName;
  String lastMessage;
  Timestamp timeSend;
  QueryDocumentSnapshot chatDocument;

  ItemConversation(this.chatDocument, this.friendName, this.lastMessage,
      this.timeSend);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Route route = MaterialPageRoute(
            builder: (context) =>
                ConversationChat(chatDocument.reference, friendName));
        Navigator.push(context, route);
      },
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 20 * 0.75),
        child: Row(
          children: [
            FutureBuilder<User?>(
              future: UserRepository().getUserByUserName(friendName),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ItemNetworkImage(image:snapshot.data!.avatar);
                } else {
                  return CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/img_1.png'),
                  );
                }
              },
            ),
            Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendName,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Opacity(
                        opacity: 0.64,
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                )),
            Opacity(
              opacity: 0.64,
              child: Text(getTimeMess(timeSend)),
            )
          ],
        ),
      ),
    );
  }
}
