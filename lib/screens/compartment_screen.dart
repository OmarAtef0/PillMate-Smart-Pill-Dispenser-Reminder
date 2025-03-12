// lib/screens/compartment_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'compartment_details_screen.dart'; // Ensure this screen is created

class CompartmentScreen extends StatefulWidget {
  const CompartmentScreen({super.key});
  @override
  _CompartmentScreenState createState() => _CompartmentScreenState();
}

class _CompartmentScreenState extends State<CompartmentScreen> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> compartments = {};

  @override
  void initState() {
    super.initState();
    _fetchCompartments();
  }

  /// Recursively casts a Map with dynamic keys and values to a Map with String keys and dynamic values.
  Map<String, dynamic> _castMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> result = {};
    map.forEach((key, value) {
      String newKey = key.toString();
      if (value is Map<dynamic, dynamic>) {
        result[newKey] = _castMap(value);
      } else {
        result[newKey] = value;
      }
    });
    return result;
  }

  /// Fetches compartments from Firebase Realtime Database
  void _fetchCompartments() {
    database.child('compartments').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map<dynamic, dynamic>) {
        // Use the helper function to cast the map
        Map<String, dynamic> compartmentMap = _castMap(data);

        setState(() {
          compartments = compartmentMap;
        });
      } else {
        // Handle unexpected data types
        setState(() {
          compartments = {};
        });
      }
    });
  }

  /// Adds a new compartment to Firebase Realtime Database
  Future<void> _addCompartment(String name, int pillCount) async {
    final newCompartmentRef = database.child('compartments').push();
    await newCompartmentRef.set({
      'name': name,
      'pillCount': pillCount,
      'alarms': {},
    });
  }

  /// Deletes a compartment from Firebase Realtime Database
  Future<void> _deleteCompartment(String compartmentId) async {
    await database.child('compartments/$compartmentId').remove();
  }

  /// Displays a dialog to add a new compartment
  Future<void> _showAddCompartmentDialog() async {
    final _nameController = TextEditingController();
    final _pillCountController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Compartment'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Compartment Name'),
                ),
                TextField(
                  controller: _pillCountController,
                  decoration:
                      const InputDecoration(labelText: 'Initial Pill Count'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = _nameController.text.trim();
                int pillCount =
                    int.tryParse(_pillCountController.text.trim()) ?? 0;

                if (name.isNotEmpty && pillCount > 0) {
                  await _addCompartment(name, pillCount);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show error message if inputs are invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter valid details.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a confirmation dialog before deleting a compartment
  Future<void> _confirmDeleteCompartment(
      String compartmentId, String compartmentName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Compartment'),
          content: Text('Are you sure you want to delete "$compartmentName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Do not delete
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm delete
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteCompartment(compartmentId);
      // show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Compartment "$compartmentName" deleted successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If compartments are loading, show a loading indicator
    if (compartments.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compartment Management'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Sort compartment keys to ensure new compartments are at the end
    List<String> sortedCompartmentKeys = compartments.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartment Management'),
      ),
      body: ListView.builder(
        itemCount: sortedCompartmentKeys.length,
        itemBuilder: (context, index) {
          String compartmentId = sortedCompartmentKeys[index];
          var compartment = compartments[compartmentId];

          String compartmentName = compartment['name'] ?? 'Unnamed';
          int pillCount = compartment['pillCount'] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(compartmentName),
            subtitle: Text('Pills: $pillCount'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompartmentDetailsScreen(
                    compartmentId: compartmentId,
                    compartmentData: compartment,
                  ),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _confirmDeleteCompartment(compartmentId, compartmentName);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCompartmentDialog,
        tooltip: 'Add Compartment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
