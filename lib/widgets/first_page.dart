import 'dart:io';

import 'package:flutter_iconpicker/Serialization/iconDataSerialization.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/icon_map.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/task.dart';

import 'package:flutter/material.dart';

import '../socicons_icons.dart';

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  String username = '';
  void initState() {
    FirebaseAuth.instance.currentUser().then((user) {
      setState(() {
        username = user.displayName;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaquery = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Time Tracker"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Card(
              child: Container(
                height: mediaquery.height * 0.2,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(
                      "Reading",
                      style: TextStyle(fontSize: 25),
                    ),
                    Text(
                      "00:00:00",
                      style: TextStyle(fontSize: 20),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.play_arrow),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.pause,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.stop),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListView.builder(
                    physics: ScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 5,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text("item $index"),
                      );
                    },
                  ),
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
  Widget _icon;
  IconData icon;
  List<Widget> iconList = [];

  final db = Firestore.instance;

  @override
  void initState() {
    super.initState();
    _buildIcons();
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
                      // border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                      color: pickerColor,
                    ),
                    child: FlatButton(
                      child: Container(),
                      onPressed: myPickIcon,
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
                    child: _icon != null
                        ? IconButton(
                            icon: _icon,
                            onPressed: pickIcon,
                          )
                        : InkWell(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            child: Container(
                              child: Text("Choose Icon"),
                            ),
                            onTap: pickIcon,
                          ),
                  ),
                ],
              ),
            ),
            // Thourth Row > Task Description
            Container(
              child: TextField(
                controller: descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'task description',
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
                    createTask();
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
    Task newTask = Task(
      title: titleController.text,
      colorHex: currentColor.toString(),
      iconMap: iconDataToMap(icon),
      taskDescription: descriptionController.text ?? '',
    );
    print(newTask.colorHex);
    print(newTask.iconMap);
    print(newTask.taskDescription);
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

  pickIcon() async {
    icon = await FlutterIconPicker.showIconPicker(context,
        iconSize: 40,
        iconPickerShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title:
            Text('Pick an icon', style: TextStyle(fontWeight: FontWeight.bold)),
        closeChild: Text(
          'Close',
          textScaleFactor: 1.25,
        ),
        searchHintText: 'Search icon...',
        noResultsText: 'No results for:');

    setState(() {
      if (icon != null) {
        _icon = Icon(icon);
      } else {
        _icon = null;
      }
    });
  }

  _buildIcons() async {
    iconMap.forEach((String key, int val) async {
      iconList.add(InkResponse(
          onTap: () => print("Chose $key"),
          child: Icon(
            MdiIcons.fromString(key),
          )));
    });
  }

  myPickIcon() async {
    return showDialog(
      context: context,
      child: AlertDialog(
        title: Text("Pick an Icon!"),
        content: Container(
          height: 300,
          width: 200,
          child: Column(
            children: <Widget>[
              Container(
                child: Text("Search bar"),
              ),
              Container(
                child: SingleChildScrollView(
                  child: Container(
                    height: 200,
                    width: 200,
                    child: GridView.count(
                      crossAxisCount: 5,
                      children: iconList,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
