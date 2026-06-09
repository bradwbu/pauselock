import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';

class ProBuildsPage extends StatefulWidget {
  const ProBuildsPage({super.key});

  @override
  State<ProBuildsPage> createState() => _ProBuildsPageState();
}

class _ProBuildsPageState extends State<ProBuildsPage> {
  bool _isLoading = true;
  List<dynamic> _builds = [];

  @override
  void initState() {
    super.initState();
    _fetchProBuilds();
  }

  Future<void> _fetchProBuilds() async {
    final builds = await PauselockClient.getFeaturedBuilds(limit: 20);
    if (mounted) {
      setState(() {
        _builds = builds ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Builds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchProBuilds();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _builds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 80, color: AppTheme.accentColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text("No pro builds available at this time.", style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _builds.length,
                  itemBuilder: (context, index) {
                    final b = _builds[index];
                    final heroId = b['heroId'] ?? 0;
                    final buildName = b['buildName'] ?? 'Unknown Build';
                    final author = b['authorName'] ?? 'Pro Player';
                    final winRate = b['winRate'] ?? 0.0;
                    final matches = b['matchesPlayed'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/build/${b['id']}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.secondaryColor, width: 2),
                                  image: DecorationImage(
                                    image: NetworkImage('https://assets.deadlock-api.com/images/heroes/$heroId.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Fallback if image fails to load
                                child: Image.network(
                                  'https://assets.deadlock-api.com/images/heroes/$heroId.png',
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white54),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      buildName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified, color: AppTheme.accentColor, size: 14),
                                        const SizedBox(width: 4),
                                        Text('By $author', style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${winRate.toStringAsFixed(1)}% WR', style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                                  Text('$matches Matches', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.chevron_right, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
