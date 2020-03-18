class Task {
  String title;
  String colorHex;
  Map iconMap;
  String taskDescription;

  Task({this.title, this.colorHex, this.iconMap, this.taskDescription});

  factory Task.fromJson(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      colorHex: map['colorHex'],
      iconMap: map['iconMap'],
      taskDescription: map['taskDescription'],
    );
  }

  toJson() {
    return {
      'title': title,
      'colorHex': colorHex,
      'iconMap': iconMap,
      'taskDescription': taskDescription ?? '',
    };
  }
}
