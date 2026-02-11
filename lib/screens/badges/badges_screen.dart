import 'package:flutter/material.dart';
import '../../widgets/primary_app_bar.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Badges',
      ),
      body: const Center(
        child: Text("Coming Soon"),
      ),
    );
  }
}
