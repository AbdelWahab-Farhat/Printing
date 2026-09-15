import 'package:flutter/material.dart';

/// The screen the app opens on.
///
/// **A placeholder, and deliberately an empty one.** Nothing is drawn here that a real screen
/// will not replace: the first feature decides what a customer sees first, and a mock home
/// invented now would be a layout nobody chose that somebody later has to argue with.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دعاية')),
      body: const SizedBox.shrink(),
    );
  }
}
