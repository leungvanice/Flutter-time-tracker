import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:time_tracker/models/task.dart';
import 'package:time_tracker/models/taskEntry.dart';
import 'package:time_tracker/widgets/first_page.dart';

import '../database_helper.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String useruid;
  DateTime fromDate;
  DateTime toDate;
  int yMMdFromDate;
  int yMMdToDate;
  int yMMdToday;
  List documents;
  ValueNotifier todayNotifier = ValueNotifier('true');

  getUser() {
    FirebaseAuth.instance.currentUser().then((user) {
      setState(() {
        useruid = user.uid;
      });
    });
  }

  setDate() async {
    toDate = DateTime.now();
    fromDate = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    fromDate = toDate.subtract(Duration(days: prefs.getInt('queryRange') ?? 0));

    yMMdFromDate = int.parse(DateFormat('yMMd').format(fromDate));
    yMMdToDate = int.parse(DateFormat('yMMd').format(toDate));
    yMMdToday = int.parse(DateFormat('yMMd').format(toDate));
  }

  void initState() {
    super.initState();

    setDate();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Entries"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              List<Task> taskList = [];
              QuerySnapshot snapshot = await Firestore.instance
                  .collection('users/$useruid/tasks')
                  .getDocuments();
              var documents = snapshot.documents;
              for (int i = 0; i < documents.length; i++) {
                Task task = Task.fromJson(documents[i]);
                taskList.add(task);
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateTaskEntry(taskList)));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
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
                  onPressed: () {
                    arrowBtnFunc('left');
                  },
                ),
                FlatButton(
                  child: Text(DateFormat('dd MMM, EEE').format(fromDate)),
                  onPressed: () => selectDate('left'),
                ),
                Text('-'),
                FlatButton(
                  child: Text(DateFormat('dd MMM, EEE').format(toDate)),
                  onPressed: () => selectDate('right'),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  iconSize: 12,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onPressed: () {
                    arrowBtnFunc('right');
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: todayNotifier,
            builder: (context, value, child) {
              return todayNotifier.value == 'true'
                  ? showRunningTask()
                  : Container();
            },
          ),
          // history list
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20),
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection('users/$useruid/taskEntries')
                    .orderBy('endTime', descending: true)
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
                      return ListView(
                        children: snapshot.data.documents.map(
                          (document) {
                            return int.parse(DateFormat('yMMd').format(
                                            document['endTime'].toDate())) >=
                                        yMMdFromDate &&
                                    int.parse(DateFormat('yMMd').format(
                                            document['endTime'].toDate())) <=
                                        yMMdToDate
                                ? Container(
                                    height: 40,
                                    child: Row(
                                      children: <Widget>[
                                        taskIcon(
                                            document['belongedTask']['icon'],
                                            document['belongedTask']
                                                ['colorHex']),
                                        // text column
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.65,
                                          padding:
                                              const EdgeInsets.only(left: 10),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              // task title
                                              Text(
                                                document['belongedTask']
                                                    ['title'],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              Text(
                                                  "${DateFormat().add_jm().format(document['startTime'].toDate())} - ${DateFormat().add_jm().format(document['endTime'].toDate())}",
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        // duration display
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(formatStringDuration(
                                              document['duration'])),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container();
                          },
                        ).toList(),
                      );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget taskIcon(String icon, String colorString) {
    String valueString = colorString.split('(0x')[1].split(')')[0];
    int value = int.parse(valueString, radix: 16);
    Color color = Color(value);
    return Icon(
      MdiIcons.fromString(
        icon,
      ),
      color: color,
    );
  }

  Widget showRunningTask() {
    return ValueListenableBuilder(
      valueListenable: MyStopwatch.stopwatchRunningNotifier,
      builder: (context, value, child) {
        return MyStopwatch.stopwatchRunningNotifier.value == 'true'
            ? Container(
                margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                height: 40,
                child: Row(
                  children: <Widget>[
                    taskIcon(
                      TaskEntry.newTaskEntry.belongedTask.icon,
                      TaskEntry.newTaskEntry.belongedTask.colorHex,
                    ),
                    // text column
                    Container(
                      width: MediaQuery.of(context).size.width * 0.65,
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // task title
                          Text(
                            MyStopwatch.runningTaskNotifier.value,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorFromString(TaskEntry
                                    .newTaskEntry.belongedTask.colorHex)),
                          ),
                          Text(
                              "${DateFormat().add_jm().format(TaskEntry.newTaskEntry.startTime)} - ",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorFromString(TaskEntry
                                      .newTaskEntry.belongedTask.colorHex))),
                        ],
                      ),
                    ),
                    // duration display
                    Container(
                      alignment: Alignment.centerRight,
                      child: ValueListenableBuilder(
                        valueListenable: MyStopwatch.stopwatchValueNotifier,
                        builder: (context, value, child) {
                          return Text(
                            MyStopwatch.stopwatchValueNotifier.value,
                            style: TextStyle(
                                color: colorFromString(TaskEntry
                                    .newTaskEntry.belongedTask.colorHex)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                height: 10,
              );
      },
    );
  }

  Color colorFromString(String colorString) {
    String valueString = colorString.split('(0x')[1].split(')')[0];
    int value = int.parse(valueString, radix: 16);
    Color color = Color(value);
    return color;
  }

  _saveRange(int newVal) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'queryRange';
    final value = newVal;
    prefs.setInt(key, value);
    print('saved $value');
  }

  Future selectDate(String leftOrRight) async {
    if (leftOrRight == 'left') {
      DateTime choseDate = await showDatePicker(
          context: context,
          initialDate: fromDate,
          firstDate: DateTime(2020),
          lastDate: toDate);
      setState(() {
        if (choseDate != null) fromDate = choseDate;
        yMMdFromDate = int.parse(DateFormat('yMMd').format(fromDate));
      });
    } else if (leftOrRight == 'right') {
      DateTime choseDate = await showDatePicker(
          context: context,
          initialDate: toDate,
          firstDate: fromDate,
          lastDate: DateTime.now());
      setState(() {
        if (choseDate != null) toDate = choseDate;
        yMMdToDate = int.parse(DateFormat('yMMd').format(toDate));
      });
    }
    if (yMMdToday >= yMMdFromDate && yMMdToday <= yMMdToday) {
      todayNotifier.value = 'true';
    } else {
      todayNotifier.value = 'false';
    }
    Duration dayViewRange = toDate.difference(fromDate);
    _saveRange(dayViewRange.inDays);
  }

  arrowBtnFunc(String leftorRight) {
    Duration dayViewRange = toDate.difference(fromDate);
    if (leftorRight == 'left') {
      setState(() {
        DateTime newFromDate =
            fromDate.subtract(dayViewRange).subtract(Duration(days: 1));
        DateTime newToDate =
            toDate.subtract(dayViewRange).subtract(Duration(days: 1));
        fromDate = newFromDate;
        toDate = newToDate;
        yMMdFromDate = int.parse(DateFormat('yMMd').format(fromDate));
        yMMdToDate = int.parse(DateFormat('yMMd').format(toDate));
        if (yMMdToday >= yMMdFromDate && yMMdToday <= yMMdToDate) {
          todayNotifier.value = 'true';
        } else {
          todayNotifier.value = 'false';
        }
        // todayNotifier.value = 'false';
      });
    } else if (leftorRight == 'right') {
      setState(() {
        DateTime newFromDate =
            fromDate.add(dayViewRange).add(Duration(days: 1));
        DateTime newToDate = toDate.add(dayViewRange).add(Duration(days: 1));
        fromDate = newFromDate;
        toDate = newToDate;
        yMMdFromDate = int.parse(DateFormat('yMMd').format(fromDate));
        yMMdToDate = int.parse(DateFormat('yMMd').format(toDate));
        if (yMMdToday >= yMMdFromDate && yMMdToday <= yMMdToDate) {
          todayNotifier.value = 'true';
        } else {
          todayNotifier.value = 'false';
        }
      });
    }
  }

  formatStringDuration(String d) {
    return d.split('.').first.padLeft(8, '0');
  }
}

class CreateTaskEntry extends StatefulWidget {
  List<Task> taskList;
  CreateTaskEntry(this.taskList);
  @override
  _CreateTaskEntryState createState() => _CreateTaskEntryState();
}

class _CreateTaskEntryState extends State<CreateTaskEntry> {
  List<Task> fsTaskList = [];
  Task choseTask;
  String useruid;
  DateTime startTime = DateTime.now();
  DateTime endTime;
  Duration duration;
  String value;
  TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    value = widget.taskList[0].title;
    initFunction();
  }

  initFunction() async {
    await setUser();
    await getTaskList();
  }

  setUser() async {
    // await FirebaseAuth.instance.currentUser().then((user) {
    //   useruid = user.uid;
    // });
    final prefs = await SharedPreferences.getInstance();
    useruid = prefs.getString('uid');
    print("User set: $useruid");
  }

  getTaskList() async {
    QuerySnapshot snapshot = await Firestore.instance
        .collection('users/$useruid/tasks')
        .getDocuments();
    var documents = snapshot.documents;
    // print(Task.fromJson(documents[0]).title);
    for (int i = 0; i < documents.length; i++) {
      fsTaskList.add(Task.fromJson(documents[i]));
    }
  }

  formatDuration(Duration duration) {
    return duration.toString().split('.')[0].padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Task Entry"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            // First row
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
                  Container(
                    width: 100,
                    child: Text(
                      "Task",
                    ),
                  ),
                  Container(
                    // decoration:
                    //     BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: DropdownButton(
                      items: widget.taskList.map((Task task) {
                        return DropdownMenuItem(
                          child: Text(task.title),
                          value: task.title,
                        );
                      }).toList(),
                      value: value,
                      onChanged: (val) {
                        setState(() {
                          value = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Secon row
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
                  Container(
                    width: 100,
                    child: Text(
                      "Start Time",
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        child: FlatButton(
                          child: Text(
                              DateFormat('dd MMMM yyyy').format(startTime)),
                          onPressed: () {
                            chooseDate('left');
                          },
                        ),
                      ),
                      Container(
                        child: FlatButton(
                          child: Text(DateFormat().add_jm().format(startTime)),
                          onPressed: () {
                            chooseTime('left');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Third row
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
                  Container(
                    width: 100,
                    child: Text(
                      "End Time",
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        child: FlatButton(
                          child: endTime != null
                              ? Text(DateFormat('dd MMMM yyyy').format(endTime))
                              : Container(),
                          onPressed: () {
                            chooseDate('right');
                          },
                        ),
                      ),
                      Container(
                        child: FlatButton(
                          child: endTime != null
                              ? Text(DateFormat().add_jm().format(endTime))
                              : Container(),
                          onPressed: () {
                            chooseTime('right');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                  Container(
                    width: 100,
                    child: Text(
                      "Duration",
                    ),
                  ),
                  Container(
                    child: FlatButton(
                      child: duration != null
                          ? Text(formatDuration(duration))
                          : Container(),
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                color: Colors.white,
                                height: MediaQuery.of(context).size.height / 3,
                                child: CupertinoTimerPicker(
                                  mode: CupertinoTimerPickerMode.hm,
                                  initialTimerDuration:
                                      Duration(milliseconds: 0),
                                  minuteInterval: 1,
                                  secondInterval: 1,
                                  onTimerDurationChanged:
                                      (Duration changedtimer) {
                                    setState(() {
                                      duration = changedtimer;
                                      endTime = startTime.add(duration);
                                    });
                                  },
                                ),
                              );
                            });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Thourth Row
            Container(
              child: TextField(
                controller: noteController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'note (optional)',
                ),
              ),
            ),
            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text("Save"),
                  onPressed: () async {
                    if (endTime != null && duration != null) {
                      saveTaskEntry();
                      Navigator.pop(context);
                    } else if (endTime == null && duration == null) {
                      await readyToStart();
                      Navigator.pop(context);
                      Duration difference =
                          DateTime.now().difference(startTime);

                      MyStopwatch.myfunction(difference.inMilliseconds);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  saveTaskEntry() async {
    QuerySnapshot snapshot = await Firestore.instance
        .collection('users/$useruid/tasks')
        .where('title', isEqualTo: value)
        .getDocuments();
    var documents = snapshot.documents;
    TaskEntry.newTaskEntry.id = DateTime.now().toIso8601String();
    TaskEntry.newTaskEntry.belongedTask = Task.fromJson(documents[0]);
    TaskEntry.newTaskEntry.belongedTaskId = documents[0].documentID;
    TaskEntry.newTaskEntry.note = noteController.text;
    TaskEntry.newTaskEntry.startTime = startTime;
    TaskEntry.newTaskEntry.endTime = endTime;
    TaskEntry.newTaskEntry.duration = duration;

    await TaskEntry.saveToFirestore();
  }

  readyToStart() async {
    QuerySnapshot snapshot = await Firestore.instance
        .collection('users/$useruid/tasks')
        .where('title', isEqualTo: value)
        .getDocuments();

    var documents = snapshot.documents;
    Task task = Task.fromJson(documents[0]);
    TaskEntry.newTaskEntry.id = DateTime.now().toIso8601String();
    TaskEntry.newTaskEntry.belongedTask = task;
    TaskEntry.newTaskEntry.belongedTaskId = documents[0].documentID;
    TaskEntry.newTaskEntry.note = noteController.text;
    TaskEntry.newTaskEntry.startTime = startTime;
  }

  chooseDate(String leftOrRight) async {
    DateTime choseDate = await showDatePicker(
        context: context,
        initialDate: startTime,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (leftOrRight == 'left') {
      setState(() {
        if (choseDate != null) {
          startTime = choseDate;
        }
      });
    } else {
      setState(() {
        if (choseDate != null) {
          endTime = choseDate;
        }
      });
    }
  }

  chooseTime(String leftOrRight) async {
    TimeOfDay choseTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    DateTime now = DateTime.now();
    if (leftOrRight == 'left') {
      setState(() {
        if (choseTime != null) {
          startTime = DateTime(
              now.year, now.month, now.day, choseTime.hour, choseTime.minute);
          print(DateFormat().add_jm().format(startTime));
        }
      });
    } else {
      setState(() {
        if (choseTime != null) {
          endTime = DateTime(
              now.year, now.month, now.day, choseTime.hour, choseTime.minute);
          print(DateFormat().add_jm().format(endTime));
          duration = endTime.difference(startTime);
        }
      });
    }
  }
}
