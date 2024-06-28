//this is main.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'toolbar.dart';
import 'singinscreen.dart';
import 'todo.dart';
import 'todoitem.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'firebase_functions.dart';
import 'todolistfilter.dart';



final addTodoKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();
final todoListProvider = StateNotifierProvider<TodoList, AsyncValue<List<Todo>>>((ref) => TodoList());
final currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
   if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  final isFirstTime = await checkIfFirstTime();
  if (isFirstTime) {
    final defaultTodos = TodoList().build();
    await createUserDocumentWithMerge(defaultTodos);
  } else {
     await loadTodosFromFirestore();
    

  }
  runApp(const ProviderScope(child: MyApp()));
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodos);
    final newTodoController = useTextEditingController();

    return GestureDetector(
      
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>   const SigningInScreen()),
            );
          },
          child: const Icon(Icons.login),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const SizedBox(height: 12.0,),
            TextField(
              key: addTodoKey,
              controller: newTodoController,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
              ),
              onSubmitted: (value) {
                ref.read(todoListProvider.notifier).add(value);
                newTodoController.clear();
              },
            ),
            const SizedBox(height: 42),
            const Toolbar(),
            if (todos.isNotEmpty) const Divider(height: 0),
            for (var i = 0; i < todos.length; i++) ...[
              if (i > 0) const Divider(height: 0),
              Dismissible(
                key: ValueKey(todos[i].id),
                onDismissed: (_) {
                  ref.read(todoListProvider.notifier).remove(todos[i]);
                },
                child: ProviderScope(
                  overrides: [
                    currentTodo.overrideWithValue(todos[i]),
                  ],
                  child: const TodoItem(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


