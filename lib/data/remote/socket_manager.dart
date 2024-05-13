
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:webrtc_callchat/data/model/message.dart';

class SocketManager{
  static SocketManager? socketManager;
  static SocketManager getInstance(){
    socketManager ??= SocketManager();
    return socketManager!;
  }

  SocketManager(){
    _socket = IO.io("http://192.168.21.252:3001", <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    _socket.onConnect((data){
      print("on socket connect");
    });
  }

  late IO.Socket _socket;
  IO.Socket get socket => _socket;

  void connect(){
    _socket.connect();
  }

  void disconnect(){
    _socket.disconnect();
  }

  void close(){
    _socket.disconnect();
    _socket.close();
    // _socket.off(event)
    _socket.dispose();
  }

  void off({required String eventName}){
    _socket.off(eventName);
  }

  listenMessage({required String eventName, required Function(Message) onListen}) {
    _socket.on(eventName, (json) {
       Message data = Message.fromJson(json);
       onListen(data);
    });
  }

  void sendData({String? eventName, required String json}){
    print("${_socket.connected} ${_socket.hashCode} emit: $json");
    _socket.emit(eventName ?? Message.SERVER_EVENT, json);
  }

  Stream<T> listenDataSocket<T>({required String eventName, required T fromJson(data)}) async*{
    _socket.on(eventName, (json) async*{
    T data = fromJson(json);
    yield data;
    });
  }
}