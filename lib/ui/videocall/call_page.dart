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
import 'package:heath_care/utils/dialog_util.dart';
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
  String? _roomId;
  bool _isCalling = false;
  bool _isMute = false;
  String _timmer = '';
  Timer? _timmerInstance;
  Timer? _timmer_timeOutInstance;
  int _start = 0;
  bool _isFrontCamera = true;
  bool _isReady = false;
  int _timeOut = 45;
  bool _isSpeakerPhone = true;
  bool _isDisConnected = false;
  bool _enableCamera = true;
  bool _remoteEnableCamera = true;
  bool _completed = false;

  final assetsAudioPlayer = AssetsAudioPlayer();

  playLocal() async {
    try {
      assetsAudioPlayer
          .open(
        Audio('assets/audio/beep.wav'),
        loopMode: LoopMode.none,
      )
          .then((value) {
        assetsAudioPlayer.stop();
      });
    } catch (t) {
      //stream unreachable
    }
  }

  void start_timeOut() {
    var oneSec = Duration(seconds: 1);
    _timmer_timeOutInstance = Timer.periodic(oneSec, (Timer timer) {
      if (timer.tick >= _timeOut) {
        if (!_isReady && !_completed) {
          _makeCallCompleted();
          _sendMessage(widget.currentName, "Không thể thực hiện cuộc gọi!");
        }
        _timmer_timeOutInstance?.cancel();
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

  _sendMessage(String? userName, String content) {
    widget.reference.get().then((value) {
      Message message =
          Message(userName ?? value['from'], content, Timestamp.now());
      ChatFireBase.getInstance()
          .sendMessageWithId(message, value.get('chat_id'));
    });
  }

  _updateEnableCamera(bool isEnable) {
    widget.reference.get().then((value) {
      if (widget.currentName == value.get('from')) {
        widget.reference.update({
          'camera_from': isEnable,
        });
      } else {
        widget.reference.update({
          'camera_to': isEnable,
        });
      }
    });
  }

  _makeCallCompleted() {
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
      'room_id': _roomId,
    });
  }

  hangUp({bool pop = true}) {
    if (pop) {
      Navigator.pop(context);
    }
    playLocal();
    signaling.hangUp(_localRenderer);
    _timmerInstance?.cancel();
    widget.onHangUp();
  }

  initListener() {
     widget.reference.snapshots().listen((event) {
      try {
        if (widget.currentName == event.get('from') &&
            event.get('camera_to') != null) {
          final to = event.get('camera_to');
          setState(() {
            _remoteEnableCamera = to;
            print('set cam to ${_remoteEnableCamera}');
          });
        } else if (widget.currentName != event.get('from') &&
            event.get('camera_from') != null) {
          final from = event.get('camera_from');
          setState(() {
            _remoteEnableCamera = from;
            print('set cam from ${_remoteEnableCamera}');
          });
        }
      } catch (e) {
        print(e);
      }

      if ((event.get('completed') == false &&
          event.get('incoming_call') == false)) {
        setState(() {
          _isReady = true;
        });
      }
      if (event.get('completed') == true && !_isDisConnected) {
        _completed = true;
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
        !_isCalling) {
      await signaling.openUserMedia(
          widget.isVoiceCall, _localRenderer, _remoteRenderer);
      if (widget.createRoom) {
        _roomId = await signaling.createRoom(_remoteRenderer);
        updateRoom();
      } else {
        final snapshot = await widget.reference.get();
        String idJoin = snapshot['room_id'];
        signaling.joinRoom(
          idJoin,
          _remoteRenderer,
        );
      }
      _isCalling = true;
      setState(() {});
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Thoát cuộc gọi?'),
            content: new Text('Kết thúc cuộc gọi'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: new Text('Tiếp tục gọi'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendMessage(null, "Kết thúc cuộc gọi");
                  _makeCallCompleted();
                },
                child: new Text('Thoát'),
              ),
            ],
          ),
        )) ??
        false;
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
    signaling.onConnectedFail = () async {
      setState(() {
        _isDisConnected = true;
      });
      _makeCallCompleted();
      await showErrorDialog(
          context, "Mất kết nối", "Vui lòng kiểm tra lại kết nối internet");
      hangUp();
    };
    initPermission();
    initListener();
    start_timeOut();
    super.initState();
  }

  @override
  void dispose() {
    _timmer_timeOutInstance?.cancel();
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
    return WillPopScope(
      onWillPop: () async {
        final result = await _onWillPop();
        return result;
      },
      child: Scaffold(
        body: Container(
          color: Colors.black87,
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [
              Visibility(
                visible: _isReady && !widget.isVoiceCall,
                child: buildMainRender(_remoteRenderer, size),
              ),
              if (widget.isVoiceCall)
                buildVoiceCall()
              else if (_isReady)
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
                        _isMute ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                        size: size.width * .06,
                      ),
                      size.width * .12,
                      size.width * .12,
                      () => setState(() {
                            _isMute = !_isMute;
                            signaling.muteAudio(_isMute);
                          })),
                  SizedBox(
                    width: 16,
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
                      _sendMessage(null, "Kết thúc cuộc gọi");
                    }
                  }, backgroundColor: Colors.red.withOpacity(0.6)),
                  SizedBox(
                    width: 16,
                  ),
                  buildIconButtonWidget(
                      Icon(
                        _isSpeakerPhone
                            ? CupertinoIcons.speaker_1_fill
                            : CupertinoIcons.speaker_1,
                        color: Colors.white,
                        size: size.width * .06,
                      ),
                      size.width * .12,
                      size.width * .12,
                      () => setState(() {
                            _isSpeakerPhone = !_isSpeakerPhone;
                            signaling.enableSpeaker(_isSpeakerPhone);
                          })),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector buildIconButtonWidget(
      Widget icon, double height, double width, Function onTap,
      {Color? backgroundColor}) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.grey.withOpacity(0.6),
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
              color: !_isReady ? Colors.transparent : Colors.green,
              fontSize: size.width / 26.5,
            ),
          ),
          Text(
            _isReady && _timmer.isNotEmpty ? "Đang gọi..." : "Đang kết nối...",
            style: TextStyle(
                fontSize: 20,
                color: _isReady && _timmer.isNotEmpty
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold),
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
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(6.0)),
              border: Border.all(color: Colors.blueAccent, width: 2.0),
            ),
            child: _localRenderer.textureId == null
                ? Container()
                : SizedBox(
                    width: size.height,
                    height: size.height,
                    child: !_enableCamera
                        ? Center(child: Text("Camera off"))
                        : Transform(
                            transform: Matrix4.identity()
                              ..rotateY(
                                _isFrontCamera ? -pi : 0.0,
                              ),
                            alignment: FractionalOffset.center,
                            child: Texture(
                                textureId: _localRenderer.textureId ?? 1),
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
                    _enableCamera ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                    size: size.width * .06,
                  ),
                  size.width * .12,
                  size.width * .12, () {
                setState(() {
                  _enableCamera = !_enableCamera;
                  _updateEnableCamera(_enableCamera);
                  signaling.enableCamera(_enableCamera);
                });
              }),
              SizedBox(
                width: 12,
              ),
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
    print(
        'rebuild main ${!_remoteEnableCamera } ${render.textureId} ');
    return Container(
      width: size.width,
      height: size.height,
      child: render.textureId == null
          ? Container()
          : !_remoteEnableCamera
              ? Center(
                  child: Text('Camera Off'),
                )
              : FittedBox(
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
                            visible: !_isReady, child: Text("Đang kết nối...")),
                      ],
                    ),
                  ),
                ),
    );
  }
}
