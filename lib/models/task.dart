import 'package:firebase_auth/firebase_auth.dart';

class Task {
  String title;
  String colorHex;
  String icon;
  String taskDescription;
  String  userUid;

  Task({this.title, this.colorHex, this.icon, this.taskDescription, this.userUid});

  factory Task.fromJson(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      colorHex: map['colorHex'],
      icon: map['icon'],
      taskDescription: map['taskDescription'],
      userUid: map['userUid'],
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
