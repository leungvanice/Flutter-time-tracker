import 'package:firebase_auth/firebase_auth.dart';

import './widgets/root_page.dart';
import './widgets/login_page.dart';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimeTrackerApp(),
      routes: {
        'root-page': (context) => RootPage(),
      },
    );
  }
}

// This page is for deciding which page to show based on whether the user has logged in or not
class TimeTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser() == null
        ? LoginPage()
        : RootPage();
  }
}
