import 'package:flutter/material.dart';

class MedicationCard extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final String time;

  const MedicationCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: ListTile(
        title: Text(medicationName),
        subtitle: Text('Dosage: $dosage at $time'),
      ),
    );
  }
}
