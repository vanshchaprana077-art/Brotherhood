import 'package:flutter/material.dart';

class WeeklyProgressScreen extends StatelessWidget {
  const WeeklyProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Progress'),
      ),
      body: const Center(
        child: Text(
          'Weekly Progress',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}