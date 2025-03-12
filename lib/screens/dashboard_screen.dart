// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _troponinController = TextEditingController();
  final TextEditingController _ckmbController = TextEditingController();

  bool _isLoading = false;
  String _resultMessage = "";
  Color _resultColor = Colors.black;

  // Reference to the root of the Firebase Realtime Database
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // This method handles classification logic
  Future<void> _classify() async {
    setState(() {
      _isLoading = true;
      _resultMessage = "";
      _resultColor = Colors.black;
    });

    try {
      await _database
          .child('troponin')
          .set(double.parse(_troponinController.text));
      await _database.child('cm').set(double.parse(_ckmbController.text));

      // Simulate waiting for data to be processed
      await Future.delayed(const Duration(seconds: 2));

      // Read the prediction result from Firebase
      final predictionSnapshot =
          await _database.child('results/prediction').get();

      // Reset Troponin and CK-MB values (and prediction) in Firebase (optional)
      await _database.child('troponin').set(0);
      await _database.child('cm').set(0);
      await _database.child('results/prediction').set(0);

      if (predictionSnapshot.exists) {
        int prediction = predictionSnapshot.value as int;
        setState(() {
          _resultMessage = prediction == 1
              ? "User has a heart attack."
              : "User does not have a heart attack.";
          _resultColor = prediction == 1 ? Colors.red : Colors.green;
        });
      } else {
        setState(() {
          _resultMessage = "Prediction data not available.";
          _resultColor = Colors.black;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = "Error fetching prediction: $e";
        _resultColor = Colors.black;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1) StreamBuilder to display real-time heart rate from Firebase
              StreamBuilder<DatabaseEvent>(
                // Listen to the 'heartrate' child in the database
                stream: _database.child('heartrate').onValue,
                builder: (context, snapshot) {
                  // Check if there's data and it's not null
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final heartrateValue = snapshot.data!.snapshot.value;
                    return Text(
                      'Heart Rate: $heartrateValue',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Text(
                      'Error retrieving heart rate',
                      style: TextStyle(color: Colors.red),
                    );
                  } else {
                    // If no data, show some placeholder text
                    return const Text(
                      'Heart Rate: --',
                      style: TextStyle(fontSize: 18),
                    );
                  }
                },
              ),

              const SizedBox(height: 16.0),

              // 2) Troponin field
              TextFormField(
                controller: _troponinController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Troponin (μg/L)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Troponin level';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16.0),

              // 3) cm field
              TextFormField(
                controller: _ckmbController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'CK-MB (μg/L)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter CK-MB level';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24.0),

              // 4) Classify button
              ElevatedButton(
                onPressed: _isLoading ? null : _classify,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Classify'),
              ),

              const SizedBox(height: 24.0),

              // 5) Display classification result message
              if (_resultMessage.isNotEmpty)
                Text(
                  _resultMessage,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: _resultColor,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
