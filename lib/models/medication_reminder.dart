class MedicationReminder {
  String medicationName;
  DateTime reminderTime;
  int dosage;
  bool isActive;

  MedicationReminder({
    required this.medicationName,
    required this.reminderTime,
    required this.dosage,
    this.isActive = true,
  });

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    return MedicationReminder(
      medicationName: map['medicationName'],
      reminderTime: DateTime.parse(map['reminderTime']),
      dosage: map['dosage'],
      isActive: map['isActive'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicationName': medicationName,
      'reminderTime': reminderTime.toIso8601String(),
      'dosage': dosage,
      'isActive': isActive,
    };
  }
}
