
import 'package:flutter/material.dart';
import 'package:webrtc_callchat/screen/home_creen.dart';

import '../data/model/message.dart';
import '../data/remote/socket_manager.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  SocketManager socketManager = SocketManager.getInstance();

  TextEditingController myNameTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    socketManager.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Call chat"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: TextFormField(
              controller: myNameTextController,
              decoration: InputDecoration(
                labelText: "Tên của bạn",
                suffixIcon: IconButton(
                  onPressed: (){
                    String name = myNameTextController.text;
                    Message data = Message(
                        name: name,
                        type: Message.ADD_USER
                    );
                    socketManager.sendData(json: data.toJson());

                    socketManager.listenMessage(
                        eventName: Message.CLIENT_EVENT + name,
                        onListen: (Message message) {
                          if(message.type == Message.LOGIN_DONE){
                            socketManager.off(eventName: Message.CLIENT_EVENT + name);
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeScreen(name: name)));
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi")));
                          }
                        });
                  },
                  icon: const Icon(Icons.send),
                ),
              ),
            ),
          ),
        )
    );
  }
}
