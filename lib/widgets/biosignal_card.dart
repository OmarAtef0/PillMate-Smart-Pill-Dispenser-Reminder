import 'package:flutter/material.dart';

class BiosignalCard extends StatelessWidget {
  final String signalName;
  final int signalValue;

  const BiosignalCard(
      {super.key, required this.signalName, required this.signalValue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: ListTile(
        title: Text(signalName),
        subtitle: Text('Value: $signalValue'),
        trailing: const Icon(Icons.favorite, color: Colors.red),
      ),
    );
  }
}
