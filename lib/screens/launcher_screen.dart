import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/project_controller.dart';
import 'main_editor_screen.dart';

class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              Text(
                'Fuzzy Logic Compare',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              _ActionCard(
                icon: Icons.add,
                title: 'New Project',
                subtitle: 'Create a new fuzzy logic comparison project',
                onTap: () => _showNewProjectDialog(context),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.folder_open,
                title: 'Open Project',
                subtitle: 'Open an existing JSON project file',
                onTap: () => _openProject(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'Enter project name',
          ),
          onSubmitted: (_) => _createProject(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _createProject(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createProject(BuildContext context, String name) {
    if (name.trim().isEmpty) return;
    Navigator.pop(context);
    final projController = context.read<ProjectController>();
    projController.createNewProject(name.trim());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainEditorScreen()),
    );
  }

  Future<void> _openProject(BuildContext context) async {
    final projController = context.read<ProjectController>();
    final success = await projController.openProject();
    if (success && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainEditorScreen()),
      );
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.indigo),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
