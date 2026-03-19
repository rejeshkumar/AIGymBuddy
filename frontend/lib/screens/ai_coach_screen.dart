import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// AI Coach - workout tips, form advice, and personalized suggestions.
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _tipCategories = [
    _TipCategory(
      icon: Icons.fitness_center,
      title: 'Form & Technique',
      tips: [
        'Keep your core engaged during all lifts to protect your spine.',
        'Control the eccentric (lowering) phase – aim for 2-3 seconds.',
        'Breathe out on the effort, in on the return.',
        'Warm up with 5-10 min light cardio before lifting.',
      ],
    ),
    _TipCategory(
      icon: Icons.restaurant,
      title: 'Nutrition',
      tips: [
        'Eat protein within 2 hours post-workout for muscle repair.',
        'Stay hydrated – aim for 8+ glasses of water daily.',
        'Balance macros: protein, carbs, and healthy fats.',
        'Pre-workout: light carbs 30-60 min before for energy.',
      ],
    ),
    _TipCategory(
      icon: Icons.bedtime,
      title: 'Recovery',
      tips: [
        'Sleep 7-9 hours for optimal muscle growth and recovery.',
        'Take rest days – muscles grow when you rest.',
        'Stretch after workouts to improve flexibility.',
        'Consider foam rolling for muscle recovery.',
      ],
    ),
    _TipCategory(
      icon: Icons.psychology,
      title: 'Mindset',
      tips: [
        'Progress over perfection – consistency beats intensity.',
        'Track your workouts to see progress over time.',
        'Set small, achievable goals each week.',
        'Celebrate wins – every workout counts!',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = context.watch<AuthProvider>().user?['goal'] ?? 'general';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Coach',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your personal fitness guide',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (goal != 'general') ...[
          _SuggestionCard(
            title: 'Goal: ${goal.replaceAll('_', ' ')}',
            suggestion: _getGoalSuggestion(goal),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Tips & Advice',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._tipCategories.map((cat) => _TipCategoryCard(category: cat)),
      ],
    );
  }

  String _getGoalSuggestion(String goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Focus on compound movements and higher reps (12-15). Add 2-3 cardio sessions per week. Maintain a slight calorie deficit.';
      case 'muscle_gain':
        return 'Prioritize progressive overload. Aim for 8-12 reps per set. Eat in a calorie surplus with adequate protein (1.6g per kg bodyweight).';
      default:
        return 'Mix strength and cardio. Aim for 3-4 workouts per week with variety.';
    }
  }
}

class _TipCategory {
  final IconData icon;
  final String title;
  final List<String> tips;

  _TipCategory({required this.icon, required this.title, required this.tips});
}

class _TipCategoryCard extends StatefulWidget {
  final _TipCategory category;

  const _TipCategoryCard({required this.category});

  @override
  State<_TipCategoryCard> createState() => _TipCategoryCardState();
}

class _TipCategoryCardState extends State<_TipCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.category.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.category.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                ...widget.category.tips.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.key + 1}.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String suggestion;

  const _SuggestionCard({required this.title, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
