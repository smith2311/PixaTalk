import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/api/apis.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/home_screen.dart';

import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(seconds: 3),(){

      //Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,statusBarColor: Colors.white));

      if(APIs.auth.currentUser != null) {
        log('\n User: ${APIs.auth.currentUser}');
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
      else{
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }

    });
  }
  @override
  Widget build(BuildContext context) {
    mq= MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to PixaTalk'),
      ),
      body: Stack(children: [

        AnimatedPositioned(
            top: mq.height * 0.15,
            right: mq.width * 0.1,
            width: mq.width * 0.8,
            duration: const Duration(milliseconds: 1500),
            height: mq.height * 0.3,
            child: Image.asset('assets/logo_1.png')),

        Positioned(
          bottom: mq.height * .20,
          width: mq.width,
          child: Text('Talk 😆. Imagine 🤔. Create 🖌️.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15,
                color: Colors.black87,
            letterSpacing: 2),
          )),
      ]),
    );
  }
}
