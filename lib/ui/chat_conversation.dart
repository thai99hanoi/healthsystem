import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heath_care/firebase/call_firebase.dart';
import 'package:heath_care/model/user.dart';
import 'package:heath_care/repository/user_repository.dart';
import 'components/body.dart';

class ConversationChat extends StatelessWidget {
  User friend;
  DocumentReference chatDocument;

  ConversationChat(this.chatDocument, this.friend);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Body(chatDocument),
    );
  }

  AppBar buildAppBar(BuildContext context) {
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
            Text(friend.getDisplayName(), style: TextStyle(fontSize: 16)),
            Text("Active 3m ago", style: TextStyle(fontSize: 12)),
          ])
        ]),
        actions: [
          IconButton(
              onPressed: () {
                pressCall(true);
              },
              icon: Icon(Icons.call)),
          IconButton(
              onPressed: () async {
                pressCall(false);
              },
              icon: Icon(Icons.video_call)),
          SizedBox(
            width: 4,
          ),
        ]);
  }

  Future<void> pressCall(bool isVoiceCall) async {
    try {
      User user = await UserRepository().getCurrentUser();
      await CallFireBase.getInstance()
          .makeCall(user, friend.username, chatDocument.id, isVoiceCall);
    } catch (e) {
      print(e);
    }
  }
}
