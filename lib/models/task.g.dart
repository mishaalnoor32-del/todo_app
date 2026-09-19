// GENERATED CODE - DO NOT MODIFY BY HAND
// ---------------------------------------------------------------------
// LECTURE NOTE:
// In a real project you NEVER write this file yourself. You write
// task.dart with the @HiveType/@HiveField annotations, then run:
//
//     flutter pub run build_runner build --delete-conflicting-outputs
//
// and this file is generated automatically. It is included here, already
// written out, so the project compiles and runs immediately without
// needing internet access to fetch packages during your lecture demo.
// If you add/change fields in Task, delete this file and re-run the
// command above to regenerate it.
//
// NOTE ON BACKWARD COMPATIBILITY: `reminderTime` (field 4) was added
// after fields 0-3 already existed. The `read()` method below still
// works fine for OLD data saved before this field existed — the `fields`
// map simply won't have a key `4`, and `fields[4] as DateTime?` safely
// evaluates to null in that case, since the cast is nullable.
// ---------------------------------------------------------------------

part of 'task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      description: fields[1] as String,
      isCompleted: fields[2] as bool,
      createdAt: fields[3] as DateTime,
      reminderTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(5) // number of fields being written
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.reminderTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
