// import './root_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/database_helper.dart';
import 'package:time_tracker/models/task.dart';

import '../sign_in.dart';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  ValueNotifier authNotifier;
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

  getUseruid() async {
    user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      print("Not null");
      return user.uid;
    }
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
          TaskDatabaseHelper helper = TaskDatabaseHelper.instance;
          getUseruid();
          helper.deleteAll();
          // sync user tasks into db
          FirebaseAuth.instance.currentUser().then((user) {
            uid = user.uid;
            print(uid);
            Firestore.instance
                .collection('users/$uid/tasks')
                .orderBy('title')
                .snapshots()
                .listen((data) {
              data.documents.forEach((doc) {
                Task task = Task.fromJson(doc);
                TaskDatabaseHelper helper = TaskDatabaseHelper.instance;
                helper.insert(task);
              });
            });
            widget.authNotifier.value = uid;
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
}
