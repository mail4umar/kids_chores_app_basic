import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(Task, bool) onTaskCompletionChanged;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTaskCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          task.iconName != null &&
                  AppConstants.choreIcons.containsKey(task.iconName)
              ? Icon(
                AppConstants.choreIcons[task.iconName],
                color: AppConstants.primaryPink,
              )
              : const Icon(Icons.task, color: AppConstants.primaryPink),
      title: Text(task.title, style: AppConstants.bodyTextStyle),
      trailing: Checkbox(
        value: task.isCompleted,
        onChanged: (value) {
          if (value != null) {
            onTaskCompletionChanged(task, value);
          }
        },
        activeColor: AppConstants.primaryPink,
      ),
    );
  }
}
