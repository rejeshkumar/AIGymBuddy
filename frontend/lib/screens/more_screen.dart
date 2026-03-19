import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'progress_screen.dart';
import 'ai_coach_screen.dart';
import 'groups_leaderboard_screen.dart';
import 'admin_screen.dart';

/// More menu: Progress, AI Coach, Leaderboard, Admin, Logout.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.user?['role'] ?? 'user') == 'admin';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'More',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Progress, tips, and community',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        _MoreTile(
          icon: Icons.trending_up,
          title: 'Progress',
          subtitle: 'Workout history and stats',
          onTap: () => _navigate(context, const ProgressScreen()),
        ),
        const SizedBox(height: 12),
        _MoreTile(
          icon: Icons.smart_toy,
          title: 'AI Coach',
          subtitle: 'Tips and personalized advice',
          onTap: () => _navigate(context, const AiCoachScreen()),
        ),
        const SizedBox(height: 12),
        _MoreTile(
          icon: Icons.leaderboard,
          title: 'Leaderboard',
          subtitle: 'Compete with groups',
          onTap: () => _navigate(context, const GroupsLeaderboardScreen()),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          _MoreTile(
            icon: Icons.admin_panel_settings,
            title: 'Admin',
            subtitle: 'User management',
            onTap: () => _navigate(context, const AdminScreen()),
          ),
        ],
        const SizedBox(height: 32),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: theme.colorScheme.surfaceContainerHighest,
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title: Text(
            'Sign out',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            auth.logout();
          },
        ),
      ],
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: theme.colorScheme.surfaceContainerHighest,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 24),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
