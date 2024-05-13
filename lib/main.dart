import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_callchat/screen/login_screen.dart';

void main() {

  if (WebRTC.platformIsAndroid) {
    initializeService();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginScreen(),
      // home: HomeScreen(name: "haidz",),
    );
  }
}


Future<void> initializeService() async {


  if (WebRTC.platformIsAndroid) {

    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "CodeWithBisky",
      notificationText: "Background notification for keeping the CodeWithBisky running in the background",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'), // Default is ic_launcher from folder mipmap
    );

    await FlutterBackground.initialize(androidConfig: androidConfig).then(
            (value) async {
          // value is false
          if (value) {
            bool enabled = await FlutterBackground.enableBackgroundExecution();
          }
          return value;
        }, onError: (e) {
      print('error>>>> $e');
    });
  }


  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
        onStart: (ServiceInstance instance){
        },
        // auto start service
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceNotificationId: 888),
        iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: (ServiceInstance instance){

      },

      // you have to enable background fetch capability on xcode project
      onBackground: (ServiceInstance instance){
        return false;
      },
    ),
  );

  service.startService();
}



