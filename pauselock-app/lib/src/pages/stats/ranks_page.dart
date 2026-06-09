import 'package:flutter/material.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/widgets/common_widgets.dart';

class RanksPage extends StatelessWidget {
  const RanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MMR Ranks')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Ranks coming soon',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We are currently tracking MMR distribution data.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
