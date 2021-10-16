import 'dart:async';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:heath_care/firebase/chat_firebase.dart';
import 'package:heath_care/model/message.dart';
import 'package:heath_care/utils/signaling.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPage extends StatefulWidget {
  bool createRoom;
  DocumentReference reference;
  Function onHangUp;
  String? currentName;
  bool isVoiceCall;

  CallPage(this.isVoiceCall, this.createRoom, this.reference, this.currentName,
      this.onHangUp);

  @override
  State<StatefulWidget> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  bool isCalling = false;
  bool isMute = false;
  String _timmer = '';
  Timer? _timmerInstance;
  Timer? _timmerTimeOutInstance;
  int _start = 0;
  bool isFrontCamera = true;
  bool isReady = false;
  int timeOut = 60;
  bool isSpeakerPhone = false;

  final assetsAudioPlayer = AssetsAudioPlayer();

  playLocal() async {
    try {
      await assetsAudioPlayer.open(
        Audio('assets/audio/beep.wav'),
        loopMode: LoopMode.none,
      );
      await Future.delayed(Duration(seconds: 2));
      assetsAudioPlayer.stop();
    } catch (t) {
      //stream unreachable
    }
  }

  void startTimeOut() {
    var oneSec = Duration(seconds: 1);
    _timmerTimeOutInstance = Timer.periodic(oneSec, (Timer timer) {
      if (timer.tick >= timeOut) {
        if (!isReady) {
          _makeCallCompleted();
          _sendMessage("Không thể thực hiện cuộc gọi!");
        }
        _timmerTimeOutInstance?.cancel();
      }
    });
  }

  void startTimmer() {
    var oneSec = Duration(seconds: 1);
    _timmerInstance = Timer.periodic(
        oneSec,
        (Timer timer) => setState(() {
              if (_start < 0) {
                _timmerInstance?.cancel();
              } else {
                _start = _start + 1;
                _timmer = getTimerTime(_start);
              }
            }));
  }

  _sendMessage(String content) {
    widget.reference.get().then((value) {
      Message message = Message(
          widget.currentName == null ? value.get('from') : widget.currentName,
          content,
          Timestamp.now());
      ChatFireBase.getInstance()
          .sendMessageWithId(message, value.get('chat_id'));
    });
  }

  _makeCallCompleted() async {
    await playLocal();
    widget.reference.update({
      'completed': true,
    });
  }

  String getTimerTime(int start) {
    int minutes = (start ~/ 60);
    String sMinute = '';
    if (minutes.toString().length == 1) {
      sMinute = '0' + minutes.toString();
    } else
      sMinute = minutes.toString();

    int seconds = (start % 60);
    String sSeconds = '';
    if (seconds.toString().length == 1) {
      sSeconds = '0' + seconds.toString();
    } else
      sSeconds = seconds.toString();

    return sMinute + ':' + sSeconds;
  }

  void updateRoom() {
    widget.reference.update({
      'room_id': roomId,
    });
  }

  hangUp() {
    Navigator.pop(context);
    widget.onHangUp();
    _timmerInstance?.cancel();
    signaling.hangUp(_localRenderer);
  }

  initListener() {
    widget.reference.snapshots().listen((event) {
      if ((event.get('completed') == false &&
          event.get('incoming_call') == false)) {
        setState(() {
          isReady = true;
        });
      }
      if (event.get('completed') == true) {
        hangUp();
      }
    });
  }

  initPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted &&
        !isCalling) {
      await signaling.openUserMedia(
          widget.isVoiceCall, _localRenderer, _remoteRenderer);
      if (widget.createRoom) {
        roomId = await signaling.createRoom(_remoteRenderer);
        updateRoom();
      } else {
        final snapshot = await widget.reference.get();
        String idJoin = snapshot['room_id'];
        signaling.joinRoom(
          idJoin,
          _remoteRenderer,
        );
      }
      isCalling = true;
      setState(() {});
    }
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
      startTimmer();
    });
    initPermission();
    initListener();
    startTimeOut();
    super.initState();
  }

  @override
  void dispose() {
    _timmerTimeOutInstance?.cancel();
    _timmerInstance?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    assetsAudioPlayer.stop();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: Colors.black87,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Visibility(
              visible: isReady && !widget.isVoiceCall,
              child: buildMainRender(_remoteRenderer, size),
            ),
            if (widget.isVoiceCall)
              buildVoiceCall()
            else if (isReady)
              buildLocalRender(size)
            else
              buildMainRender(_localRenderer, size),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                buildIconButtonWidget(
                    Icon(
                      isMute ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: size.width * .06,
                    ),
                    size.width * .12,
                    size.width * .12,
                    () => setState(() {
                          isMute = !isMute;
                          signaling.muteAudio(isMute);
                        })),
                SizedBox(
                  width: 12,
                ),
                buildIconButtonWidget(
                    Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: size.width / 12.0,
                    ),
                    size.width * .18,
                    size.width * .18, () {
                  {
                    _makeCallCompleted();
                    _sendMessage("Kết thúc cuộc gọi");
                  }
                }),
                SizedBox(
                  width: 12,
                ),
                buildIconButtonWidget(
                    Icon(
                      isSpeakerPhone
                          ? CupertinoIcons.speaker_1_fill
                          : CupertinoIcons.speaker_1,
                      color: Colors.white,
                      size: size.width * .06,
                    ),
                    size.width * .12,
                    size.width * .12,
                    () => setState(() {
                          isSpeakerPhone = !isSpeakerPhone;
                          signaling.enableSpeaker(isSpeakerPhone);
                        })),
              ],
            )
          ],
        ),
      ),
    );
  }

  GestureDetector buildIconButtonWidget(
      Icon icon, double height, double width, Function onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.6),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }

  Widget buildVoiceCall() {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _timmer,
            style: TextStyle(
              color: !isReady ? Colors.transparent : Colors.green,
              fontSize: size.width / 26.5,
            ),
          ),
          Text(
            isReady && _timmer.isNotEmpty ? "Đang gọi..." : "Đang kết nối...",
            style: TextStyle(
                fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Positioned buildLocalRender(Size size) {
    return Positioned(
      top: 40.0,
      right: 16.0,
      child: Column(
        children: [
          Text(
            _timmer,
            style: TextStyle(
              color: _localRenderer.textureId == null
                  ? Colors.transparent
                  : Colors.green,
              fontSize: size.width / 26.5,
            ),
          ),
          SizedBox(
            height: 8.0,
          ),
          Container(
            height: size.width * .5,
            width: size.width * .3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(6.0)),
              border: Border.all(color: Colors.blueAccent, width: 2.0),
            ),
            child: _localRenderer.textureId == null
                ? Container()
                : SizedBox(
                    width: size.height,
                    height: size.height,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..rotateY(
                          isFrontCamera ? -pi : 0.0,
                        ),
                      alignment: FractionalOffset.center,
                      child: Texture(textureId: _localRenderer.textureId ?? 1),
                    ),
                  ),
          ),
          SizedBox(
            height: 8,
          ),
          Row(
            children: [
              buildIconButtonWidget(
                  Icon(
                    Icons.switch_camera,
                    color: Colors.white,
                    size: size.width * .06,
                  ),
                  size.width * .12,
                  size.width * .12, () {
                signaling.switchCamera();
              })
            ],
          )
        ],
      ),
    );
  }

  Container buildMainRender(RTCVideoRenderer render, Size size) {
    return Container(
      width: size.width,
      height: size.height,
      child: render.textureId == null
          ? Container()
          : OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: Center(
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      SizedBox(
                        width: size.width,
                        height: size.height,
                        child: Transform(
                          transform: Matrix4.identity()..rotateY(0.0),
                          alignment: FractionalOffset.center,
                          child: Texture(textureId: render.textureId!),
                        ),
                      ),
                      Visibility(
                          visible: !isReady, child: Text("Đang kết nối...")),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
