import 'dart:async';

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/icon_map.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/sign_in.dart';

import '../models/task.dart';
import '../models/taskEntry.dart';


import 'package:flutter/material.dart';

class MyStopwatch {
  static Stopwatch stopwatch = Stopwatch();

  static ValueNotifier stopwatchValueNotifier = ValueNotifier('00:00');
  static ValueNotifier stopwatchStarted = ValueNotifier('false');
  static ValueNotifier stopwatchRunningNotifier = ValueNotifier('false');
  static ValueNotifier runningTaskNotifier = ValueNotifier('');
  static String formatDuration(Duration d) {
    return d.toString().split('.').first.padLeft(8, '0');
  }

  static String getHHMM(Duration duration) {
    String hhmmss = duration.toString().split('.').first.padLeft(8, '0');
    List list = hhmmss.split(':');
    String hhmm = list[0] + ':' + list[1];
    return hhmm;
  }

  static myfunction(int startedms) {
    MyStopwatch.stopwatch.start();
    MyStopwatch.stopwatchRunningNotifier.value = 'true';

    if (MyStopwatch.stopwatchRunningNotifier.value == 'true') {
      MyStopwatch.stopwatchValueNotifier.value =
          MyStopwatch.getHHMM(Duration(milliseconds: startedms));
      Timer.periodic(Duration(minutes: 1), (timer) {
        MyStopwatch.stopwatchValueNotifier.value = MyStopwatch.getHHMM(
          Duration(
              milliseconds:
                  MyStopwatch.stopwatch.elapsedMilliseconds + startedms),
        );
      });
    }
    if (MyStopwatch.stopwatchStarted.value == 'false') {
      MyStopwatch.runningTaskNotifier.value =
          TaskEntry.newTaskEntry.belongedTask.title;
    }
    MyStopwatch.stopwatchStarted.value = 'true';
  }

  static Color colorFromString(String colorString) {
    String valueString = colorString.split('(0x')[1].split(')')[0];
    int value = int.parse(valueString, radix: 16);
    Color color = Color(value);
    return color;
  }
}

