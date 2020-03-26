import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/task.dart';
import 'package:time_tracker/models/taskEntry.dart';

import 'first_page.dart';

class TaskDetailPage extends StatefulWidget {
  TaskEntry taskEntry;
  final List<Task> taskList;
  String docId;
  TaskDetailPage({this.taskEntry, this.taskList, this.docId});
  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  String value = '';
  TextEditingController noteController = TextEditingController();
  @override
  void initState() {
    value = widget.taskEntry.belongedTask.title;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Entry Detail'),
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
                    child: DropdownButtonHideUnderline(
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
                          child: Text(DateFormat('dd MMMM yyyy')
                              .format(widget.taskEntry.startTime)),
                          onPressed: () => chooseDate('left'),
                        ),
                      ),
                      Container(
                        child: FlatButton(
                          child: Text(DateFormat()
                              .add_jm()
                              .format(widget.taskEntry.startTime)),
                          onPressed: () => chooseTime('left'),
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
                  widget.taskEntry.endTime != null
                      ? Row(
                          children: <Widget>[
                            Container(
                              child: FlatButton(
                                child: Text(DateFormat('dd MMMM yyyy')
                                    .format(widget.taskEntry.endTime)),
                                onPressed: () => chooseDate('right'),
                              ),
                            ),
                            Container(
                              child: FlatButton(
                                child: Text(DateFormat()
                                    .add_jm()
                                    .format(widget.taskEntry.endTime)),
                                onPressed: () => chooseTime('right'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            Container(
                              child: FlatButton(
                                child: Text(''),
                                onPressed: () {},
                              ),
                            ),
                            Container(
                              child: FlatButton(
                                child: Text(''),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        )
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
                      child: widget.taskEntry.duration != null
                          ? Text(MyStopwatch.formatDuration(
                              widget.taskEntry.duration))
                          : Text(''),
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
                                      widget.taskEntry.duration == null
                                          ? Duration(milliseconds: 0)
                                          : widget.taskEntry.duration,
                                  minuteInterval: 1,
                                  secondInterval: 1,
                                  onTimerDurationChanged:
                                      (Duration changedtimer) {
                                    setState(() {
                                      widget.taskEntry.duration = changedtimer;
                                      widget.taskEntry.endTime = widget
                                          .taskEntry.startTime
                                          .add(changedtimer);
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
                    await setTask();
                    await saveBtnFunc();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  chooseDate(String leftOrRight) async {
    DateTime startT = widget.taskEntry.startTime;
    DateTime endT = widget.taskEntry.endTime == null
        ? DateTime.now()
        : widget.taskEntry.endTime;

    if (leftOrRight == 'left') {
      DateTime choseDate = await showDatePicker(
          context: context,
          initialDate: widget.taskEntry.startTime,
          firstDate: DateTime(2020),
          lastDate: DateTime(3000));
      setState(() {
        if (choseDate != null) {
          DateTime newDate = DateTime(choseDate.year, choseDate.month,
              choseDate.day, startT.hour, startT.minute);
          widget.taskEntry.startTime = newDate;
        }
      });
    } else {
      DateTime choseDate = await showDatePicker(
          context: context,
          initialDate: endT,
          firstDate: DateTime(2020),
          lastDate: DateTime(3000));
      setState(() {
        if (choseDate != null) {
          DateTime newDate = DateTime(choseDate.year, choseDate.month,
              choseDate.day, endT.hour, endT.minute);
          widget.taskEntry.endTime = newDate;
        }
      });
    }
  }

  chooseTime(String leftOrRight) async {
    DateTime startT = widget.taskEntry.startTime;
    DateTime endT = widget.taskEntry.endTime == null
        ? DateTime.now()
        : widget.taskEntry.endTime;
    if (leftOrRight == 'left') {
      TimeOfDay choseTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: widget.taskEntry.startTime.hour,
            minute: widget.taskEntry.startTime.minute),
      );
      setState(() {
        if (choseTime != null) {
          widget.taskEntry.startTime = DateTime(startT.year, startT.month,
              startT.day, choseTime.hour, choseTime.minute);

          print(DateFormat().add_jm().format(widget.taskEntry.startTime));
          widget.taskEntry.duration =
              widget.taskEntry.endTime.difference(widget.taskEntry.startTime);
        }
      });
    } else {
      TimeOfDay choseTime = await showTimePicker(
        context: context,
        initialTime: widget.taskEntry.endTime != null
            ? TimeOfDay(
                hour: widget.taskEntry.endTime.hour,
                minute: widget.taskEntry.endTime.minute)
            : TimeOfDay(hour: endT.hour, minute: endT.minute),
      );
      setState(() {
        if (choseTime != null) {
          widget.taskEntry.endTime = DateTime(endT.year, endT.month, endT.day,
              choseTime.hour, choseTime.minute);
          print(DateFormat().add_jm().format(widget.taskEntry.endTime));
          widget.taskEntry.duration =
              widget.taskEntry.endTime.difference(widget.taskEntry.startTime);
        }
      });
    }
  }

  setTask() async {
    final prefs = await SharedPreferences.getInstance();
    String useruid = prefs.getString('uid');
    // get task from fs using the value
    QuerySnapshot snapshot = await Firestore.instance
        .collection('users/$useruid/tasks')
        .where('title', isEqualTo: value)
        .getDocuments();
    var documents = snapshot.documents;
    Task task = Task.fromJson(documents[0]);
    widget.taskEntry.belongedTask = task;
    widget.taskEntry.note = noteController.text;
  }

  saveBtnFunc() async {
    final prefs = await SharedPreferences.getInstance();
    String useruid = prefs.getString('uid');
    if (widget.docId != null) {
      await Firestore.instance
          .collection('users/$useruid/taskEntries')
          .document(widget.docId)
          .setData(widget.taskEntry.toJson());
    }
  }
}
