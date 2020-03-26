import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String title;
  String colorHex;
  String icon;
  String taskDescription;
  String userUid;

  Task(
      {this.title,
      this.colorHex,
      this.icon,
      this.taskDescription,
      this.userUid});

  factory Task.fromJson(DocumentSnapshot map) {
    return Task(
      title: map['title'],
      colorHex: map['colorHex'],
      icon: map['icon'],
      taskDescription: map['taskDescription'],
      userUid: map['userUid'],
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      colorHex: map['colorHex'],
      icon: map['icon'],
      taskDescription: map['taskDescription'],
    );
  }

  toJson() {
    return {
      'title': title,
      'colorHex': colorHex,
      'icon': icon,
      'taskDescription': taskDescription ?? '',
      'userUid': userUid,
    };
  }
}