class FirstPage extends StatefulWidget {
  final ValueNotifier authNotifier;
  FirstPage({this.authNotifier});
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  String username = '';
  String useruid;
  List taskList = [];
  final db = Firestore.instance;

  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser().then((user) {
      setState(() {
        if (user != null) {
          username = user.displayName;
          useruid = user.uid;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Time Tracker"),
        leading: IconButton(
          icon: Icon(MdiIcons.themeLightDark),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            if (Theme.of(context).brightness == Brightness.dark) {
              DynamicTheme.of(context).setBrightness(Brightness.light);
              prefs.setBool('isDark', false);
            } else if (Theme.of(context).brightness == Brightness.light) {
              DynamicTheme.of(context).setBrightness(Brightness.dark);
              prefs.setBool('isDark', true);
            }
          },
        ),
        actions: <Widget>[
          // sign out
          FlatButton(
            child: Text("Sign out"),
            onPressed: () async {
              await signOutWithGoogle();
              setState(() {
                MyStopwatch.stopwatch.stop();
                MyStopwatch.stopwatch.reset();
                MyStopwatch.stopwatchStarted.value = 'false';
              });
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('authenticated', false);
              prefs.setString('uid', '');
              widget.authNotifier.value = '';
            },
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            // Card
            ValueListenableBuilder(
                valueListenable: MyStopwatch.stopwatchStarted,
                builder: (context, value, child) {
                  return MyStopwatch.stopwatchStarted.value == 'false'
                      ? NoTaskRunningCard()
                      : CurrentCard();
                }),
            // space
            SizedBox(
              height: 30,
            ),
            // main content
            Expanded(
              child: ListView(
                children: <Widget>[
                  // task list
                  SingleChildScrollView(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: Firestore.instance
                          .collection('users/$useruid/tasks')
                          .orderBy('title')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text("Error ${snapshot.error}");
                        }
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return Text("Loading");
                          default:
                            return ListView(
                              shrinkWrap: true,
                              physics: ScrollPhysics(),
                              children: snapshot.data.documents
                                  .map((DocumentSnapshot document) {
                                return Dismissible(
                                  key: Key(document.documentID),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) async {
                                    QuerySnapshot snapshot = await Firestore
                                        .instance
                                        .collection(
                                            'users/$useruid/taskEntries')
                                        .where('belongedTaskId',
                                            isEqualTo: document.documentID)
                                        .getDocuments();
                                    var documents = snapshot.documents;
                                    // remove the task entries
                                    for (int i = 0; i < documents.length; i++) {
                                      Firestore.instance
                                          .collection(
                                              'users/$useruid/taskEntries')
                                          .document(documents[i].documentID)
                                          .delete();
                                    }
                                    // remove the task
                                    await Firestore.instance
                                        .collection('users/$useruid/tasks')
                                        .document(document.documentID)
                                        .delete();
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    color: Colors.red,
                                    child: Icon(Icons.delete),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Task task = Task.fromJson(document);
                                      startTask(document.documentID, task);
                                    },
                                    child: Container(
                                      height: 40,
                                      child: Row(
                                        children: <Widget>[
                                          taskIcon(document['icon'],
                                              document['colorHex']),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: Text(
                                              document['title'],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                        }
                      },
                    ),
                  ),
                  // Create task button
                  Center(
                    child: SizedBox(
                      height: 30,
                      child: OutlineButton(
                        child: Text("+ Create Task"),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreateTaskPage()));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  void startTask(String belongedTaskDocumentId, Task task) {
    MyStopwatch.stopwatch.start();
    MyStopwatch.stopwatchRunningNotifier.value = 'true';

    if (MyStopwatch.stopwatchRunningNotifier.value == 'true') {
      Timer.periodic(Duration(seconds: 1), (callback) {
        // MyStopwatch.stopwatchValueNotifier.value = MyStopwatch.formatDuration(
        //   Duration(milliseconds: MyStopwatch.stopwatch.elapsedMilliseconds),
        // );
        MyStopwatch.stopwatchValueNotifier.value =
            MyStopwatch.getHHMM(MyStopwatch.stopwatch.elapsed);
      });
    }
    if (MyStopwatch.stopwatchStarted.value == 'false') {
      MyStopwatch.runningTaskNotifier.value = task.title;
      TaskEntry.newTaskEntry.startTime = DateTime.now();
      TaskEntry.newTaskEntry.belongedTaskId = belongedTaskDocumentId;
      TaskEntry.newTaskEntry.belongedTask = task;
      TaskEntry.newTaskEntry.id = DateTime.now().toIso8601String();
    }
    MyStopwatch.stopwatchStarted.value = 'true';
  }
}

class CurrentCard extends StatefulWidget {
  @override
  _CurrentCardState createState() => _CurrentCardState();
}

class _CurrentCardState extends State<CurrentCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ValueListenableBuilder(
              valueListenable: MyStopwatch.runningTaskNotifier,
              builder: (context, value, child) {
                return Text(
                  value,
                  style: TextStyle(fontSize: 25),
                );
              },
            ),
            // elapsed time text
            ValueListenableBuilder(
                valueListenable: MyStopwatch.stopwatchValueNotifier,
                builder: (context, value, child) {
                  return Text(
                    MyStopwatch.stopwatchValueNotifier.value,
                    style: TextStyle(fontSize: 20),
                  );
                }),
            // actions buttons
            Center(
              child: IconButton(
                icon: Icon(Icons.stop),
                onPressed: resetButtonFunction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  resetButtonFunction() {
    MyStopwatch.stopwatch.stop();
    // reset stopwatch
    MyStopwatch.stopwatch.reset();
    MyStopwatch.stopwatchStarted.value =
        'false'; // currentCard() > noTaskRunningCard()

    // handle data
    TaskEntry.newTaskEntry.endTime = DateTime.now();
    TaskEntry.newTaskEntry.duration = TaskEntry.newTaskEntry.endTime
        .difference(TaskEntry.newTaskEntry.startTime);
    MyStopwatch.stopwatchValueNotifier.value = '00:00:00';
    MyStopwatch.stopwatchRunningNotifier.value = 'false';
    TaskEntry.saveToFirestore();
    // TaskEntry taskEntry = TaskEntry(
    //     belongedTaskName: TaskEntry.newTaskEntry.belongedTask.title,
    //     duration: parseDuration(TaskEntry.newTaskEntry.duration.toString()),
    //     startTime: TaskEntry.newTaskEntry.startTime,
    //     endTime: TaskEntry.newTaskEntry.endTime,
    //     note: TaskEntry.newTaskEntry.note);

    // TaskEntryDatabaseHelper helper = TaskEntryDatabaseHelper.instance;
    // helper.insert(taskEntry);
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

class NoTaskRunningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "No task running",
                  style: TextStyle(fontSize: 25),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateTaskPage extends StatefulWidget {
  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Color pickerColor = Color(0xff000000);
  Color currentColor = Color(0xff000000);

  List<Widget> iconList = [];
  List<String> avialableIconNameList = [];
  String searchText = '';
  TextEditingController searchController = TextEditingController();
  bool searching = false;
  ValueNotifier valueNotifier = ValueNotifier('');

  final db = Firestore.instance;
  FirebaseUser user;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Task"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            // First row > Title text field
            Container(
              height: 45,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 100,
                    child: Text(
                      "Task title",
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: TextField(
                        controller: titleController,
                        textAlign: TextAlign.end,
                        decoration: InputDecoration(
                          hintText: 'new task',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Secon row > Choose color
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
                      "Color",
                    ),
                  ),
                  Container(
                    height: 25,
                    width: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: pickerColor,
                    ),
                    child: FlatButton(
                      child: Container(),
                      onPressed: pickColor,
                    ),
                  ),
                ],
              ),
            ),
            // Third row > Choose icon
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
                      "Icon",
                    ),
                  ),
                  Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Container(
                        child: ValueListenableBuilder(
                          valueListenable: valueNotifier,
                          builder: (context, value, child) {
                            return valueNotifier.value != ''
                                ? IconButton(
                                    icon: Icon(
                                      MdiIcons.fromString(valueNotifier.value),
                                    ),
                                    onPressed: myPickIcon,
                                  )
                                : InkWell(
                                    highlightColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    child: Container(
                                      child: Text("Choose Icon"),
                                    ),
                                    onTap: myPickIcon,
                                  );
                          },
                        ),
                      )),
                ],
              ),
            ),
            // Thourth Row > Task Description
            Container(
              child: TextField(
                controller: descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'task description (optional)',
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
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    if (titleController.text == '' ||
                        currentColor.toString() == null ||
                        valueNotifier.value == '') {
                      notCompletedWarning();
                      print("Not completed");
                    } else {
                      createTask();
                      Navigator.pop(context);
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

  void createTask() async {
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    Task newTask = Task(
      title: titleController.text,
      colorHex: currentColor.toString(),
      icon: valueNotifier.value,
      taskDescription: descriptionController.text ?? '',
      userUid: user.uid,
    );

    DocumentReference ref = await db
        .collection('users')
        .document(user.uid)
        .collection('tasks')
        .add(newTask.toJson());

    print("Inserted to firebase: $ref");


  }

  Future notCompletedWarning() async {
    return showDialog(
      context: context,
      child: AlertDialog(
        title: Text("Please fill in the data"),
        actions: <Widget>[
          FlatButton(
            child: Text("Got it!"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  Future pickColor() {
    return showDialog(
      barrierDismissible: true,
      context: context,
      child: AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: changeColor,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text('Got it'),
            onPressed: () {
              setState(() => currentColor = pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  myPickIcon() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Pick an Icon!"),
            content: MyIconDialogContent(valueNotifier),
          );
        });
  }
}

class MyIconDialogContent extends StatefulWidget {
  final ValueNotifier valueNotifier;

  MyIconDialogContent(this.valueNotifier);
  @override
  _MyIconDialogContentState createState() => _MyIconDialogContentState();
}

class _MyIconDialogContentState extends State<MyIconDialogContent> {
  List<Widget> iconList = [];
  List<String> avialableIconNameList = [];
  String searchText = '';
  TextEditingController searchController = TextEditingController();
  bool searching = false;
  @override
  void initState() {
    super.initState();
    _buildIcons();
    // add every icon's name in this list
    iconMap.forEach((String key, int val) {
      avialableIconNameList.add(key);
    });
  }

  _buildIcons() async {
    iconMap.forEach((String key, int val) async {
      iconList.add(InkResponse(
          onTap: () {
            print("Chose $key");
            setState(() {
              widget.valueNotifier.value = key;
            });
            FocusScope.of(context).requestFocus(FocusNode());
            Navigator.pop(context);
          },
          child: Icon(
            MdiIcons.fromString(key),
          )));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: 300,
      child: Column(
        children: <Widget>[
          // Search bar
          Container(
            height: 35,
            width: 300,
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                searchText = val;
                setState(() {
                  if (searchController.text.isEmpty) {
                    searching = false;
                  } else {
                    searching = true;
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search icon...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    print("Pressed");
                  },
                ),
              ),
            ),
          ),
          searching == false
              ? Container(
                  child: SingleChildScrollView(
                      child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: 300,
                  child: GridView.count(
                    crossAxisCount: 5,
                    children: iconList,
                  ),
                )))
              : searchingContainer(),
        ],
      ),
    );
  }

  Widget searchingContainer() {
    List matchedList = [];
    List<Widget> matchedIconList = [];
    for (int i = 0; i < avialableIconNameList.length; i++) {
      if (avialableIconNameList[i]
          .toLowerCase()
          .contains(searchText.toLowerCase())) {
        matchedList.add(avialableIconNameList[i]);
      }
    }
    if (matchedList != []) {
      for (int i = 0; i < matchedList.length; i++) {
        iconMap.forEach((String key, int val) {
          if (matchedList[i] == key) {
            matchedIconList.add(InkResponse(
                onTap: () {
                  print("Chose $key");

                  widget.valueNotifier.value = key;
                  Navigator.pop(context);
                },
                child: Icon(
                  MdiIcons.fromString(key),
                )));
          }
        });
      }
      return Container(
          child: SingleChildScrollView(
              child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: 300,
        child: GridView.count(
          crossAxisCount: 5,
          children: matchedIconList,
        ),
      )));
    } else {
      print("No match");
      return Text("There isn't match icon");
    }
  }
}
