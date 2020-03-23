// import './root_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_tracker/database_helper.dart';
import 'package:time_tracker/models/task.dart';

import '../sign_in.dart';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      onPressed: () {
        signInWithGoogle().whenComplete(() {
          String useruid;
          TaskDatabaseHelper helper = TaskDatabaseHelper.instance;
          helper.deleteAll();
          FirebaseAuth.instance.currentUser().then((user) {
            useruid = user.uid;
            print(useruid);
            Firestore.instance
                .collection('users/$useruid/tasks')
                .orderBy('title')
                .snapshots()
                .listen((data) {
              data.documents.forEach((doc) {
                Task task = Task.fromJson(doc);
                TaskDatabaseHelper helper = TaskDatabaseHelper.instance;
                helper.insert(task);
              });
            });
          });

          Navigator.pushNamedAndRemoveUntil(context, 'root-page', (_) => false);
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
