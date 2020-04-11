import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:time_tracker/models/task.dart';

import '../sign_in.dart';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final ValueNotifier authNotifier;
  LoginPage({this.authNotifier});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseUser user;

  @override
  void initState() {
    checkIfNull();

    super.initState();
  }

  checkIfNull() async {
    await FirebaseAuth.instance.currentUser().then((onUser) {
      user = onUser ?? null;
    });
  }

  List<Task> taskList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _signInButton(),
      ),
    );
  }

  Widget _signInButton() {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () async {
        await signInWithGoogle().whenComplete(() async {
          String uid;

          // sync user tasks into db
          FirebaseAuth.instance.currentUser().then((user) {
            uid = user.uid;
            print(uid);

            widget.authNotifier.value = uid;
            saveUid(uid);
          });

          // Navigator.pushNamedAndRemoveUntil(context, 'root-page', (_) => false);
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("assets/google_logo.png"), height: 35.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  saveUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('uid', uid);
  }

  Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }
}
