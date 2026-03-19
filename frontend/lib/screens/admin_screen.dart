import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic>? _users;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _roleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'doctor':
        return 'Doctor';
      case 'gym_instructor':
        return 'Gym Instructor';
      default:
        return 'User';
    }
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() => _loading = true);
    final users = await ApiService().adminListUsers(
      auth.token!,
      search: _search.isEmpty ? null : _search,
    );
    final stats = await ApiService().adminStats(auth.token!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _users = users ?? [];
      _stats = stats;
    });
  }

  Future<void> _deleteUser(int id, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete user $email? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final ok = await ApiService().adminDeleteUser(auth.token!, id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'User deleted' : 'Failed to delete')),
      );
      if (ok) _load();
    }
  }

  void _showCreateUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _AdminUserFormScreen(),
      ),
    ).then((_) => _load());
  }

  void _showEditUser(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminUserFormScreen(user: user),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?['id'];

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage users and view stats',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_stats != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Total Users',
                            value: '${_stats!['total_users'] ?? 0}',
                            icon: Icons.people_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: 'Total Workouts',
                            value: '${_stats!['total_workouts'] ?? 0}',
                            icon: Icons.fitness_center,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by email...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          onSubmitted: (v) {
                            setState(() => _search = v);
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _search = _searchController.text);
                          _load();
                        },
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _showCreateUser,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Create User'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_users == null || _users!.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final u = _users![index] as Map<String, dynamic>;
                    final id = u['id'] as int;
                    final email = u['email'] as String? ?? '';
                    final role = u['role'] as String? ?? 'user';
                    final isCurrent = id == currentUserId;
                    final isStaff = ['admin', 'doctor', 'gym_instructor'].contains(role);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isStaff
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            role == 'admin'
                                ? Icons.admin_panel_settings
                                : role == 'doctor'
                                    ? Icons.medical_services
                                    : role == 'gym_instructor'
                                        ? Icons.fitness_center
                                        : Icons.person,
                            color: isStaff
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(email),
                        subtitle: Text(
                          'ID: $id • ${_roleDisplayName(role)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showEditUser(u),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                              onPressed: isCurrent
                                  ? null
                                  : () => _deleteUser(id, email),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _users!.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminUserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const _AdminUserFormScreen({this.user});

  @override
  State<_AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<_AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  String _goal = 'general';
  String _role = 'user';
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _emailController = TextEditingController(text: u?['email']?.toString() ?? '');
    _passwordController = TextEditingController();
    _ageController = TextEditingController(text: u?['age']?.toString() ?? '');
    _heightController = TextEditingController(text: u?['height']?.toString() ?? '');
    _weightController = TextEditingController(text: u?['weight']?.toString() ?? '');
    _goal = u?['goal']?.toString() ?? 'general';
    _role = u?['role']?.toString() ?? 'user';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    bool ok = false;
    if (_isEdit) {
      final result = await ApiService().adminUpdateUser(
        auth.token!,
        widget.user!['id'] as int,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        age: int.tryParse(_ageController.text),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        goal: _goal,
        role: _role,
      );
      ok = result != null;
    } else {
      final result = await ApiService().adminCreateUser(
        auth.token!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: int.tryParse(_ageController.text),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        goal: _goal,
        role: _role,
      );
      ok = result != null;
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'User updated' : 'User created')),
      );
      Navigator.pop(context);
    } else {
      setState(() => _error = _isEdit ? 'Update failed' : 'Email may already exist');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit User' : 'Create User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEdit,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: _isEdit ? 'Leave blank to keep current' : 'Min 6 characters',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (!_isEdit && (v == null || v.isEmpty)) return 'Enter password';
                  if (!_isEdit && v != null && v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(
                  labelText: 'Goal',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'weight_loss', child: Text('Weight Loss')),
                  DropdownMenuItem(value: 'muscle_gain', child: Text('Muscle Gain')),
                ],
                onChanged: (v) => setState(() => _goal = v ?? 'general'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                  DropdownMenuItem(value: 'gym_instructor', child: Text('Gym Instructor')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'user'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Update User' : 'Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
