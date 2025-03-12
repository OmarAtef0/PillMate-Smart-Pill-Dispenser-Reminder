// models/alarm.dart
class Alarm {
  String id;
  String time; // Format: "HH:mm"
  List<String> repeatDays;

  Alarm({
    required this.id,
    required this.time,
    required this.repeatDays,
  });

  factory Alarm.fromMap(String id, Map<String, dynamic> map) {
    return Alarm(
      id: id,
      time: map['time'] ?? '00:00',
      repeatDays: List<String>.from(map['repeatDays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'repeatDays': repeatDays,
    };
  }
}
