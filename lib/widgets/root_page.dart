import './first_page.dart';
import './history_page.dart';
import './calendar_page.dart';

import 'package:flutter/material.dart';

class RootPage extends StatefulWidget {
  final ValueNotifier authNotifier;
  RootPage({this.authNotifier});
  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: <Widget>[
            FirstPage(
              authNotifier: widget.authNotifier,
            ),
            CalendarPage(),
            HistoryPage(),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.access_time),
            ),
            Tab(
              icon: Icon(Icons.calendar_today),
            ),
            Tab(
              icon: Icon(Icons.assignment),
            ),
          ],
          labelColor: Colors.yellow,
          unselectedLabelColor: Colors.blue,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: EdgeInsets.all(5.0),
          indicatorColor: Colors.red,
        ),
      ),
    );
  }
}
