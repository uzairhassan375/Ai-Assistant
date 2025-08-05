import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:aiassistant1/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _nameController.text = _user?.displayName ?? '';
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isNotEmpty &&
        _nameController.text != _user?.displayName) {
      await _user?.updateDisplayName(_nameController.text);
      await _auth.currentUser?.reload();
      setState(() {
        _user = _auth.currentUser;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Settings
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(settings),
          const SizedBox(height: 16),
          _buildFontSlider(settings),
          const Divider(height: 32),

          // Account Settings
          _buildSectionHeader('Account'),
          if (_user != null) ...[
            CircleAvatar(
              radius: 40,
              child: Text(
                _user!.displayName?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${_user!.email ?? 'N/A'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async => await _auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ] else
            const Text('Not logged in'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildThemeSelector(SettingsService settings) {
    return ListTile(
      title: const Text('Theme'),
      trailing: DropdownButton<ThemeMode>(
        value: settings.themeMode,
        items: const [
          DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
          DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
        ],
        onChanged: (value) => settings.updateThemeMode(value),
      ),
    );
  }

  Widget _buildFontSlider(SettingsService settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font Size'),
        Slider(
          value: settings.fontScale,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: settings.fontScale.toStringAsFixed(1),
          onChanged: (value) => settings.updateFontScale(value),
        ),
      ],
    );
  }
}
