import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiassistant1/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = '';
  }

  Future<void> _updateProfile() async {}

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

          // Account removed in demo build
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
