// lib/models/task.dart
//
// This is the DATA MODEL that Hive will store.
//
// -------------------------------------------------------------------------
// LECTURE NOTE: How Hive storage works
// -------------------------------------------------------------------------
// Hive is a lightweight, pure-Dart NoSQL database. It doesn't store rows in
// tables like SQL — it stores plain Dart OBJECTS in "Boxes" (think of a Box
// as a persistent Map<key, value> saved to disk as a binary file).
//
// Because Hive stores raw binary data (not JSON, not SQL rows), it needs to
// know exactly how to convert our Task object <-> bytes. That conversion
// logic is called a TypeAdapter, and instead of writing it by hand, we let
// code generation create it for us using annotations:
//
//   @HiveType(typeId: X)   -> marks this class as storable, gives it a
//                              unique ID so Hive can tell types apart on disk
//   @HiveField(N)          -> marks each property and assigns it a field
//                              index (used inside the binary format)
//   extends HiveObject     -> gives us convenient .save() and .delete()
//                              methods directly on the object instance
// -------------------------------------------------------------------------

import 'package:hive/hive.dart';

part 'task.g.dart'; // The generated adapter file lives here

@HiveType(typeId: 0) // typeId must be unique across ALL your Hive models
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime createdAt;

  /// Optional date/time to send a local notification reminding the user
  /// about this task. Null means "no reminder set". Nullable fields work
  /// fine with Hive/TypeAdapters — no special handling needed.
  @HiveField(4)
  DateTime? reminderTime;

  Task({
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
    this.reminderTime,
  }) : createdAt = createdAt ?? DateTime.now();
}
