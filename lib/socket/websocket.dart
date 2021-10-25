// import 'dart:async';
// import 'dart:convert';
//
// import 'package:heath_care/model/message.dart';
// import 'package:heath_care/networks/auth.dart';
// import 'package:stomp_dart_client/stomp.dart';
// import 'package:stomp_dart_client/stomp_config.dart';
// import 'package:stomp_dart_client/stomp_frame.dart';
//
// import '../application.dart';
//
// class ChatService {
//   String? userName;
//
//   String roomId; // change it's value to join roomChat
//
//   StompClient? stompClient;
//
//
//   Stream<List<Message>>? get chatStream {
//    return streams[roomId]?.stream;
//   }
//
//   ChatService(this.userName, {this.roomId = '1'}) {
//     streams[roomId] =
//     new StreamController<List<Message>>();
//     initChat();
//   }
//
//   void onMessageReceive(StompFrame frame) {
//     var message = json.decode(frame.body);
//     print('response' + message.toString());
//     if (message['type'] == 'JOIN') {
//       message['content'] = message['sender'] + ' joined';
//     } else if (message['type'] == 'LEAVE') {
//       message['content'] = message['sender'] + ' left!';
//     }
//     Message currentMessage = Message(message['sender'], message['content']);
//
//     var _currentMessages = messages[roomId];
//     if (_currentMessages == null) {
//       _currentMessages = [];
//       messages[roomId] = _currentMessages;
//     }
//     messages[roomId]?.add(currentMessage);
//     print('messages:' + messages[roomId].toString());
//     List<Message>? datas = messages[roomId];
//     if (datas != null) {
//       streams[roomId]?.sink.add(datas);
//     }
//   }
//
//   void onConnect(StompClient client, StompFrame frame, String userName,
//       Function(StompFrame) onMessageReceive) {
//     print('onConnect');
//     client.subscribe(
//         destination: '/channel/$roomId', callback: onMessageReceive);
//
//     client.send(
//         destination: '/app/chat/$roomId/addUser',
//         body: json.encode({'sender': userName, 'type': 'JOIN'}));
//   }
//
//   Future<void> initChat() async {
//     print('activeChat');
//     print('userName:' + userName.toString());
//     token.then((value) async {
//       print('token:' + value.toString());
//       print('rooms:' + rooms.toString());
//       StompClient? stompClientTmp = rooms[roomId];
//       print('stomp null ko?:' + stompClientTmp.toString());
//       if (stompClientTmp != null) {
//         print('stomp ko null roi');
//         stompClient = stompClientTmp;
//         List<Message>? datas = messages[roomId];
//         if (datas != null) {
//           streams[roomId]?.sink.add(datas);
//         }
//       } else {
//         print('stomp null roi');
//         stompClient = StompClient(
//             config: StompConfig(
//                 url: 'ws://192.168.43.223:8080/ws',
//                 onConnect: (client, frame) {
//                   print('connect roi');
//                   onConnect(client, frame, userName!, onMessageReceive);
//                 },
//                 connectionTimeout: Duration(seconds: 5),
//                 onWebSocketError: (error) =>
//                     print("error active socket}" + error.toString()),
//                 onStompError: (d) => print('error stomp ${d.toString()}'),
//                 onDisconnect: (f) => print('disconnected ${f.toString()}'),
//                 onDebugMessage: (mess) => print("debug ${mess}"),
//                 stompConnectHeaders: {'Authorization': 'Bearer $value'},
//                 webSocketConnectHeaders: {'Authorization': 'Bearer $value'}));
//         rooms[roomId] = stompClient!;
//         await Future.delayed(Duration(seconds: 1));
//         stompClient?.activate();
//       }
//     });
//   }
//
//   void sendMessage(String message) {
//     if (stompClient != null) {
//       stompClient?.send(
//           destination: '/app/chat/$roomId/sendMessage',
//           body: json.encode(
//               {'sender': userName, 'type': 'CHAT', 'content': message}));
//     }
//   }
// }
//
// Future<String> getToken() async {
//   String token = await Auth().getToken();
//   return token;
// }
//
// var token = getToken();
