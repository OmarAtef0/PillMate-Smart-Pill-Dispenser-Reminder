import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  Future<void> updateCompartment(String compartmentId, int pillCount) async {
    await database.child('compartments/$compartmentId').update({
      'pillCount': pillCount,
    });
  }

  // Future<Map<String, dynamic>> getCompartment(String compartmentId) async {
  //   final snapshot = await database.child('compartments/$compartmentId').once();
  //   return Map<String, dynamic>.from(snapshot.value);
  // }

  Future<void> setBiosignal(String signal, int value) async {
    await database.child('biosignals/$signal').set(value);
  }

  // Future<int> getBiosignal(String signal) async {
  //   final snapshot = await database.child('biosignals/$signal').once();
  //   return (evsnapshot.value ?? 0) as int;
  // }
}
