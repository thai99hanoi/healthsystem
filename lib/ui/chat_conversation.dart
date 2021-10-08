import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heath_care/model/message.dart';
import 'package:heath_care/model/user.dart';

import 'components/body.dart';

class ConversationChat extends StatelessWidget {
  String friendName;
  DocumentReference chatDocument;

  ConversationChat(this.chatDocument, this.friendName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Body(chatDocument),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            backgroundImage: AssetImage("assets/images/img_1.png"),
          ),
          SizedBox(
            width: 4,
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(friendName, style: TextStyle(fontSize: 16)),
            Text("Active 3m ago", style: TextStyle(fontSize: 12)),
          ])
        ]),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.call)),
          IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
          SizedBox(
            width: 4,
          ),
        ]);
  }
}
