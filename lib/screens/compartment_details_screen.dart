// lib/screens/compartment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/notification_service.dart'; // Corrected Import

class CompartmentDetailsScreen extends StatefulWidget {
  final String compartmentId;
  final Map<String, dynamic> compartmentData;

  const CompartmentDetailsScreen({
    super.key,
    required this.compartmentId,
    required this.compartmentData,
  });

  @override
  _CompartmentDetailsScreenState createState() =>
      _CompartmentDetailsScreenState();
}

class _CompartmentDetailsScreenState extends State<CompartmentDetailsScreen> {
  final database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> alarms = {};

  late String name;
  late int pillCount;

  @override
  void initState() {
    super.initState();
    name = widget.compartmentData['name'];
    pillCount = widget.compartmentData['pillCount'];
    alarms = widget.compartmentData['alarms'] != null
        ? Map<String, dynamic>.from(widget.compartmentData['alarms'])
        : {};
    _fetchAlarms();
    _listenForIrChanges();
  }

  void _listenForIrChanges() {
    database.child('ir').onValue.listen((event) {
      final irValue = event.snapshot.value;
      if (irValue == 1) {
        // Show local notification
        NotificationService.instance.showImmediateNotification(
          id: 9999, // Unique ID for this type of notification
          title: 'Low Pill Count Alert',
          body: 'Your pills are running low. Please refill.',
        );
      }
    });
  }

