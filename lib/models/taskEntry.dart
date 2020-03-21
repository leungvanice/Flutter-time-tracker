import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_tracker/models/task.dart';

final db = Firestore.instance;
String uid;

class TaskEntry {
  String id;
  String belongedTaskId;
  Task belongedTask;
  String note;
  DateTime startTime;
  DateTime endTime;
  Duration duration;
  TaskEntry(
      {this.note,
      this.startTime,
      this.endTime,
      this.duration,
      this.belongedTask,
      this.belongedTaskId});

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
