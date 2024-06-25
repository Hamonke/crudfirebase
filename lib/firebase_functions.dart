//this is firebase_functions.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'todo.dart';

Future<void> createUserDocumentWithMerge(List<Todo> todos) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final usersCollection = FirebaseFirestore.instance.collection('Users');
    final todosData = todos.map((todo) => {
      'description': todo.description,
      'id': todo.id,
      'completed': todo.completed,
    }).toList();
    await usersCollection.doc(user.uid).set({
      'todos': todosData,
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));
  }
}

Future<void> checkAndInitializeTodos(String userId) async {
  final todosCollection = FirebaseFirestore.instance.collection('todos');
  final userTodosSnapshot = await todosCollection.doc(userId).get();

  if (!userTodosSnapshot.exists) {
    // Initialize with default todos
    final defaultTodos = TodoList().build();
    for (final todo in defaultTodos) {
      todosCollection.doc(userId).collection('userTodos').add({
        'id': todo.id,
        'description': todo.description,
        'completed': todo.completed,
      });
    }
  }
}


//for some reason when user is anonymous it is not able to load the todos from firestore
Future<List<Todo>> loadTodosFromFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && !user.isAnonymous) {
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