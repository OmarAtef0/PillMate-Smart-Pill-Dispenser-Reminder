import 'package:flutter/material.dart';

class CompartmentCard extends StatelessWidget {
  final String name;
  final int pillCount;

  const CompartmentCard(
      {super.key, required this.name, required this.pillCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: ListTile(
        title: Text(name),
        subtitle: Text('Pill count: $pillCount'),
      ),
    );
  }
}
