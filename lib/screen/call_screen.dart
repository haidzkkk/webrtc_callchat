
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_callchat/data/model/message.dart';
import 'package:webrtc_callchat/data/remote/socket_manager.dart';

import '../data/remote/signaling.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.message});

  final Message message;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late Signaling _signaling;
  SocketManager socketManager = SocketManager.getInstance();

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = true;
  bool _cameraOn = true;
  bool _switchCamera = true;
  bool isShareScreen = false;

  @override
  void initState(){
    super.initState();
    initScreen();
  }

  initScreen() async{

    _signaling = Signaling.getInstance();
    await _signaling.openUserMedia(_localRenderer, _remoteRenderer).then((value) {
      setState(() {});
    });

    _signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    _signaling.onIceCandidate = (RTCIceCandidate iceCandidate){
      _signaling.addIceCandidate(iceCandidate);
      Map<String, dynamic> myIceCandidate = {
        'sdpMid': iceCandidate.sdpMid,
        'sdpMLineIndex': iceCandidate.sdpMLineIndex,
        'candidate': iceCandidate.candidate,
      };
      Message messageIce = Message(
          name: widget.message.name,
          target: widget.message.target,
          type: Message.ICE_CANDIDATE,
          data: jsonEncode(myIceCandidate)
      );
      socketManager.sendData(json: messageIce.toJson());
    };

    socketManager.connect();
    socketManager.listenMessage(
        eventName: Message.CLIENT_EVENT + widget.message.name!,
        onListen: (Message message) async {
          print("socket message: ${message.toString()}");

          switch(message.type){
            case Message.OFFER_RECIEVED:{
              widget.message.target = message.target ?? "";
              Map<String, dynamic> descriptionMapRes = jsonDecode(message.data);
              RTCSessionDescription description = RTCSessionDescription(
                  descriptionMapRes['sdp'],
                  descriptionMapRes['type']
              );
              _signaling.setRemoteDescription(description);
              await Future.delayed(const Duration(milliseconds: 1000));

              Message messageAnswer = Message(name: widget.message.name, target: widget.message.target, type: Message.CREATE_ANSWER);
              Message messageCreateAnswer = await _signaling.createAnswer(messageAnswer);
              socketManager.sendData(json: messageCreateAnswer.toJson());

              break;
            }
            case Message.ANSWER_RECIEVED:{
              Map<String, dynamic> descriptionMapRes = jsonDecode(message.data);
              RTCSessionDescription description = RTCSessionDescription(
                  descriptionMapRes['sdp'],
                  descriptionMapRes['type']
              );
              _signaling.setRemoteDescription(description);

              break;
            }
            case Message.ICE_CANDIDATE:{
              Map<String, dynamic> myIceCandidateRes = jsonDecode(message.data);
              RTCIceCandidate myIceCandidate = RTCIceCandidate(
                myIceCandidateRes['candidate'],
                myIceCandidateRes['sdpMid'],
                myIceCandidateRes['sdpMLineIndex'],);
              _signaling.addIceCandidate(myIceCandidate);

              break;
            }
          }
        });

    // offer
    if(widget.message.target != null && widget.message.target?.isNotEmpty == true){
      _signaling.createOffer(widget.message).then((value) {
        socketManager.sendData(json: value.toJson());
      });
    }
  }

  @override
  void dispose() {
    _signaling.close(_localRenderer, _remoteRenderer);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            onTap: (){
              _signaling.openUserMedia(_localRenderer, _remoteRenderer).then((value) {
                setState(() {});
              });
            },
            child: const Text("Call")),
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                placeholderBuilder: (context){
                  return Container(
                      color: Colors.white,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      )
                  );
                },
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              width: 100,
              height: 150,
              child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  placeholderBuilder: (context){
                    return Container(
                        color: Colors.white,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        )
                    );
                  },
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                  IconButton(
                    onPressed: () {
                      _cameraOn = !_cameraOn;
                      _signaling.turnCamera(_localRenderer, _cameraOn).then((value){
                        setState(() {});
                      });
                    },
                    icon: Icon(_cameraOn ? Icons.camera_alt_outlined : Icons.folder_off_outlined, color: Colors.pink),
                  ),
                  IconButton(
                    onPressed: () {
                      _isMuted = !_isMuted;
                      _signaling.muteMic(_isMuted);
                      setState(() {});
                    },
                    icon: Icon(_isMuted ? Icons.mic_none : Icons.mic_off_outlined, color: Colors.pink),
                  ),
                  IconButton(
                    onPressed: () {
                      _signaling.switchCamera();
                    },
                    icon: const Icon(Icons.swap_horizontal_circle_outlined, color: Colors.pink),
                  ),
                  IconButton(
                    onPressed: () {
                      selectScreenSourceDialog(context);
                    },
                    icon: Icon(Icons.screen_lock_portrait, color: isShareScreen ? Colors.lightBlue : Colors.pink),
                  ),
                  IconButton(
                    onPressed: () {
                    },
                    icon: const Icon(Icons.call_end, size: 30, color: Colors.redAccent),
                  ),
              ],
            )
          )
        ],
      ),
    );
  }

  Future<void> selectScreenSourceDialog(BuildContext context) async {
    if (WebRTC.platformIsAndroid) {
      // Android specific
      Future<void> requestBackgroundPermission([bool isRetry = false]) async {
        // Required for android screenshare.
        try {
          var hasPermissions = await FlutterBackground.hasPermissions;
          if (!isRetry) {
            const androidConfig = FlutterBackgroundAndroidConfig(
              notificationTitle: 'Screen Sharing',
              notificationText: 'LiveKit Example is sharing the screen.',
              notificationImportance: AndroidNotificationImportance.Default,
              notificationIcon: AndroidResource(
                  name: 'livekit_ic_launcher', defType: 'mipmap'),
            );
            hasPermissions = await FlutterBackground.initialize(
                androidConfig: androidConfig);
          }
          if (hasPermissions &&
              !FlutterBackground.isBackgroundExecutionEnabled) {
            await FlutterBackground.enableBackgroundExecution();
          }
        } catch (e) {
          if (!isRetry) {
            return await Future<void>.delayed(const Duration(seconds: 1),
                    () => requestBackgroundPermission(true));
          }
          print('could not publish video: $e');
        }
      }

      await requestBackgroundPermission();
    }

    makeCall();
  }

  void makeCall() {
    isShareScreen = !isShareScreen;
    _signaling.switchToScreenSharing(_localRenderer, isShareScreen, _cameraOn).then((value) {
      setState(() {});
    });
  }

}




