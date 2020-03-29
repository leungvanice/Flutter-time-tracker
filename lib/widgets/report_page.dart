import 'package:charts_flutter/flutter.dart' as charts;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/models/taskEntry.dart';
import 'package:time_tracker/widgets/first_page.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String useruid;
  final List<charts.Series<TaskEntryEveryday, String>> seriesList = [];

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report"),
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('users/$useruid/taskEntries')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Text("Loading");
            default:
              List<TaskEntry> taskEntries = [];
              snapshot.data.documents.forEach((doc) {
                taskEntries.add(TaskEntry.fromJson(doc));
              });
              return buildChart(context, taskEntries);
          }
        },
      ),
    );
  }

  Widget buildChart(BuildContext context, List<TaskEntry> taskEntries) {
    List taskList = []; // have duplicate data
    List detailList = []; // hold detail
    Map mapList =
        Map(); // {Programming: [detail, detail], Badminton: [detail, detail]}
    int counter = 0; // to get the hour in hoursList

    // todo: add up task entries hours and put then into different task
    taskEntries.forEach((entry) {
      Map detail = {
        'Date': DateFormat('dd/mm/yyyy').format(entry.endTime),
        'Hours': entry.duration.inMinutes / 60,
        'Color': entry.belongedTask.colorHex,
      };
      detailList.add(detail);
      Map taskMap = {
        entry.belongedTask.title: [detail]
      };
      taskList.add(taskMap);
    });
    taskList.forEach((taskMap) {
      for (var key in taskMap.keys) {
        if (!mapList.containsKey(key)) {
          mapList[key] = taskMap.values;
        } else {
          for (var list in mapList[key]) {
            list.add(detailList[counter]);
          }
        }
      }
      counter++;
    });

    for (var taskTitle in mapList.keys) {
      List<TaskEntryEveryday> list = [];
      // print(taskTitle);
      // create task data list using TaskEntryEveryday class
      for (var detailList in mapList[taskTitle]) {
        detailList.forEach((detail) {
          TaskEntryEveryday taskEntryEveryday = TaskEntryEveryday(
              date: detail['Date'],
              hours: detail['Hours'],
              color: MyStopwatch.colorFromString(detail['Color']));
          list.add(taskEntryEveryday);
        });
      }

      // add series to seriesList
      seriesList.add(charts.Series<TaskEntryEveryday, String>(
        id: taskTitle,
        domainFn: (TaskEntryEveryday data, _) => data.date,
        measureFn: (TaskEntryEveryday data, _) => data.hours,
        colorFn: (TaskEntryEveryday data, _) =>
            charts.ColorUtil.fromDartColor(data.color),
        data: list,
      ));
    }

    // build different data list using task

    // create charts.Series and add to the seriesList
    // build chart
    return Container(
      child: SizedBox(
        height: 300,
        child: charts.BarChart(
          seriesList,
          barGroupingType: charts.BarGroupingType.stacked,
          animate: true,
          animationDuration: Duration(seconds: 1),
        ),
      ),
    );
  }

  getUser() {
    FirebaseAuth.instance.currentUser().then((user) {
      setState(() {
        useruid = user.uid;
      });
    });
  }
}

class TaskEntryEveryday {
  final String date;
  final double hours;
  final Color color;

  TaskEntryEveryday({this.date, this.hours, this.color});
}
