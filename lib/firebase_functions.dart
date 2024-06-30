//this is firebase_functions.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'todo.dart';

Future<void> createUserDocumentWithMerge(List<Todo> todos) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final usersCollection = FirebaseFirestore.instance.collection('Users');
    final todosData = [
      {'description': 'Buy cookies', 'id': 'todo-0', 'completed': false},
      {'description': 'Star Riverpod', 'id': 'todo-1', 'completed': false},
      {'description': 'Have a walk', 'id': 'todo-2', 'completed': false},
    ];
    await usersCollection.doc(user.uid).set({
      'todos': todosData,
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));
  }
}



Future<List<Todo>> loadTodosFromFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) { // Removed the check for !user.isAnonymous
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (docSnapshot.exists && docSnapshot.data()!.containsKey('todos')) {
      List<dynamic> todosData = docSnapshot.data()!['todos'];
      return todosData.map((todoData) => Todo(
        id: todoData['id'],
        description: todoData['description'],
        completed: todoData['completed'],
      )).toList();
    }
  }
  return [];
}
Future<bool> checkIfFirstTime() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && !user.isAnonymous) {
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    return !docSnapshot.exists;
  }
  return true; 
}

