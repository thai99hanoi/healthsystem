import 'dart:async';

import 'package:heath_care/model/user.dart';

import 'model/message.dart';

User? _currentUser;

User? getCurrentUserTmp(){
  return _currentUser;
}

void setCurrentUser(User user){
  _currentUser = user;
}

Map<String, List<Message>> messages = {};
Map<String, StreamController<List<Message>>> streams = {};