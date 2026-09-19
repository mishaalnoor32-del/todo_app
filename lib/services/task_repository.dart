// lib/services/task_repository.dart
//
// Wraps the Hive Box with clean CRUD methods, and now also keeps each
// task's reminder notification in sync with its data — this is the ONE
// place that decides "should this task have a scheduled notification
// right now?", so the UI layer never has to think about notifications
// directly.

import 'package:hive/hive.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskRepository {
  final Box<Task> _box;
  final NotificationService _notifications = NotificationService();

  TaskRepository(this._box);

  List<Task> getAllTasks() {
    return _box.values.toList().cast<Task>();
  }

  /// Adds a new task. Hive assigns it an auto-incrementing key, which we
  /// then reuse as the notification id.
  Future<void> addTask(Task task) async {
    await _box.add(task);
    await _syncReminder(task);
  }

  Future<void> updateTask(Task task) async {
    await task.save();
    await _syncReminder(task);
  }

  Future<void> deleteTask(Task task) async {
    final id = task.key as int?;
    await task.delete();
    if (id != null) await _notifications.cancelReminder(id);
  }

  Future<void> toggleComplete(Task task) async {
    task.isCompleted = !task.isCompleted;
    await task.save();
    await _syncReminder(task);
  }

  /// Schedules or cancels the task's reminder notification based on its
  /// current reminderTime and completion state:
  /// - No reminderTime set -> no notification.
  /// - Task marked complete -> cancel any pending notification.
  /// - Otherwise -> (re)schedule for reminderTime.
  Future<void> _syncReminder(Task task) async {
    final id = task.key as int?;
    if (id == null) return; // not yet persisted, shouldn't happen here

    if (task.reminderTime == null || task.isCompleted) {
      await _notifications.cancelReminder(id);
      return;
    }

    await _notifications.scheduleReminder(
      id: id,
      title: 'Task Reminder',
      body: task.title,
      scheduledTime: task.reminderTime!,
    );
  }
}
