import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/model/message.dart';
import '../data/remote/signaling.dart';
import '../data/remote/socket_manager.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.name});

  final String name;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SocketManager socketManager = SocketManager.getInstance();
  TextEditingController myNameTextController = TextEditingController();
  TextEditingController callNameTextController = TextEditingController();

  String target = "";
  bool isOffer = false;

  bool isCall = false;

  late Signaling _signaling;

  @override
  void initState(){
    super.initState();
    _signaling = Signaling.getInstance();

    socketManager.connect();
    socketManager.listenMessage(
        eventName: Message.CLIENT_EVENT + widget.name,
        onListen: (Message message) async {
          print("socket message: ${message.toString()}");

          switch(message.type){
            case Message.CALL_RESPONSE: {
              if(message.data == Message.OK){

                target = callNameTextController.text;
                Message messageOffer = Message(name: widget.name, target: target, type: Message.CREATE_OFFER);

                Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CallScreen(message: messageOffer)));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Nó không tồn tại")));
              }
              break;
            }
          }
        });
  }

  @override
  void dispose() {
    super.dispose();
    myNameTextController.dispose();
    callNameTextController.dispose();
    socketManager.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.name),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 100,),
                TextFormField(
                  controller: callNameTextController,
                  decoration: InputDecoration(
                    labelText: "Tên muốn gọi",
                    suffixIcon: IconButton(
                      onPressed: () async{
                        await _signaling.createPeerConnectionData();
                        String targetName = callNameTextController.text;
                        Message messageCall = Message(name: widget.name, target: targetName, type: Message.START_CALL);
                        if(targetName.isNotEmpty){
                          socketManager.sendData(json: messageCall.toJson());
                        }else{
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CallScreen(message: messageCall)));
                        }
                      },
                      icon: const Icon(Icons.call, size: 30,),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  resetTargetData(){
    target = "";
    isOffer = false;
    setState(() {});
  }
}
