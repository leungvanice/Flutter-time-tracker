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
  runApp(MyApp(
    defaultBrightness: brightness,
  ));
}

class MyApp extends StatelessWidget {
  Brightness defaultBrightness;
  MyApp({this.defaultBrightness});
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      // defaultBrightness: Brightness.light,
      defaultBrightness: defaultBrightness,
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
class TimeTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser() == null
        ? LoginPage()
        : RootPage();
  }
}
