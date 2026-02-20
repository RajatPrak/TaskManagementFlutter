import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'dio_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dio = ref.read(dioProvider);
  return TaskRepository(dio);
});

class TaskListState {
  final List<Task> tasks;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final int currentPage;
  final TaskStatus? statusFilter;
  final String searchQuery;
  final String? error;

  TaskListState({
    required this.tasks,
    required this.isLoading,
    required this.isRefreshing,
    required this.hasMore,
    required this.currentPage,
    required this.statusFilter,
    required this.searchQuery,
    this.error,
  });

  factory TaskListState.initial() => TaskListState(
    tasks: [],
    isLoading: false,
    isRefreshing: false,
    hasMore: true,
    currentPage: 1,
    statusFilter: null,
    searchQuery: '',
  );

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    int? currentPage,
    TaskStatus? statusFilter,
    String? searchQuery,
    String? error,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

class TaskListController extends StateNotifier<TaskListState> {
  final TaskRepository _repository;

  static const int _pageSize = 10;

  TaskListController(this._repository) : super(TaskListState.initial()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, currentPage: 1, error: null);
    try {
      final response = await _repository.getTasks(
        page: 1,
        limit: _pageSize,
        status: state.statusFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(
        isLoading: false,
        tasks: response.data,
        currentPage: response.page,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load tasks');
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    try {
      final response = await _repository.getTasks(
        page: 1,
        limit: _pageSize,
        status: state.statusFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(
        isRefreshing: false,
        tasks: response.data,
        currentPage: response.page,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: 'Failed to refresh tasks');
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.getTasks(
        page: nextPage,
        limit: _pageSize,
        status: state.statusFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      final newTasks = [...state.tasks, ...response.data];
      state = state.copyWith(
        isLoading: false,
        tasks: newTasks,
        currentPage: response.page,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load more tasks');
    }
  }

  Future<void> setFilter(TaskStatus? status) async {
    state = state.copyWith(statusFilter: status);
    await loadInitial();
  }

  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadInitial();
  }

  Future<void> addTask(Task task) async {
    state = state.copyWith(tasks: [task, ...state.tasks]);
  }

  Future<void> replaceTask(Task task) async {
    final index = state.tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    final tasks = [...state.tasks];
    tasks[index] = task;
    state = state.copyWith(tasks: tasks);
  }

  Future<void> removeTask(String id) async {
    final tasks = state.tasks.where((t) => t.id != id).toList();
    state = state.copyWith(tasks: tasks);
  }
}

final taskListControllerProvider =
StateNotifierProvider<TaskListController, TaskListState>((ref) {
  final repo = ref.read(taskRepositoryProvider);
  return TaskListController(repo);
});
