import 'package:flutter/material.dart';

class TargetProgressWidget extends StatelessWidget {
  final int dailyTarget;
  final int dailyAchieved;
  final int weeklyTarget;
  final int weeklyAchieved;

  const TargetProgressWidget({
    super.key,
    required this.dailyTarget,
    required this.dailyAchieved,
    required this.weeklyTarget,
    required this.weeklyAchieved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Target: $dailyAchieved/$dailyTarget',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: dailyTarget == 0 ? 0 : dailyAchieved / dailyTarget,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
        ),
        SizedBox(height: 16),
        Text(
          'Weekly Target: $weeklyAchieved/$weeklyTarget',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: weeklyTarget == 0 ? 0 : weeklyAchieved / weeklyTarget,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
        ),
      ],
    );
  }
}
