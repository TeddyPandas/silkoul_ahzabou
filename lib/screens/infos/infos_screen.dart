import 'package:flutter/material.dart';
import '../../widgets/primary_app_bar.dart';

class InfosScreen extends StatelessWidget {
  const InfosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Infos',
      ),
      body: const Center(
        child: Text("Coming Soon"),
      ),
    );
  }
}
