import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heath_care/model/user.dart';
import 'package:heath_care/repository/user_repository.dart';
import 'package:heath_care/ui/components/item_conversation.dart';

import 'components/NavSideBar.dart';
import 'components/item_user_online.dart';

// ignore: must_be_immutable
class ListUser extends StatefulWidget {
  @override
  State<ListUser> createState() => _ListUserState();
}

class _ListUserState extends State<ListUser> {
  int _selectedIndex = 1;
  Future<User> _currentUser = UserRepository().getCurrentUser();
  Future<List<User>?> _userOnlines = UserRepository().getUserOnline();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(78, 159, 193, 1),
          title: Text('LIÊN HỆ HỖ TRỢ'),
        ),
        body: FutureBuilder<User>(
            future: _currentUser,
            builder: (context, currentUser) {
              if (currentUser.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<User>?>(
                        future: _userOnlines,
                        builder: (context, userOnlineSnapshot) {
                          if (userOnlineSnapshot.hasData) {
                            print(
                                'lenght onlines ${userOnlineSnapshot.data!.length}');
                            return SizedBox(
                              height: 100,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: userOnlineSnapshot.data!.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    if (index % 2 == 0) {
                                      userOnlineSnapshot.data![index].avatar =
                                          'https://toigingiuvedep.vn/wp-content/uploads/2021/01/anh-avatar-cho-con-gai-cuc-dep.jpg';
                                    }
                                    return ItemUserOnline(
                                        userOnlineSnapshot.data![index],
                                        currentUser.data!.username!);
                                  }),
                            );
                          } else {
                            return Container();
                          }
                        }),
                    StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .orderBy('updated_time', descending: true)
                            .where('participants', arrayContainsAny: [
                          currentUser.data!.username
                        ]).snapshots(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            List conversations =
                                snapshot.data!.docs.where((element) {
                              return (element['messages'] as List).isNotEmpty;
                            }).toList();
                            return Expanded(
                              child: ListView.builder(
                                  itemCount: conversations != null
                                      ? conversations.length
                                      : 0,
                                  shrinkWrap: true,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    var conversation = conversations[index];
                                    var userNameHim =
                                        (conversation['participants'] as List)
                                            .firstWhere((element) =>
                                                element !=
                                                currentUser.data!.username);
                                    var lastMessage =
                                        (conversation['messages'] as List).last;
                                    return ItemConversation(
                                        conversation,
                                        userNameHim.toString(),
                                        lastMessage['content'],
                                        lastMessage['created_time']);
                                  }),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                "Hãy bắt đầu cuộc hội thoại ngay để nhận được sự trợ giúp!",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }),
                  ],
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
        drawer: NavDrawer());
  }
}
