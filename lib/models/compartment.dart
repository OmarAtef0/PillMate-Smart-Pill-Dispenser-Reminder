// models/compartment.dart
class Compartment {
  String id;
  String name;
  int pillCount;
  Map<String, Alarm> alarms;

  Compartment({
    required this.id,
    required this.name,
    required this.pillCount,
    required this.alarms,
  });

  factory Compartment.fromMap(String id, Map<String, dynamic> map) {
    Map<String, Alarm> alarmsMap = {};
    if (map['alarms'] != null && map['alarms'] is Map) {
      (map['alarms'] as Map<String, dynamic>).forEach((key, value) {
        alarmsMap[key] = Alarm.fromMap(key, Map<String, dynamic>.from(value));
      });
    }
    return Compartment(
      id: id,
      name: map['name'] ?? 'Unnamed',
      pillCount: map['pillCount'] ?? 0,
      alarms: alarmsMap,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> alarmsMap = {};
    alarms.forEach((key, alarm) {
      alarmsMap[key] = alarm.toMap();
    });
    return {
      'name': name,
      'pillCount': pillCount,
      'alarms': alarmsMap,
    };
  }
}
