import 'package:flutter/material.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet'),
      ),
      body: const Center(
        child: Text(
          'Diet Plan Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}