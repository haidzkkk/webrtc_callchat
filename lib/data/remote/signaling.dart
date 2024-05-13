import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_callchat/data/model/message.dart';

typedef void StreamStateCallback(MediaStream stream);
typedef void ICECandidateCallback(RTCIceCandidate iceCandidate);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      },
      {
        'url': 'turn:123.45.67.89:3478',
        'username': 'change_to_real_user',
        'credential': 'change_to_real_secret'
      },
    ]
  };

  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  static Signaling? mySingletonSignaling;
  static getInstance(){
    mySingletonSignaling ??= Signaling();
    return mySingletonSignaling;
  }

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  ICECandidateCallback? onIceCandidate;

  createPeerConnectionData() async {
    if(peerConnection == null){
      peerConnection = await createPeerConnection(configuration, offerSdpConstraints);
      await registerPeerConnectionListeners();
    }
 }

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo,
      ) async {
    await localVideo.initialize();
    await remoteVideo.initialize();

    localStream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});

    localVideo.srcObject = localStream;
    remoteVideo.srcObject = await createLocalMediaStream('key');

    localStream!.getTracks().forEach((track) async{
      peerConnection!.addTrack(track, localStream!);
    });

  }

  Future<Message> createOffer(Message message) async {
    RTCSessionDescription offer = await peerConnection!.createOffer();
    setLocalDescription(offer);

    message.data = jsonEncode(offer.toMap());
    return message;
  }

  Future<Message> createAnswer(Message message) async {
    RTCSessionDescription answer = await peerConnection!.createAnswer();
    setLocalDescription(answer);

    message.data = jsonEncode(answer.toMap());
    return message;
  }

  Future<void> setLocalDescription(RTCSessionDescription description) async {
    print("Addádsad local sdp");
    await peerConnection!.setLocalDescription(description);
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    print("Addádsad remote sdp");
    await peerConnection!.setRemoteDescription(description);
  }

  Future<void> addIceCandidate(RTCIceCandidate iceCandidate) async{
    print("Addádsad IceCandidate ${iceCandidate.toMap()}");
    peerConnection!.addCandidate(iceCandidate);
  }

  Future<void> close(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    localVideo.srcObject?.getTracks().forEach((track) => track.stop());
    localVideo.srcObject = null;
    remoteVideo.srcObject?.getTracks().forEach((track) => track.stop());
    remoteVideo.srcObject = null;

    localStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.getTracks().forEach((track) => track.stop());

    peerConnection?.close();
    peerConnection = null;
    localStream?.dispose();
    localStream = null;
    remoteStream?.dispose();
  }


  Future<void> registerPeerConnectionListeners() async{
    peerConnection?.onConnectionState = (RTCPeerConnectionState state){
      print("statehhihi: $state");
    };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      remoteStream = stream;
      if(onAddRemoteStream != null)
        onAddRemoteStream!(stream);
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if(onIceCandidate != null)
        onIceCandidate!(candidate);
    };
  }

  Future<void> switchCamera() async{
    if (localStream != null) {
      Helper.switchCamera(localStream!.getVideoTracks()[0]);
    }
  }

  Future<void> muteMic(bool mute) async{
    if (localStream != null) {
      localStream!.getAudioTracks().forEach((track) {
        track.enabled = mute;
      });
    }
  }

  Future<void> turnCamera(RTCVideoRenderer localVideo, bool isCamera) async{
    localStream!.getVideoTracks().forEach((track) {
      track.enabled = isCamera;
    });

  }

  Future<void> switchToScreenSharing(RTCVideoRenderer localVideo, bool isShareScreen, bool isCamera) async {

    if (isShareScreen) {
      if (WebRTC.platformIsAndroid) {
        localStream = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': true});
      }else{
        localStream = await navigator.mediaDevices.getDisplayMedia({'video': {'deviceId': 'broadcast'}, 'audio': true});
      }
    }else{
      localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    }

    peerConnection?.senders.then((senders) async{
      for (var sender in senders) {
        if (sender.track!.kind == 'video') {
          await sender.replaceTrack(localStream!.getVideoTracks()[0]);
        }
      }});
    localStream!.getVideoTracks().forEach((track) {
      track.enabled = isCamera;
    });
    localVideo.srcObject = localStream;
  }
}

