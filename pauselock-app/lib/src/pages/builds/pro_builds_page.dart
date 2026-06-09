import 'package:flutter/material.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/widgets/common_widgets.dart';

class ProBuildsPage extends StatelessWidget {
  const ProBuildsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro Builds')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 80, color: AppTheme.accentColor),
            const SizedBox(height: 16),
            Text(
              'Pro Builds coming soon',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We are gathering the best builds from high MMR players.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
