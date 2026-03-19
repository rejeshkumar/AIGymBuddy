import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loading.dart';

class DailyWorkoutScreen extends StatefulWidget {
  const DailyWorkoutScreen({super.key});

  @override
  State<DailyWorkoutScreen> createState() => _DailyWorkoutScreenState();
}

class _DailyWorkoutScreenState extends State<DailyWorkoutScreen> {
  Map<String, dynamic>? _workout;
  String? _error;
  bool _loading = true;
  bool _completing = false;
  bool _showSuccess = false;
  List<Map<String, dynamic>> _exerciseProgress = [];

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await ApiService().getTodayWorkoutWithError(auth.token!);
    if (!mounted) return;
    if (err != null && err.startsWith('401')) {
      await auth.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please sign in again.')),
        );
      }
      return;
    }
    setState(() {
      _loading = false;
      _workout = data;
      _error = err;
      _exerciseProgress = (data?['exercises'] as List?)
              ?.map((e) => {
                    'name': e['name'],
                    'sets': e['sets'] ?? 3,
                    'reps': e['reps'] ?? 12,
                    'completed_sets': 0,
                  })
              .toList() ??
          [];
    });
  }

  void _incrementSet(int index) {
    setState(() {
      if (index < _exerciseProgress.length) {
        final ex = _exerciseProgress[index];
        final max = ex['sets'] as int;
        if ((ex['completed_sets'] as int) < max) {
          ex['completed_sets'] = (ex['completed_sets'] as int) + 1;
        }
      }
    });
  }

  int _totalSets() {
    return _exerciseProgress.fold(0, (sum, e) => sum + (e['sets'] as int));
  }

  int _totalCompletedSets() {
    return _exerciseProgress.fold(
        0, (sum, e) => sum + (e['completed_sets'] as int));
  }

  void _decrementSet(int index) {
    setState(() {
      if (index < _exerciseProgress.length) {
        final ex = _exerciseProgress[index];
        if ((ex['completed_sets'] as int) > 0) {
          ex['completed_sets'] = (ex['completed_sets'] as int) - 1;
        }
      }
    });
  }

  Future<void> _completeWorkout() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() => _completing = true);
    final result = await ApiService().completeWorkout(
      auth.token!,
      exercises: _exerciseProgress,
    );
    if (!mounted) return;
    setState(() => _completing = false);
    if (result != null) {
      HapticFeedback.heavyImpact();
      setState(() => _showSuccess = true);
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() => _showSuccess = false);
          _loadWorkout();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const WorkoutSkeleton();
    }
    if (_workout == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Couldn\'t load workout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadWorkout,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final exercises = _workout!['exercises'] as List? ?? [];
    final goal = _workout!['goal'] ?? 'general';

    return Stack(
      children: [
        RefreshIndicator(
      onRefresh: _loadWorkout,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Workout",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${_totalCompletedSets()}/${_totalSets()} sets',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _totalSets() > 0
                          ? _totalCompletedSets() / _totalSets()
                          : 0,
                      minHeight: 8,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: ${goal.replaceAll('_', ' ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(exercises.length, (i) {
            final ex = exercises[i] as Map<String, dynamic>;
            final name = ex['name'] ?? 'Exercise';
            final sets = ex['sets'] ?? 3;
            final reps = ex['reps'] ?? 12;
            final completed = i < _exerciseProgress.length
                ? _exerciseProgress[i]['completed_sets'] as int
                : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sets sets × $reps reps',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: IconButton.filled(
                            icon: const Icon(Icons.remove, size: 24),
                            onPressed: completed > 0
                                ? () {
                                    HapticFeedback.selectionClick();
                                    _decrementSet(i);
                                  }
                                : null,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(52, 52),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$completed / $sets sets done',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: IconButton.filled(
                            icon: const Icon(Icons.add, size: 24),
                            onPressed: completed < sets
                                ? () {
                                    HapticFeedback.selectionClick();
                                    _incrementSet(i);
                                  }
                                : null,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(52, 52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _completing ? null : _completeWorkout,
            icon: _completing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_completing ? 'Completing...' : 'Complete Workout'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
        ),
        if (_showSuccess) const _SuccessOverlay(),
      ],
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: const Duration(milliseconds: 400)),
            const SizedBox(height: 24),
            Text(
              'Workout Complete!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 200))
                .slideY(begin: 0.3, end: 0),
            Text(
              'Great job! Keep it up.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400))
                .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}
