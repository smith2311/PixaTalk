import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/api/apis.dart';
import 'package:frontend/helper/dialogs.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool _isAnimate=false;

  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(milliseconds: 500),(){
      setState(() {
        _isAnimate=true;
      });
    });
  }

  _handleGoogleBtnClick(){
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);

      if(user!=null){
        log('\n User: ${user.user}');
        log('\n User: ${user.additionalUserInfo}');

        if((await APIs.userExist())){
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
        else{
          APIs.createUser().then((value){
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
    });
  }
    Future<UserCredential?> _signInWithGoogle() async {
   try{
     await InternetAddress.lookup('google.com');
     // Trigger the authentication flow
     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

     // Obtain the auth details from the request
     final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

     // Create a new credential
     final credential = GoogleAuthProvider.credential(
       accessToken: googleAuth?.accessToken,
       idToken: googleAuth?.idToken,
     );

     // Once signed in, return the UserCredential
     return await APIs.auth.signInWithCredential(credential);
   }
   catch(e){
     log('\n _signInWithGoogle : $e');
     Dialogs.showSnackBar(context, 'Something went wrong! Please check your Internet Connection');
     return null;
   }
  }
  // _signOut() async{
  //   await FirebaseAuth.instance.signOut();
  //   await GoogleSignIn().signOut();
  // }
  @override
  Widget build(BuildContext context) {
    mq= MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to PixaTalk'),
        //Talk. Imagine. Create. Welcome to PixaTalk
      ),
      body: Stack(children: [

        AnimatedPositioned(
            top: mq.height * 0.15,
            right: _isAnimate? mq.width * 0.1 : mq.width * .5,
            width: mq.width * 0.8,
            duration: const Duration(milliseconds: 1500),
            height: mq.height * 0.3,
            child: Image.asset('assets/logo_1.png')),

        Positioned(
            top: mq.height * .50,
            left: mq.width * .1,
            width: mq.width * .8,
            height: mq.height * .06,

          child: ElevatedButton.icon(onPressed: (){
            _handleGoogleBtnClick();
            },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen,
                shape: StadiumBorder(),elevation: 1),
                icon: Image.asset('assets/google.png',height: mq.height*.04,),
                label:RichText(text:
                const TextSpan(
                    style: TextStyle(color: Colors.black,fontSize: 19,fontWeight: FontWeight.bold),
                    children: [
                  TextSpan(text: "Login with " ),
                  TextSpan(text: "Google"),
                ]))),),
    ]),
    );
  }
}
