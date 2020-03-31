import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/taskEntry.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String useruid;
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser().then((onUser) {
      setState(() {
        useruid = onUser.uid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report"),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              return myBarChart(taskEntries);
          }
        },
      ),
    );
  }

  Widget myBarChart(List<TaskEntry> taskEntries) {
    int yMMdSmallestDate;
    int yMMdBiggestDate;
    List<Map> dateRangeList;
    List<BarChartGroupData> barChartGroupDataList = [];
    int totalDays;
    // set smallest date and biggest date
    taskEntries.forEach((entry) {
      int yMMdEndTime = int.parse(DateFormat('yMMd').format(entry.endTime));
      if (yMMdSmallestDate == null || yMMdBiggestDate == null) {
        yMMdSmallestDate = yMMdEndTime;
        yMMdBiggestDate = yMMdEndTime;
      } else {
        if (yMMdEndTime < yMMdSmallestDate) {
          yMMdSmallestDate = yMMdEndTime;
        } else if (yMMdEndTime > yMMdBiggestDate) {
          yMMdBiggestDate = yMMdEndTime;
        }
      }
    });

    // create date list (bar chart bottom titles)
    totalDays = yMMdBiggestDate - yMMdSmallestDate + 1;
    dateRangeList = List.generate(totalDays, (i) {
      DateTime smallestDate = DateTime.parse(yMMdSmallestDate.toString());
      DateTime date = smallestDate.add(Duration(days: i));
      String formattedDate = DateFormat('dd/MM/yyyy').format(date);
      Map map = {formattedDate: []};
      return map;
    });

    // separate task entry according to date
    for (var map in dateRangeList) {
      for (var date in map.keys) {
        for (TaskEntry entry in taskEntries) {
          String formattedDate = DateFormat('dd/MM/yyyy').format(entry.endTime);
          if (formattedDate == date) {
            for (var list in map.values) {
              list.add(entry);
            }
          }
        }
      }
    }

    // add up task entries belonged to same task in single day
    dateRangeList.forEach((map) {
      for (List entryList in map.values) {
        List taskList = [];
        List toAdd = [];
        List addedTaskNameList = [];

        entryList.forEach((entry) {
          String taskName = entry.belongedTask.title;
          double hours = entry.duration.inMinutes / 60;
          Map taskMap = {taskName: hours};
          if (taskList.isEmpty) {
            taskList.add(taskMap);
          } else {
            for (var map in taskList) {
              for (var existedTask in map.keys) {
                if (taskName != existedTask &&
                    !addedTaskNameList.contains(taskName)) {
                  toAdd.add(taskMap);
                  addedTaskNameList.add(taskName);
                } else {
                  for (double oldHour in map.values) {
                    double newHour = oldHour + hours;
                    if (taskName == existedTask) {
                      map[existedTask] = newHour;
                    } else if (addedTaskNameList.contains(taskName)) {
                      toAdd.forEach((map) {
                        for (var addedTask in map.keys) {
                          for (double oldHour in map.values) {
                            double newHour = oldHour + hours;
                            map[addedTask] = newHour;
                          }
                        }
                      });
                    }
                  }
                }
              }
            }
          }
        });
        // combine the lists
        taskList.add(toAdd);
      }
    });

    // build barChartGroupDataList
    // barChartGroupDataList = List.generate(dateRangeList.length, (i) {
    //   //  create BarChartRodStackItem List > pass to rodStackItem parameter
    //   List<BarChartRodStackItem> stackDataList = [];
    //   for (List entryList in dateRangeList[i].values) {
    //     // BarChartRodStackItem item = BarChartRodStackItem();

    //   }

    //   return BarChartGroupData(
    //     x: i,
    //     // barRods: dateRangeList[i].
    //   );
    // });
    // print(dateRangeList[0].values);

    return Container();
  }
}
