//this is todolistfilter.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'todo.dart';
import 'main.dart';

enum TodoListFilter {
  all,
  active,
  completed,
}
final todoListFilter = StateProvider((_) => TodoListFilter.all);
final uncompletedTodosCount = Provider<int>((ref) {
  return ref.watch(todoListProvider).where((todo) => !todo.completed).length;
});
final filteredTodos = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
      return todos;
  }
});
