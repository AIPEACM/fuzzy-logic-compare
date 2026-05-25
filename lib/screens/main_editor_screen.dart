import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/project_controller.dart';
import '../models/parameter.dart';
import '../models/fuzzy_object.dart';
import '../widgets/parameter_tree.dart';
import '../widgets/fuzzy_object_editor.dart';
import 'comparison_overlay.dart';
import 'settings_screen.dart';

class MainEditorScreen extends StatefulWidget {
  const MainEditorScreen({super.key});

  @override
  State<MainEditorScreen> createState() => _MainEditorScreenState();
}

class _MainEditorScreenState extends State<MainEditorScreen> {
  int _selectedNavIndex = 0;
  FuzzyObject? _selectedObject;
  final Set<String> _selectedForCompare = {};
  Parameter? _selectedParameter;
  double _splitRatio = 0.4;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProjectController>();
    final project = controller.project;

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyS): const SaveAsIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (_) => _save(context),
          ),
          SaveAsIntent: CallbackAction<SaveAsIntent>(
            onInvoke: (_) => _saveAs(context),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${project.name} (v${project.version})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.hasUnsavedChanges)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '• unsaved',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save (Ctrl+S)',
                  onPressed: () => _save(context),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Save options',
                  onSelected: (value) {
                    switch (value) {
                      case 'save_as':
                        _saveAs(context);
                        break;
                      case 'save_version':
                        _saveNewVersion(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'save_as',
                      child: Row(
                        children: [
                          Icon(Icons.save_as),
                          SizedBox(width: 8),
                          Text('Save As...'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'save_version',
                      child: Row(
                        children: [
                          Icon(Icons.layers),
                          SizedBox(width: 8),
                          Text('Save New Version'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _selectedNavIndex == 0
                ? _buildEditor(project, controller)
                : const SettingsScreen(),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedNavIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.edit),
                  label: 'Editor',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(dynamic project, ProjectController controller) {
    return Row(
      children: [
        Expanded(
          flex: (_splitRatio * 100).toInt(),
          child: _buildLeftPanel(project, controller),
        ),
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _splitRatio += details.delta.dx / context.size!.width;
              _splitRatio = _splitRatio.clamp(0.2, 0.8);
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Container(
              width: 8,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.drag_indicator, size: 12),
              ),
            ),
          ),
        ),
        Expanded(
          flex: ((1 - _splitRatio) * 100).toInt(),
          child: _buildRightPanel(project, controller),
        ),
      ],
    );
  }

  Widget _buildLeftPanel(dynamic project, ProjectController controller) {
    return Column(
      children: [
        Container(
          color: Colors.indigo.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.account_tree, size: 20, color: Colors.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Parameters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                tooltip: 'Add Root Parameter',
                onPressed: () => _showAddRootParameter(controller),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ParameterTree(
            parameters: project.parameters,
            selectedParameter: _selectedParameter,
            onSelect: (p) => setState(() => _selectedParameter = p),
            onAddChild: (parent) {},
            onRemove: (param) => _removeParameter(controller, param),
            onEdit: (param) => controller.markChanged(),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(dynamic project, ProjectController controller) {
    return Column(
      children: [
        Container(
          color: Colors.teal.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.data_object, size: 20, color: Colors.teal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fuzzy Objects',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                tooltip: 'Add Fuzzy Object',
                onPressed: () => _addFuzzyObject(controller),
              ),
              if (_selectedForCompare.length >= 2)
                FilledButton.icon(
                  onPressed: () => _showComparison(controller),
                  icon: const Icon(Icons.compare_arrows, size: 18),
                  label: Text('Compare (${_selectedForCompare.length})'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (project.fuzzyObjects.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No fuzzy objects yet. Click + to add one.'),
            ),
          )
        else
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: ListView.builder(
                    itemCount: project.fuzzyObjects.length,
                    itemBuilder: (context, index) {
                      final obj = project.fuzzyObjects[index];
                      final isSelected = _selectedObject?.id == obj.id;
                      final isForCompare = _selectedForCompare.contains(obj.id);
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: Checkbox(
                          value: isForCompare,
                          onChanged: (_) {
                            setState(() {
                              if (isForCompare) {
                                _selectedForCompare.remove(obj.id);
                              } else {
                                _selectedForCompare.add(obj.id);
                              }
                            });
                          },
                        ),
                        title: Text(
                          obj.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => setState(() => _selectedObject = obj),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _removeFuzzyObject(controller, obj),
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedObject == null
                      ? const Center(child: Text('Select an object to edit'))
                      : FuzzyObjectEditor(
                          parameters: project.parameters,
                          fuzzyObject: _selectedObject!,
                          onChanged: (_) => controller.markChanged(),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAddRootParameter(ProjectController controller) {
    final nameController = TextEditingController();
    double weight = 1.0;
    AggregationType aggregation = AggregationType.avg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Root Parameter'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Weight:'),
                    Expanded(
                      child: Slider(
                        value: weight,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        label: weight.toStringAsFixed(2),
                        onChanged: (v) => setState(() => weight = v),
                      ),
                    ),
                    Text(weight.toStringAsFixed(2)),
                  ],
                ),
                DropdownButtonFormField<AggregationType>(
                  initialValue: aggregation,
                  decoration: const InputDecoration(labelText: 'Aggregation'),
                  items: AggregationType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => aggregation = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  controller.addRootParameter(
                    Parameter(
                      name: nameController.text.trim(),
                      weight: weight,
                      aggregation: aggregation,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeParameter(ProjectController controller, Parameter param) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Parameter?'),
        content: Text('Delete "${param.name}" and all its children?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.removeRootParameter(param);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addFuzzyObject(ProjectController controller) {
    final obj = FuzzyObject(name: 'Object ${controller.project!.fuzzyObjects.length + 1}');
    controller.addFuzzyObject(obj);
    setState(() => _selectedObject = obj);
  }

  void _removeFuzzyObject(ProjectController controller, FuzzyObject obj) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Object?'),
        content: Text('Delete "${obj.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.removeFuzzyObject(obj);
              if (_selectedObject?.id == obj.id) {
                setState(() => _selectedObject = null);
              }
              _selectedForCompare.remove(obj.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showComparison(ProjectController controller) {
    final objects = controller.project!.fuzzyObjects
        .where((o) => _selectedForCompare.contains(o.id))
        .toList();
    final results = controller.compareObjects(objects);

    showDialog(
      context: context,
      builder: (ctx) => ComparisonOverlay(
        parameters: controller.project!.parameters,
        objects: objects,
        results: results,
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final controller = context.read<ProjectController>();
    final path = await controller.saveProject();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $path')),
      );
    }
  }

  Future<void> _saveAs(BuildContext context) async {
    final controller = context.read<ProjectController>();
    final path = await controller.saveAsNewProject();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved as $path')),
      );
    }
  }

  Future<void> _saveNewVersion(BuildContext context) async {
    final controller = context.read<ProjectController>();
    final path = await controller.saveNewVersion();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved new version to $path')),
      );
    }
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}
