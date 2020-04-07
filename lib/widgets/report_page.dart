import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('users/$useruid/taskEntries')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            List<TaskEntry> taskEntries = [];
            snapshot.data.documents.forEach((doc) {
              taskEntries.add(TaskEntry.fromJson(doc));
            });
            return myBarChart(taskEntries);
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget myBarChart(List<TaskEntry> taskEntries) {
    DateTime smallestDate;
    DateTime biggestDate;
    List dateList = [];
    List<BarChartGroupData> barChartGroupDataList = [];
    int totalDays;
    // 1. create date list <String>
    // Get smallest date and largest date
    taskEntries.forEach((entry) {
      DateTime entryDate =
          DateTime(entry.endTime.year, entry.endTime.month, entry.endTime.day);
      if (smallestDate == null || biggestDate == null) {
        smallestDate = entryDate;
        biggestDate = entryDate;
      } else {
        if (entryDate.isBefore(smallestDate)) {
          smallestDate = entryDate;
        } else if (entryDate.isAfter(biggestDate)) {
          biggestDate = entryDate;
        }
      }
    });
    totalDays = biggestDate.difference(smallestDate).inDays + 1;
    // Build the date list
    dateList = List.generate(totalDays, (i) {
      DateTime date = smallestDate.add(Duration(days: i));
      String formattedDate = DateFormat('dd/MM/yyyy').format(date);
      return formattedDate;
    });

    List entryDataList = List.generate(dateList.length, (i) {
      Map map = {dateList[i]: {}};
      return map;
    });

    // 2. Organize entry's data
    taskEntries.forEach((entry) {
      String taskName = entry.belongedTask.title;
      double hours = entry.duration.inMinutes / 60;
      // get the map in entryDataList according to entry's date
      String entryDate = DateFormat('dd/MM/yyyy').format(entry.endTime);
      int dateIndexInList = dateList.indexOf(entryDate);
      Map dateMap = entryDataList[dateIndexInList];
      Map entriesMap = dateMap.values.toList()[0];
      String entryColor = entry.belongedTask.colorHex;
      String valueString = entryColor.split('(0x')[1].split(')')[0];
      int value = int.parse(valueString, radix: 16);

      if (entriesMap.isEmpty) {
        entriesMap[taskName] = [hours, value];
      } else {
        if (!entriesMap.keys.toList().contains(taskName)) {
          entriesMap[taskName] = [hours, value];
        } else {
          double oldHours = entriesMap[taskName][0];
          double totalHours = oldHours + hours;
          entriesMap[taskName] = [totalHours, value];
        }
      }
    });
    // print(entryDataList);
    // 3. Build List
    int counter = 0;
    entryDataList.forEach((date) {
      double totalHours = 0;
      Map entryData = date.values.toList()[0];
      List taskList = entryData.keys.toList();
      List entryDetail = entryData.values.toList();
      // print(entryDetail);

      // get total hours (y)
      entryDetail.forEach((list) {
        totalHours += list[0];
      });
      // build height List
      double currentHours = 0;
      List heightList = List.generate(entryDetail.length, (i) {
        currentHours += entryDetail[i][0];
        return currentHours;
      });

      // build BarChartRodStackItem list
      List<BarChartRodStackItem> barChartRodStackItemList =
          List.generate(taskList.length, (i) {
        Color itemColor = Color(entryDetail[i][1]);
        // from Y
        if (i == 0) {
          return BarChartRodStackItem(0, heightList[i], itemColor);
        } else {
          return BarChartRodStackItem(
              heightList[i - 1], heightList[i], itemColor);
        }
      });
      // build BarChartRodData
      List<BarChartRodData> barChartRodData = [
        BarChartRodData(
          y: totalHours,
          width: 22,
          rodStackItem: barChartRodStackItemList,
        )
      ];
      barChartGroupDataList.add(BarChartGroupData(
        x: counter,
        barRods: barChartRodData,
      ));
      counter++;
    });

    return Center(
      child: BarChart(
        BarChartData(barGroups: barChartGroupDataList),
      ),
    );
  }
}
