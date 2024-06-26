//this is todolistfilter.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'todo.dart';
import 'main.dart';

enum TodoListFilter {
  all,
  active,
  completed,
}
final uncompletedTodosCount = Provider<int>((ref) {
  final todoListAsyncValue = ref.watch(todoListProvider);
  // Check if the AsyncValue contains data and then access it
  if (todoListAsyncValue is AsyncData<List<Todo>>) {
    return todoListAsyncValue.value.where((todo) => !todo.completed).length;
  }
  // Return 0 or an appropriate default value if there's no data
  return 0;
});
final todoListFilter = StateProvider((_) => TodoListFilter.all);

final filteredTodos = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todoListAsyncValue = ref.watch(todoListProvider);

  // Check if the AsyncValue contains data and then access it
  if (todoListAsyncValue is AsyncData<List<Todo>>) {
    final todos = todoListAsyncValue.value;


    switch (filter) {
      case TodoListFilter.completed:
        return todos.where((todo) => todo.completed).toList();
      case TodoListFilter.active:
        return todos.where((todo) => !todo.completed).toList();
      case TodoListFilter.all:
      default:
        return todos;
    }
  }
  // Return an empty list or an appropriate default value if there's no data
  return [];
});
