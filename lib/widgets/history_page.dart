import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

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
  List documents;

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
            onPressed: null,
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
          // history list
          Expanded(
            child: Container(
              margin: EdgeInsets.all(20),
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
                                          color: Colors.white,
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
                                                  "${DateFormat('HH:mm').format(document['startTime'].toDate())} - ${DateFormat('yMMd').format(document['endTime'].toDate())}",
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
                                : noTaskEntry(
                                    document.documentID,
                                    snapshot
                                        .data
                                        .documents[
                                            snapshot.data.documents.length - 1]
                                        .documentID);
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

  Widget noTaskEntry(String documentId, String lastDocumentId) {
    List<Widget> list = [];
    if (documentId == lastDocumentId) {
      list.add(Container(
        child: Text("No task in the selected period"),
      ));
      return list[0];
    }
    return Container();
  }

  _save(int newVal) async {
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
          lastDate: DateTime.now());
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
    Duration dayViewRange = toDate.difference(fromDate);
    _save(dayViewRange.inDays);
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
      });
    }
  }

  formatStringDuration(String d) {
    return d.split('.').first.padLeft(8, '0');
  }
}
