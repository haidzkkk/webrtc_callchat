
import 'dart:convert';

class Message{
  static const String SERVER_EVENT = "message";
  static const String CLIENT_EVENT = "client-";

  static const String ADD_USER = "store_user";
  static const String START_CALL = "start_call";
  static const String CREATE_OFFER = "create_offer";
  static const String CREATE_ANSWER = "create_answer";
  static const String ICE_CANDIDATE = "ice_candidate";

  static const String CALL_RESPONSE = "call_response";
  static const String OFFER_RECIEVED = "offer_received";
  static const String ANSWER_RECIEVED = "answer_received";

  static const String LOGIN_DONE = "done";
  static const String OK = "ok";

  String? name;
  String? target;
  String? type;
  dynamic data;

  Message({
    this.name,
    this.target,
    this.type,
    this.data,
  });

  Message.fromJson(String json){
    Map<String, dynamic> mapJson = jsonDecode(json);
    name = mapJson['name'];
    target = mapJson['target'];
    type = mapJson['type'];
    data = mapJson['data'];
  }

  String toJson(){
    Map<String, dynamic> mapJson = {
    "name" : name,
    "target": target,
    "type" : type,
    "data" : data
    };
    String json = jsonEncode(mapJson);
    return json;
  }

  @override
  String toString() {
    return "$name - $target - $type - $data";
  }
}