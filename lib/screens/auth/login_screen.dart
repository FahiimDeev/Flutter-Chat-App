import 'dart:io';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xpress/api/apis.dart';
import 'package:xpress/helper/dialogs.dart';
import 'package:xpress/main.dart';
import 'package:xpress/screens/home_screens.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({Key? key}) : super(key: key);

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  _handleGoogleBtnClick() {
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);
      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if ((await APIs.userExists())) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          APIs.createUser().then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch (e) {
      print('\n_signInWithGoogle: $e');
      Dialogs.showSnackbar(context, 'Something went wrong, check connection');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Xpress The Chat!'),
      ),
      body: Stack(
        children: [
          //app icon
          Positioned(
            top: mq.height * 0.15,
            left: mq.width * 0.25,
            width: mq.width * 0.5,
            child: Image.asset('images/xxx.png'),
          ),
          //google login icon
          Positioned(
            bottom: mq.height * 0.15,
            left: mq.width * 0.05,
            width: mq.width * 0.9,
            height: mq.height * 0.07,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () {
                _handleGoogleBtnClick();
              },
              icon: Image.asset(
                'images/googleOne.png',
                height: 35,
              ),
              label: Text(
                'Login with Google',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
