import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class CongratulatoryWidget extends StatelessWidget {
  final Task task;

  const CongratulatoryWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
          'build/assets/animations/success.json',
          width: 150,
          height: 150,
          repeat: false,
        ),
        const SizedBox(height: 10),
        Text(
          'Awesome job on "${task.title}"!',
          style: AppConstants.bodyTextStyle.copyWith(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
