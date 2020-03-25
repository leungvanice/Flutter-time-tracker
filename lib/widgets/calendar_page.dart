import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_week_view/flutter_week_view.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/models/taskEntry.dart';
import 'package:time_tracker/widgets/first_page.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime showDate = DateTime.now();

  String useruid;
  void initState() {
    FirebaseAuth.instance.currentUser().then((onUser) {
      setState(() {
        useruid = onUser.uid;
      });
    });

    if (MyStopwatch.runningTaskNotifier.value == 'true') {
      Timer.periodic(Duration(minutes: 2), (callback) {
        FlutterWeekViewEvent event = FlutterWeekViewEvent(
          backgroundColor:
              colorFromString(TaskEntry.newTaskEntry.belongedTask.colorHex),
          description: TaskEntry.newTaskEntry.note ?? '',
          title: TaskEntry.newTaskEntry.belongedTask.title,
          start: TaskEntry.newTaskEntry.startTime,
          end: DateTime.now(),
        );
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
      ),
      body: Column(
        children: <Widget>[
          // day bar
          Container(
            height: 45,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  iconSize: 12,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onPressed: () => arrowBtnFunction('left'),
                ),
                FlatButton(
                  child: Text(DateFormat('EEEE, dd MMMM').format(showDate)),
                  onPressed: selectDate,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  iconSize: 12,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onPressed: () => arrowBtnFunction('right'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: Firestore.instance
                  .collection('users/$useruid/taskEntries')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Container();
                  default:
                    return DayView(
                      date: showDate,
                      dayBarHeight: 0,
                      hoursColumnBackgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.white,
                      hoursColumnTextStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey
                            : Colors.grey[800],
                      ),
                      eventsColumnBackgroundPainter:
                          EventsColumnBackgroundPainter(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.white,
                      ),
                      events:
                          snapshot.data.documents.map((DocumentSnapshot doc) {
                        return FlutterWeekViewEvent(
                          backgroundColor:
                              colorFromString(doc['belongedTask']['colorHex']),
                          title: doc['belongedTask']['title'],
                          description: doc['note'] != '' ? doc['note'] : '',
                          start: doc['startTime'].toDate(),
                          end: doc['endTime'].toDate(),
                          onTap: () {
                            print("Tapped");
                          },
                        );
                      }).toList(),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Color colorFromString(String colorString) {
    String valueString = colorString.split('(0x')[1].split(')')[0];
    int value = int.parse(valueString, radix: 16);
    Color color = Color(value);
    return color;
  }

  selectDate() async {
    DateTime choseDate = await showDatePicker(
        context: context,
        initialDate: showDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (choseDate != null) {
      setState(() {
        showDate = choseDate;
        print(DateFormat('dd MMM, EEE').format(showDate));
      });
    }
  }

  arrowBtnFunction(String leftOrRight) async {
    if (leftOrRight == 'left') {
      DateTime newDate = showDate.subtract(Duration(days: 1));
      setState(() {
        showDate = newDate;
      });
    } else {
      if (showDate != DateTime.now()) {
        DateTime newDate = showDate.add(Duration(days: 1));
        setState(() {
          showDate = newDate;
        });
      } else {
        print("This is the latest day");
      }
    }
  }
}
