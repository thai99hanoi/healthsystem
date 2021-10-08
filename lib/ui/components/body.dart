import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:heath_care/model/message.dart';
import 'package:heath_care/model/user.dart';
import 'package:heath_care/repository/user_repository.dart';
import 'package:heath_care/socket/websocket.dart';

import 'chat_input_field.dart';

class Body extends StatelessWidget {
  Future<User?> _currentUser = UserRepository().getCurrentUser();

  DocumentReference chatDocument;
  ScrollController _controller = ScrollController();

  Body(this.chatDocument);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
        future: _currentUser,
        builder: (context, snapshotUser) {
          if (snapshotUser.hasData) {
            return Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                      stream: chatDocument.snapshots(),
                      builder:
                          (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasData &&
                            (snapshot.data!['messages'] as List).isNotEmpty) {
                          SchedulerBinding.instance!.addPostFrameCallback((_) {
                            _controller
                                .jumpTo(_controller.position.maxScrollExtent);
                          });
                          return ListView.builder(
                              controller: _controller,
                              itemCount:
                                  (snapshot.data!['messages'] as List).length,
                              itemBuilder: (context, index) {
                                List messages =
                                    snapshot.data!['messages'] as List;
                                if (messages[index]['from'] ==
                                    snapshotUser.data?.username) {
                                  return Container(
                                      alignment: Alignment.centerRight,
                                      width: MediaQuery.of(context).size.width *
                                          0.65,
                                      child: buildMessage(
                                          messages[index]['content'],
                                          Colors.blue,
                                          Colors.white));
                                }
                                return Container(
                                    alignment: Alignment.centerLeft,
                                    width: MediaQuery.of(context).size.width *
                                        0.65,
                                    child: buildMessage(
                                        messages[index]['content'],
                                        Colors.grey.shade300,
                                        Colors.black));
                              });
                        } else {
                          return Center(
                              child: Text("Bắt đầu trò chuyện ngay thôi!"));
                        }
                      }),
                ),
                ChatInputField((conent) {
                  Message message = Message(
                      snapshotUser.data!.username!, conent, Timestamp.now());
                  sendMessage(message);
                  print('press');
                }),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  void sendMessage(Message message) {
    chatDocument.update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
      'updated_time': message.createdTime
    });
  }

  Widget buildMessage(String content, Color background, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(
          content,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
