// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../services/task_repository.dart';
import '../services/user_prefs_service.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_card.dart';
import '../widgets/task_tile.dart';
import 'profile_screen.dart';
import '../main.dart' show taskBoxName;

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final Box<Task> _box;
  late final TaskRepository _repository;
  final _prefsService = UserPrefsService();

  late final AnimationController _fabController;

  String _name = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Task>(taskBoxName);
    _repository = TaskRepository(_box);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final name = await _prefsService.getName();
    final role = await _prefsService.getRole();
    if (!mounted) return;
    setState(() {
      _name = name;
      _role = role;
    });
  }

  String get _initials {
    if (_name.trim().isEmpty) return '?';
    final parts = _name.trim().split(RegExp(r'\s+'));
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _openProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _showTaskDialog({Task? existingTask}) async {
    final titleController = TextEditingController(text: existingTask?.title);
    final descController =
        TextEditingController(text: existingTask?.description);
    DateTime? reminderTime = existingTask?.reminderTime;

    _fabController.forward();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existingTask == null ? 'New Task' : 'Edit Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: reminderTime ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (date == null || !context.mounted) return;

                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              reminderTime ?? now.add(const Duration(hours: 1))),
                        );
                        if (time == null) return;

                        setSheetState(() {
                          reminderTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm_add_rounded,
                                color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                reminderTime == null
                                    ? 'Set a reminder (optional)'
                                    : 'Remind me: ${reminderTime.toString().substring(0, 16)}',
                              ),
                            ),
                            if (reminderTime != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setSheetState(() => reminderTime = null),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        if (existingTask == null) {
                          await _repository.addTask(
                            Task(
                              title: title,
                              description: descController.text.trim(),
                              reminderTime: reminderTime,
                            ),
                          );
                        } else {
                          existingTask.title = title;
                          existingTask.description = descController.text.trim();
                          existingTask.reminderTime = reminderTime;
                          await _repository.updateTask(existingTask);
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save Task'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    _fabController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<Box<Task>>(
          valueListenable: _box.listenable(),
          builder: (context, box, _) {
            final tasks = box.values.toList().cast<Task>()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final total = tasks.length;
            final completed = tasks.where((t) => t.isCompleted).length;
            final pending = total - completed;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _openProfile,
                        child: Hero(
                          tag: 'profile-avatar',
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $_name',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _role,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onToggleTheme,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Icon(
                            widget.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            key: ValueKey(widget.isDarkMode),
                          ),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ProgressCard(
                    pendingCount: pending,
                    completedCount: completed,
                    totalCount: total,
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Your Tasks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: tasks.isEmpty
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: const _EmptyState(),
                    secondChild: Column(
                      children: [
                        for (final task in tasks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(task.key),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _repository.deleteTask(task),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white),
                              ),
                              child: TaskTile(
                                task: task,
                                onToggle: (value) async {
                                  if (value == null) return;
                                  task.isCompleted = value;
                                  await _repository.updateTask(task);
                                },
                                onDelete: () => _repository.deleteTask(task),
                                onEdit: () =>
                                    _showTaskDialog(existingTask: task),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.125).animate(_fabController),
          child: const Icon(Icons.add),
        ),
        label: const Text('Add Task'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_add_check_rounded,
                size: 48,
                color: AppTheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All clear! Add a task to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}