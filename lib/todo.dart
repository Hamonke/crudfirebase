//this is todo.dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod/riverpod.dart';
//import 'package:uuid/uuid.dart';
import 'firebase_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//const _uuid = Uuid();

/// A read-only description of a todo-item
@immutable
class Todo {
  const Todo({
    required this.description,
    required this.id,
    this.completed = false,
  });

  final String id;
  final String description;
  final bool completed;

Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'completed': completed,
    };
  }
  @override
  String toString() {
    return 'Todo(description: $description, completed: $completed)';
  }
}

/// An object that controls a list of [Todo].
class TodoList extends StateNotifier<AsyncValue<List<Todo>>> {
    TodoList() : super(const AsyncValue.loading()) {
    _loadTodos();
  }
    Future<void> _loadTodos() async {
    try {
      final todos = await loadTodosFromFirestore();
      state = AsyncValue.data(todos);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }
  Future<void> add(String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newTodo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID generation
        description: description,
        completed: false,
      );
      final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      await docRef.update({
        'todos': FieldValue.arrayUnion([newTodo.toJson()]),
      });
      _loadTodos();
    }
  }

  Future<void> toggle(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('todos')) {
        List<dynamic> todosData = docSnapshot.data()!['todos'];
        final updatedTodos = todosData.map((todoData) {
          if (todoData['id'] == id) {
            return {
              ...todoData,
              'completed': !todoData['completed'],
            };
          }
          return todoData;
        }).toList();
        await docRef.update({'todos': updatedTodos});
        _loadTodos();
      }
    }
  }

  Future<void> edit({required String id, required String description}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('todos')) {
        List<dynamic> todosData = docSnapshot.data()!['todos'];
        final updatedTodos = todosData.map((todoData) {
          if (todoData['id'] == id) {
            return {
              ...todoData,
              'description': description,
            };
          }
          return todoData;
        }).toList();
        await docRef.update({'todos': updatedTodos});
        _loadTodos();
      }
    }
  }

  Future<void> remove(Todo target) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      await docRef.update({
        'todos': FieldValue.arrayRemove([target.toJson()]),
      });
      _loadTodos();
    }
  }

  
   List<Todo> build() => [
         const Todo(id: 'todo-0', description: 'Buy cookies'),
         const Todo(id: 'todo-1', description: 'Star Riverpod'),
         const Todo(id: 'todo-2', description: 'Have a walk'),
       ];

  // void add(String description) {
  //   state = [
  //     ...state,
  //     Todo(
  //       id: _uuid.v4(),
  //       description: description,
  //     ),
  //   ];
  // }

  // void toggle(String id) {
  //   state = [
  //     for (final todo in state)
  //       if (todo.id == id)
  //         Todo(
  //           id: todo.id,
  //           completed: !todo.completed,
  //           description: todo.description,
  //         )
  //       else
  //         todo,
  //   ];
  // }

  // void edit({required String id, required String description}) {
  //   state = [
  //     for (final todo in state)
  //       if (todo.id == id)
  //         Todo(
  //           id: todo.id,
  //           completed: todo.completed,
  //           description: description,
  //         )
  //       else
  //         todo,
  //   ];
  // }

  // void remove(Todo target) {
  //   state = state.where((todo) => todo.id != target.id).toList();
  // }

}