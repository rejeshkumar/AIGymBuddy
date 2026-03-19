import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loading.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic>? _history;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() => _loading = true);
    final stats = await ApiService().getWorkoutStats(auth.token!);
    final history = await ApiService().getWorkoutHistory(auth.token!);
    setState(() {
      _loading = false;
      _stats = stats;
      _history = history ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ProgressSkeleton();
    }

    final total = _stats?['total_workouts'] ?? 0;
    final streak = _stats?['current_streak'] ?? 0;
    final longest = _stats?['longest_streak'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.fitness_center,
                  label: 'Total Workouts',
                  value: total.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Current Streak',
                  value: '$streak days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.emoji_events,
            label: 'Longest Streak',
            value: '$longest days',
          ),
          const SizedBox(height: 24),
          Text(
            'Recent History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (_history == null || _history!.isEmpty)
            EmptyState(
              icon: Icons.fitness_center,
              title: 'No workouts yet',
              message: 'Complete your first workout to see your progress here. Go to Home to get started.',
            )
          else
            ...(_history!.map((w) {
              final id = w['id'];
              final completedAt = w['completed_at'] as String?;
              final exercises = w['exercises'] as List? ?? [];
              final dateStr = app_date_utils.formatWorkoutDate(completedAt);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text('Workout #$id'),
                  subtitle: Text(
                    '$dateStr • ${exercises.length} exercises',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              );
            })),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
