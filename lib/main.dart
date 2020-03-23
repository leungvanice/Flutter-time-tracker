import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './widgets/root_page.dart';
import './widgets/login_page.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Brightness brightness =
      (prefs.getBool("isDark") ?? false) ? Brightness.dark : Brightness.light;

  FirebaseUser user;
  await FirebaseAuth.instance.currentUser().then((onUser) {
    user = user;
  });
  runApp(MyApp(
    defaultBrightness: brightness,
    user: user,
  ));
}

class MyApp extends StatefulWidget {
  Brightness defaultBrightness;
  FirebaseUser user;
  MyApp({this.defaultBrightness, this.user});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String passData;
  @override
  void initState() {
    super.initState();
    // if (widget.user.uid == null) {
    //   passData = 'none';
    // } else {
    //   passData = widget.user.uid;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: widget.defaultBrightness,
      data: (brightness) => new ThemeData(
        primarySwatch: Colors.indigo,
        brightness: brightness,
      ),
      themedWidgetBuilder: (context, theme) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: MaterialApp(
            home: TimeTrackerApp(),
            theme: theme,
            routes: {
              'root-page': (context) => RootPage(),
              'login-page': (context) => LoginPage(),
            },
          ),
        );
      },
    );
  }
}

// This page is for deciding which page to show based on whether the user has logged in or not
class TimeTrackerApp extends StatefulWidget {
  @override
  _TimeTrackerAppState createState() => _TimeTrackerAppState();
}

class _TimeTrackerAppState extends State<TimeTrackerApp> {
  FirebaseUser user;
  String useruid;
  ValueNotifier authNotifier = ValueNotifier('');
  @override
  void initState() {
    checkIfNull();
    user == null ? print("Null") : print("User logged in");

    super.initState();
  }

  checkIfNull() async {
    await FirebaseAuth.instance.currentUser().then((onUser) {
      user = onUser ?? null;
      if (user != null) {
        useruid = user.uid;
      } else {
        useruid = null;
      }
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return user == null && useruid == null ? LoginPage() : RootPage();
  // }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authNotifier,
      builder: (context, value, child) {
        return authNotifier.value == ''
            ? LoginPage(authNotifier: authNotifier)
            : RootPage(authNotifier: authNotifier);
      },
    );
  }
}
