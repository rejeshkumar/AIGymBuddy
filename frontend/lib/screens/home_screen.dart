import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/activity_ring.dart';
import 'daily_workout_screen.dart';

/// Apple Fitness-style home: activity rings, summary, today's workout.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _workout;
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
    final workout = await ApiService().getTodayWorkout(auth.token!);
    if (mounted) {
      setState(() {
        _loading = false;
        _stats = stats;
        _workout = workout;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthProvider>();
    final email = auth.user?['email'] ?? '';
    final name = email.isNotEmpty ? email.split('@').first : 'there';

    return RefreshIndicator(
      onRefresh: _load,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greeting()}, ${_capitalize(name)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            _buildSummarySection(theme),
            const SizedBox(height: 32),
            _buildTodaysWorkout(theme),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _buildSummarySection(ThemeData theme) {
    if (_loading) {
      return _buildSummarySkeleton(theme);
    }

    final total = (_stats?['total_workouts'] ?? 0) as int;
    final streak = (_stats?['longest_streak'] ?? 0) as int;
    final currentStreak = (_stats?['current_streak'] ?? 0) as int;

    // Normalize for rings: workouts (goal 10), streak (goal 7), today (0 or 1)
    final moveProgress = (total / 10).clamp(0.0, 1.0);
    final exerciseProgress = (currentStreak / 7).clamp(0.0, 1.0);
    final hasWorkout = _workout != null &&
        (_workout!['exercises'] as List?)?.isNotEmpty == true;
    final standProgress = hasWorkout ? 0.5 : 0.0; // partial if workout available

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ActivityRings(
            moveProgress: moveProgress,
            exerciseProgress: exerciseProgress,
            standProgress: standProgress,
            size: 160,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RingLegend(
              color: const Color(0xFFFA114F),
              label: 'Workouts',
              value: '$total',
            ),
            _RingLegend(
              color: const Color(0xFF30D158),
              label: 'Streak',
              value: '$currentStreak days',
            ),
            _RingLegend(
              color: const Color(0xFF64D2FF),
              label: 'Today',
              value: hasWorkout ? 'Ready' : '—',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySkeleton(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysWorkout(ThemeData theme) {
    final hasWorkout = _workout != null &&
        (_workout!['exercises'] as List?)?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Workout",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text("Today's Workout"),
                      leading: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    body: const DailyWorkoutScreen(),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasWorkout ? "Today's Workout" : 'Get Started',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasWorkout
                              ? 'Tap to view and complete'
                              : 'Complete your first workout',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _RingLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
