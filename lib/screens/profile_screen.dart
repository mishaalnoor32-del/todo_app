// lib/screens/profile_screen.dart
//
// The profile page reached by tapping the avatar on the home screen.
// Lets the user edit their name/role (persisted via SharedPreferences)
// and shows quick app stats pulled from the Hive box.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../services/user_prefs_service.dart';
import '../theme/app_theme.dart';
import '../main.dart' show taskBoxName;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _prefsService = UserPrefsService();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _prefsService.getName();
    final role = await _prefsService.getRole();
    _nameController.text = name;
    _roleController.text = role;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    if (name.isEmpty) return;

    await _prefsService.setName(name);
    await _prefsService.setRole(role.isEmpty ? 'Software Engineer' : role);

    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) {
      // Return 'true' to signal HomeScreen to reload profile data
      Navigator.pop(context, true);
    }
  }

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>(taskBoxName);
    final total = box.values.length;
    final completed = box.values.cast<Task>().where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- Gradient header with avatar ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Hero(
                          tag: 'profile-avatar',
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Your Name'
                              : _nameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _roleController.text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatChip(label: 'Total', value: '$total'),
                            const SizedBox(width: 12),
                            _StatChip(label: 'Done', value: '$completed'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Editable fields ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Edit Profile',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _roleController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Role / Title',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: Icon(_saved ? Icons.check : Icons.save_outlined),
                      label: Text(_saved ? 'Saved!' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
        ],
      ),
    );
  }
}