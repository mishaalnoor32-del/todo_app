import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final Function(bool?) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext me) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: widget.task.isCompleted,
                  onChanged: widget.onToggle,
                ),
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: widget.task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                // Edit Icon
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: widget.onEdit,
                  tooltip: 'Edit Task',
                ),
                // Visible Delete Icon for Desktop/Laptop Web
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Task',
                ),
                // Expand Toggle Arrow
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            if (_isExpanded) ...[
              const Divider(),
              if (widget.task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    widget.task.description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              if (widget.task.reminderTime != null)
                Row(
                  children: [
                    const Icon(Icons.alarm, size: 16, color: Colors.purpleAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Reminder: ${widget.task.reminderTime.toString()}',
                      style: const TextStyle(fontSize: 12, color: Colors.purpleAccent),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}