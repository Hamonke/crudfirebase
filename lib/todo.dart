//this is todo.dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';
import 'firebase_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _uuid = Uuid();

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


class TodoList extends StateNotifier<AsyncValue<List<Todo>>> {
    TodoList() : super(const AsyncValue.loading()) {
    loadTodos();
  }
    Future<void> loadTodos() async {
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
    // Step 1: Optimistic Update
    final newTodo = Todo(
      id: _uuid.v4(),// Simple unique ID generation
      description: description,
      completed: false,
    );
    state.whenData((todos) => state = AsyncValue.data([...todos, newTodo]));

    try {
      // Step 2: Perform Firebase Operation
      final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      await docRef.update({
        'todos': FieldValue.arrayUnion([newTodo.toJson()]),
      });
      // Optionally reload todos from Firebase to ensure sync
      loadTodos();
    } catch (e) {
      // Step 3: Error Handling - Revert changes if Firebase operation fails
      state.whenData((todos) => state = AsyncValue.data(todos.where((todo) => todo.id != newTodo.id).toList()));
    }
  }
}

  Future<void> toggle(String id) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Optimistic Update
    state.whenData((todos) {
      final updatedTodos = todos.map((todo) {
        if (todo.id == id) {
          return Todo(
            id: todo.id,
            description: todo.description,
            completed: !todo.completed,
          );
        }
        return todo;
      }).toList();
      state = AsyncValue.data(updatedTodos);
    });

    try {
      // Perform Firebase Operation
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
      }
    } catch (e) {
      // Error Handling: Reload todos to revert optimistic update
      loadTodos();
    }
  }
}
Future<void> edit({required String id, required String description}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Optimistic Update
    state.whenData((todos) {
      final updatedTodos = todos.map((todo) {
        if (todo.id == id) {
          return Todo(
            id: todo.id,
            description: description,
            completed: todo.completed,
          );
        }
        return todo;
      }).toList();
      state = AsyncValue.data(updatedTodos);
    });

    try {
      // Perform Firebase Operation
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
      }
    } catch (e) {
      // Error Handling: Reload todos to revert optimistic update
      loadTodos();
    }
  }
}
  Future<void> remove(Todo target) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Optimistic Update
    state.whenData((todos) {
      final updatedTodos = todos.where((todo) => todo.id != target.id).toList();
      state = AsyncValue.data(updatedTodos);
    });

    try {
      // Perform Firebase Operation
      final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      await docRef.update({
        'todos': FieldValue.arrayRemove([target.toJson()]),
      });
    } catch (e) {
      // Error Handling: Reload todos to revert optimistic update
      loadTodos();
    }
  }
}
  
   List<Todo> build() => [
         const Todo(id: 'todo-0', description: 'Buy cookies'),
         const Todo(id: 'todo-1', description: 'Star Riverpod'),
         const Todo(id: 'todo-2', description: 'Have a walk'),
       ];
}

