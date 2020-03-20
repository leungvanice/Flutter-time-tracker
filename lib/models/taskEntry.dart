import 'package:cloud_firestore/cloud_firestore.dart';

final db = Firestore.instance;

class TaskEntry {
  String id;
  String belongedTask;
  String note;
  DateTime startTime;
  DateTime endTime;
  Duration duration;
  TaskEntry({this.note, this.startTime, this.endTime, this.duration});

  static TaskEntry newTaskEntry = TaskEntry();

  toJson() {
    return {
      'id': id,
      'belongedTask': belongedTask,
      'note': note ?? '',
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration.toString(),
    };
  }

  static saveToFirestore() async {
    DocumentReference ref = await db
        .collection('tasks')
        .document(newTaskEntry.belongedTask)
        .collection('taskEntries')
        .add(newTaskEntry.toJson());

    return 'Created $ref';
  }
}
