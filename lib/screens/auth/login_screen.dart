import 'dart:io';
import 'dart:developer';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../api/apis.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _LoginScreenState();

  const LoginScreen({super.key});
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(microseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  _handleGoogleBtnClick() {
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);
      if(user != null) {
        log('\nUser: ${user.user}');
        log("\nUserAdditionalInfo: ${user.additionalUserInfo}");

        if(await APIs.userExists()) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()
              )
          );
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()
                )
            );
          });
        }


      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
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
      return await APIs.auth.signInWithCredential(credential);}
    catch(e) {
      print('\n_signInWithGoogle: $e');
      Dialogs.showSnackbar(context, 'Something Went Wrong (Check Internet!)');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome to Sabo Chat"),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
            top: mq.height * .15,
            width: mq.width * .5,
            right: _isAnimate ?  mq.width * .25 : -mq.width * .5,
            duration: Duration(seconds: 1),
            child: Image.asset('images/icon.png'),
          ),
          Positioned(
            bottom: mq.height * .15,
            width: mq.width * .9,
            left: mq.width * .05,
            height: mq.height * .06,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen.shade300,
                shape: StadiumBorder(),
                elevation: 1
              ),
                onPressed: () {
                  _handleGoogleBtnClick();
                },
                icon: Image.asset('images/google.png'),
                label: RichText(text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: "Login with "),
                    TextSpan(text: "Google", style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ))
            ),
          ),
        ],
      ),
    );
  }

}