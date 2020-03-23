import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:time_tracker/models/task.dart';

final db = Firestore.instance;
String uid;

class TaskEntry {
  String id;
  String belongedTaskId;
  Task belongedTask;
  String belongedTaskName;
  String note;
  DateTime startTime;
  DateTime endTime;
  Duration duration;
  TaskEntry(
      {this.id,
      this.note,
      this.startTime,
      this.endTime,
      this.duration,
      this.belongedTask,
      this.belongedTaskId,
      this.belongedTaskName});

  static TaskEntry newTaskEntry = TaskEntry();

  toJson() {
    return {
      'id': id,
      'belongedTask': belongedTask.toJson(),
      'belongedTaskId': belongedTaskId,
      'note': note ?? '',
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration.toString(),
    };
  }

  toMap() {
    return {
      'belongedTaskName': belongedTaskName,
      'duration': duration.toString(),
      'startTime': startTime.toString(),
      'endTime': endTime.toString(),
      'note': note ?? '',
    };
  }

  TaskEntry.fromJson(DocumentSnapshot map) {
    id = map['id'];
    belongedTaskId = map['belongedTaskId'];
    belongedTask = map['task'];
    note = map['note'];
    startTime = map['startTime'];
    endTime = map['endTime'];
    duration = map['duration'];
  }

  factory TaskEntry.fromMap(Map<String, dynamic> map) {
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

    return TaskEntry(
      id: map['_id'].toString(),
      belongedTaskName: map['belongedTaskName'],
      note: map['note'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      duration: parseDuration(map['duration']),
    );
  }

  static saveToFirestore() async {
    await FirebaseAuth.instance.currentUser().then((user) {
      uid = user.uid;
    });
    print("User uid: $uid");
    DocumentReference ref = await db
        .collection('users')
        .document(uid)
        .collection('tasks')
        .document(newTaskEntry.belongedTaskId)
        .collection('taskEntries')
        .add(newTaskEntry.toJson());

    DocumentReference reference = await db
        .collection('users')
        .document(uid)
        .collection('taskEntries')
        .add(newTaskEntry.toJson());

    return 'Created $ref, $reference';
  }
}
