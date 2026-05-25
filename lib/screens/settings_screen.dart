import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub Repository'),
            subtitle: const Text('github.com/AIPEACM/fuzzy-logic-compare'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchUrl('https://github.com/AIPEACM/fuzzy-logic-compare'),
          ),
          const Divider(),
          _buildSectionHeader('Help'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('How to Use'),
            subtitle: const Text('Define parameters, add fuzzy objects, compare'),
            onTap: () => _showHelpDialog(context),
          ),
          const Divider(),
          _buildSectionHeader('License'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SelectableText(
              '''GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2026 AIPEACM

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.''',
              style: TextStyle(fontSize: 12),
            ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
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