  void dispensePills(int pillCount) async {
    for (int i = 0; i < pillCount; i++) {
      // Update the servo value to 1 to dispense one pill
      await database.child('servo').set(1);

      // Wait for 2 seconds to allow the servo to reset
      await Future.delayed(const Duration(seconds: 4));

      // Show a confirmation message after all pills are dispensed
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('One Pill dispensed successfully!')),
      // );
    }
  }

  void _fetchAlarms() {
    database
        .child('compartments/${widget.compartmentId}/alarms')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        Map<String, dynamic> alarmMap = _castMap(data);
        setState(() {
          alarms = alarmMap;
        });

        alarmMap.forEach((alarmId, alarmData) {
          if (alarmData is Map<String, dynamic>) {
            String timeStr = alarmData['time'];
            List<dynamic> repeatDaysDynamic = alarmData['repeatDays'] ?? [];
            List<String> repeatDays =
                repeatDaysDynamic.map((day) => day.toString()).toList();

            TimeOfDay time = _parseTime(timeStr);

            // Schedule notifications and pill dispensing
            NotificationService.instance.scheduleNotification(
              id: alarmId.hashCode,
              title: 'Medication Reminder',
              body: 'Time to take your medication.',
              time: time,
              repeatDays: repeatDays,
              compartmentId: widget.compartmentId,
              alarmId: alarmId,
              onTrigger: () async {
                dispensePills(widget.compartmentData['pillCount']);
                return;
              },
            );
          }
        });
      } else {
        setState(() {
          alarms = {};
        });
      }
    });
  }

  /// Casts a Map with dynamic keys and values to a Map with String keys and dynamic values.
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

  void _updateCompartment(String name, int pillCount) {
    database.child('compartments/${widget.compartmentId}').update({
      'name': name,
      'pillCount': pillCount,
    });
  }

  void _updateAlarm(String alarmId, TimeOfDay time, List<String> repeatDays) {
    database
        .child('compartments/${widget.compartmentId}/alarms/$alarmId')
        .update({
      'time': _formatTimeOfDay(time),
      'repeatDays': repeatDays,
    }).then((_) {
      // Cancel existing notifications
      NotificationService.instance.cancelNotification(
        alarmId: alarmId,
        repeatDays: repeatDays,
        time: time,
      );

      // Schedule updated notifications
      NotificationService.instance.scheduleNotification(
        id: alarmId.hashCode, // Generate a unique ID based on alarmId
        title: 'Medication Reminder',
        body: 'Time to take your medication.',
        time: time,
        repeatDays: repeatDays,
        compartmentId: widget.compartmentId,
        alarmId: alarmId,
        onTrigger: () async {
          dispensePills(widget.compartmentData['pillCount']);
          return;
        },
      );
    }).catchError((error) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update alarm: $error')),
      );
    });
  }

  void _deleteAlarm(String alarmId) {
    // Retrieve alarm data to get repeatDays and time before deletion
    database
        .child('compartments/${widget.compartmentId}/alarms/$alarmId')
        .once()
        .then((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        String timeStr = data['time'];
        List<dynamic> repeatDaysDynamic = data['repeatDays'] ?? [];
        List<String> repeatDays =
            repeatDaysDynamic.map((day) => day.toString()).toList();
        TimeOfDay time = _parseTime(timeStr);

        // Cancel the notifications associated with this alarm
        NotificationService.instance.cancelNotification(
          alarmId: alarmId,
          repeatDays: repeatDays,
          time: time,
        );
      }
    }).catchError((error) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to retrieve alarm data: $error')),
      );
    }).then((_) {
      // Proceed to delete the alarm from Firebase
      database
          .child('compartments/${widget.compartmentId}/alarms/$alarmId')
          .remove()
          .then((_) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm deleted successfully')),
        );
      }).catchError((error) {
        // Handle errors if any
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete alarm: $error')),
        );
      });
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hm().format(dt); // "HH:mm" format
  }

  TimeOfDay _parseTime(String timeStr) {
    final format = DateFormat.Hm();
    final dt = format.parse(timeStr);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  Future<void> _showAddAlarmDialog() async {
    TimeOfDay? selectedTime = TimeOfDay.now();
    List<String> selectedDays = [];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Alarm'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          dialogSetState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child:
                          Text(selectedTime?.format(context) ?? 'Select Time'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Repeat Days'),
                    Wrap(
                      spacing: 10.0,
                      children: [
                        _buildDayChip('Sun', selectedDays, dialogSetState),
                        _buildDayChip('Mon', selectedDays, dialogSetState),
                        _buildDayChip('Tue', selectedDays, dialogSetState),
                        _buildDayChip('Wed', selectedDays, dialogSetState),
                        _buildDayChip('Thu', selectedDays, dialogSetState),
                        _buildDayChip('Fri', selectedDays, dialogSetState),
                        _buildDayChip('Sat', selectedDays, dialogSetState),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTime != null && selectedDays.isNotEmpty) {
                  _addAlarm(selectedTime!, selectedDays);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select time and days')),
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

  Future<void> _showEditCompartmentDialog() async {
    final _nameController = TextEditingController(text: name);
    final _pillCountController =
        TextEditingController(text: pillCount.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Compartment'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _pillCountController,
                  decoration: const InputDecoration(labelText: 'Pill Count'),
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
              onPressed: () {
                String newName = _nameController.text.trim();
                int newPillCount =
                    int.tryParse(_pillCountController.text.trim()) ?? pillCount;

                if (newName.isNotEmpty) {
                  _updateCompartment(newName, newPillCount);
                  setState(() {
                    name = newName;
                    pillCount = newPillCount;
                  });
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayChip(
      String day, List<String> selectedDays, StateSetter dialogSetState) {
    bool isSelected = selectedDays.contains(day);
    return ChoiceChip(
      label: Text(day),
      selected: isSelected,
      onSelected: (selected) {
        dialogSetState(() {
          if (selected) {
            selectedDays.add(day);
          } else {
            selectedDays.remove(day);
          }
        });
      },
    );
  }

  void _addAlarm(TimeOfDay time, List<String> repeatDays) {
    final String alarmId = database
        .child('compartments/${widget.compartmentId}/alarms')
        .push()
        .key!;

    final Map<String, dynamic> newAlarmData = {
      'time': _formatTimeOfDay(time),
      'repeatDays': repeatDays,
    };

    database
        .child('compartments/${widget.compartmentId}/alarms/$alarmId')
        .set(newAlarmData)
        .then((_) {
      // Schedule the notification for the new alarm
      NotificationService.instance.scheduleNotification(
        id: alarmId.hashCode,
        title: 'Medication Reminder',
        body: 'Time to take your medication.',
        time: time,
        repeatDays: repeatDays,
        compartmentId: widget.compartmentId,
        alarmId: alarmId,
        onTrigger: () async {
          dispensePills(widget.compartmentData['pillCount']);
          return;
        },
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm added successfully!')),
      );
    }).catchError((error) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add alarm: $error')),
      );
    });
  }

  Future<void> _showEditAlarmDialog(
      String alarmId, Map<String, dynamic> alarm) async {
    TimeOfDay? selectedTime = _parseTime(alarm['time']);
    List<String> selectedDays = List<String>.from(alarm['repeatDays'] ?? []);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Alarm'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          dialogSetState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Text(selectedTime == null
                          ? 'Select Time'
                          : selectedTime!.format(context)),
                    ),
                    const SizedBox(height: 10),
                    const Text('Repeat Days'),
                    Wrap(
                      spacing: 10.0,
                      children: [
                        _buildDayChip('Sun', selectedDays, dialogSetState),
                        _buildDayChip('Mon', selectedDays, dialogSetState),
                        _buildDayChip('Tue', selectedDays, dialogSetState),
                        _buildDayChip('Wed', selectedDays, dialogSetState),
                        _buildDayChip('Thu', selectedDays, dialogSetState),
                        _buildDayChip('Fri', selectedDays, dialogSetState),
                        _buildDayChip('Sat', selectedDays, dialogSetState),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTime != null && selectedDays.isNotEmpty) {
                  _updateAlarm(alarmId, selectedTime!, selectedDays);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select time and days')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditCompartmentDialog();
            },
            tooltip: 'Edit Compartment',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Pill Count'),
              subtitle: Text('$pillCount'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alarms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddAlarmDialog,
                  tooltip: 'Add Alarm',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: alarms.isEmpty
                  ? const Center(child: Text('No alarms set.'))
                  : ListView.builder(
                      itemCount: alarms.length,
                      itemBuilder: (context, index) {
                        String alarmId = alarms.keys.elementAt(index);
                        var alarm = alarms[alarmId];
                        if (alarm is Map<String, dynamic>) {
                          return ListTile(
                            leading: const Icon(Icons.alarm),
                            title: Text(alarm['time']),
                            subtitle: Text(
                                'Repeat: ${(alarm['repeatDays'] as List<dynamic>).join(', ')}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteAlarm(alarmId);
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
