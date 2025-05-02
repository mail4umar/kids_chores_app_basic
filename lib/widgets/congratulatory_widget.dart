import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class CongratulatoryWidget extends StatelessWidget {
  final Task task;
  final String message;

  const CongratulatoryWidget({
    super.key,
    required this.task,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Icons.celebration,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Congratulations text
          Text(
            'Goal Completed!',
            style: AppConstants.subheadingTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Message
          Text(
            message,
            style: AppConstants.bodyTextStyle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Task name
          Text(
            'You finished "${task.title}"',
            style: AppConstants.bodyTextStyle.copyWith(
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Confetti decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                color: [
                  Colors.amber,
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                ][index],
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Close button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Yay!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
