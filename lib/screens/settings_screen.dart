import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Name'),
            subtitle: const Text('Fuzzy Logic Compare'),
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('Version'),
            subtitle: Text(_version.isEmpty ? 'Loading...' : _version),
          ),
          const Divider(),
          _buildSectionHeader('Help'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('How to Use'),
            subtitle: const Text('Define parameters, add fuzzy objects, compare'),
            onTap: () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to Use'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Create a new project or open an existing JSON file.'),
              SizedBox(height: 8),
              Text('2. Define fuzzy logic parameters in the left panel.'),
              SizedBox(height: 8),
              Text('3. Add child parameters to build a hierarchical tree.'),
              SizedBox(height: 8),
              Text('4. Set weights (0-1) and aggregation methods for each parameter.'),
              SizedBox(height: 8),
              Text('5. Add fuzzy objects in the right panel.'),
              SizedBox(height: 8),
              Text('6. Fill in values (0-1) for each leaf parameter.'),
              SizedBox(height: 8),
              Text('7. Select 2+ objects and click Compare to see results.'),
              SizedBox(height: 8),
              Text('8. Save with Ctrl+S, Save As, or Save New Version.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
