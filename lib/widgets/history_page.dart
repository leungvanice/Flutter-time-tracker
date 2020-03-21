import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String useruid;
  void initState() {
    FirebaseAuth.instance.currentUser().then((user) {
      setState(() {
        useruid = user.uid;
      });
    });
    super.initState();
  }

  formatStringDuration(String d) {
    return d.split('.').first.padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Entries"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: StreamBuilder(
          stream: Firestore.instance
              .collection('users')
              .document(useruid)
              .collection('taskEntries')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Text("Loading");
              default:
                return ListView(
                  children: snapshot.data.documents.map((document) {
                    return Container(
                      height: 40,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            MdiIcons.fromString(
                              document['belongedTask']['icon'],
                            ),
                          ),
                          // text column
                          Container(
                            width: MediaQuery.of(context).size.width * 0.65,
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  document['belongedTask']['title'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                    "${DateFormat('HH:mm').format(document['startTime'].toDate())} - ${DateFormat('HH:mm').format(document['endTime'].toDate())}",
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          // duration display
                          Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                                formatStringDuration(document['duration'])),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ),
      ),
    );
  }
}
