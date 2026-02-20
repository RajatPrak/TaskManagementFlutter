import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../providers/auth_providers.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import 'edit_task_screen.dart';
import 'login_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  static const routeName = '/tasks';

  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(taskListControllerProvider);
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoading) {
      ref.read(taskListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(taskListControllerProvider.notifier).refresh();
  }

  Future<void> _onLogout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  void _onFilterChanged(TaskStatus? status) {
    ref.read(taskListControllerProvider.notifier).setFilter(status);
  }

  void _onSearchChanged(String value) {
    ref.read(taskListControllerProvider.notifier).setSearchQuery(value.trim());
  }

  void _openEdit(Task? task) {
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: task),
      ),
    )
        .then((changed) {
      if (changed == true) {
        // already updated via controller; just show maybe
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(taskListControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (authState.user != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hello, ${authState.user!.name ?? authState.user!.email}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search by title',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: tasksState.statusFilter == null,
                    onSelected: (_) => _onFilterChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Pending'),
                    selected: tasksState.statusFilter == TaskStatus.pending,
                    onSelected: (_) => _onFilterChanged(TaskStatus.pending),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Ongoing'),
                    selected: tasksState.statusFilter == TaskStatus.ongoing,
                    onSelected: (_) => _onFilterChanged(TaskStatus.ongoing),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Completed'),
                    selected: tasksState.statusFilter == TaskStatus.completed,
                    onSelected: (_) => _onFilterChanged(TaskStatus.completed),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: tasksState.tasks.isEmpty && !tasksState.isLoading
                  ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No tasks yet. Add one!')),
                ],
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: tasksState.tasks.length +
                    (tasksState.isLoading && tasksState.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= tasksState.tasks.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final task = tasksState.tasks[index];

                  return TaskListItem(
                    task: task,
                    onToggle: () async {
                      try {
                        final repo = ref.read(taskRepositoryProvider);
                        final updated = await repo.toggleTask(task.id);
                        await ref
                            .read(taskListControllerProvider.notifier)
                            .replaceTask(updated);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to toggle task'),
                          ),
                        );
                      }
                    },
                    onEdit: () => _openEdit(task),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text(
                              'Are you sure you want to delete this task?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;

                      try {
                        final repo = ref.read(taskRepositoryProvider);
                        await repo.deleteTask(task.id);
                        await ref
                            .read(taskListControllerProvider.notifier)
                            .removeTask(task.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task deleted'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete task'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
