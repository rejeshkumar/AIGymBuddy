import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';

class GroupsLeaderboardScreen extends StatefulWidget {
  const GroupsLeaderboardScreen({super.key});

  @override
  State<GroupsLeaderboardScreen> createState() => _GroupsLeaderboardScreenState();
}

class _GroupsLeaderboardScreenState extends State<GroupsLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic>? _leaderboard;
  List<dynamic>? _groups;
  bool _loading = true;
  int? _selectedGroupId;
  final _groupNameController = TextEditingController();
  final _joinGroupIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose();
    _joinGroupIdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() => _loading = true);
    final lb = await ApiService().getLeaderboard(auth.token!, groupId: _selectedGroupId);
    final gr = await ApiService().getGroups(auth.token!);
    setState(() {
      _loading = false;
      _leaderboard = lb?['leaderboard'] as List? ?? [];
      _groups = gr?['groups'] as List? ?? [];
    });
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final result = await ApiService().createGroup(auth.token!, name);
    if (mounted && result != null) {
      _groupNameController.clear();
      Navigator.of(context).pop();
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created')),
      );
    }
  }

  Future<void> _joinGroupById() async {
    final idStr = _joinGroupIdController.text.trim();
    if (idStr.isEmpty) return;
    final id = int.tryParse(idStr);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid group ID')),
      );
      return;
    }
    await _joinGroup(id);
    if (mounted) {
      _joinGroupIdController.clear();
      Navigator.of(context).pop();
    }
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: TextField(
          controller: _joinGroupIdController,
          decoration: const InputDecoration(
            labelText: 'Group ID',
            hintText: 'Enter the group ID to join',
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _joinGroupById(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _joinGroupById,
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Group'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Gym Buddies',
          ),
          onSubmitted: (_) => _createGroup(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _createGroup,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroup(int groupId) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final result = await ApiService().joinGroup(auth.token!, groupId);
    if (mounted) {
      _load();
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Joined group')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join group')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            Tab(icon: Icon(Icons.group), text: 'Groups'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardTab(),
              _buildGroupsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_groups != null && _groups!.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedGroupId == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedGroupId = null;
                        _load();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...(_groups!.map((g) {
                    final id = g['id'] as int;
                    final name = g['name'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: _selectedGroupId == id,
                        onSelected: (_) {
                          setState(() {
                            _selectedGroupId = id;
                            _load();
                          });
                        },
                      ),
                    );
                  })),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_leaderboard == null || _leaderboard!.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: Icons.leaderboard,
                title: 'No leaderboard data yet',
                message: 'Complete workouts and join a group to see rankings.',
              ),
            )
          else
            ...(_leaderboard!.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value as Map<String, dynamic>;
              final rank = entry['rank'] ?? (i + 1);
              final email = entry['email'] ?? 'Unknown';
              final count = entry['workout_count'] ?? 0;
              final isCurrentUser =
                  context.read<AuthProvider>().user?['id'] == entry['user_id'];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rank <= 3
                        ? Colors.amber
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? Colors.black : null,
                      ),
                    ),
                  ),
                  title: Text(
                    email,
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : null,
                    ),
                  ),
                  trailing: Text(
                    '$count workouts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            })),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: const Text('Create new group'),
            onTap: _showCreateGroupDialog,
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.login)),
            title: const Text('Join group by ID'),
            onTap: _showJoinGroupDialog,
          ),
          const Divider(),
          if (_groups == null || _groups!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No groups yet. Create one!',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...(_groups!.map((g) {
              final id = g['id'] as int;
              final name = g['name'] as String;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                title: Text(name),
                subtitle: const Text('Tap to view leaderboard'),
                onTap: () {
                  setState(() {
                    _tabController.animateTo(0);
                    _selectedGroupId = id;
                    _load();
                  });
                },
              );
            })),
        ],
      ),
    );
  }
}
