import 'dart:async';

import 'package:heath_care/model/user.dart';
import 'package:stomp_dart_client/stomp.dart';

import 'model/message.dart';

User? _currentUser;

User? getCurrentUserTmp(){
  return _currentUser;
}

void setCurrentUser(User user){
  _currentUser = user;
}

Map<String, StompClient> rooms = {};
Map<String, List<Message>> messages = {};
Map<String, StreamController<List<Message>>> streams = {};