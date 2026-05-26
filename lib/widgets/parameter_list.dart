import 'package:flutter/material.dart';
import '../models/parameter.dart';
import '../models/project.dart';

class ParameterList extends StatefulWidget {
  final Project project;
  final void Function(Parameter target, Parameter contributor) onAddContributor;
  final void Function(Parameter target, String contributorId) onRemoveContributor;
  final void Function(Parameter target, String contributorId, double weight) onUpdateWeight;
  final void Function(Parameter) onRemove;
  final void Function(Parameter) onEdit;

  const ParameterList({
    super.key,
    required this.project,
    required this.onAddContributor,
    required this.onRemoveContributor,
    required this.onUpdateWeight,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  State<ParameterList> createState() => _ParameterListState();
}

class _ParameterListState extends State<ParameterList> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.project.parameters.length,
      itemBuilder: (context, index) {
        final param = widget.project.parameters[index];
        return _buildParameterCard(param);
      },
    );
  }

  Widget _buildParameterCard(Parameter param) {
    final isExpanded = _expanded.contains(param.id);
    final isRoot = !widget.project.parameters.any((p) => p.contributorIds.contains(param.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              param.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${isRoot ? 'Root • ' : ''}${param.aggregation.name}'
              '${param.maxValue != null ? ' • max=${param.maxValue}' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditDialog(param),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => widget.onRemove(param),
                ),
              ],
            ),
          ),
          if (param.contributors.isNotEmpty)
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expanded.remove(param.id);
                  } else {
                    _expanded.add(param.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Contributors (${param.contributors.length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: param.contributors.map((link) {
                  final contributor = widget.project.getParameterById(link.id);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_upward, size: 16),
                    title: Text(contributor?.name ?? 'Unknown'),
                    subtitle: Builder(
                      builder: (context) {
                        final totalWeight = param.contributors.fold(0.0, (s, c) => s + c.weight);
                        final normalized = totalWeight > 0 ? link.weight / totalWeight : 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('w=', style: TextStyle(fontSize: 12)),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: TextEditingController(text: link.weight.toStringAsFixed(2)),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (v) {
                                      final value = double.tryParse(v.trim()) ?? 0;
                                      if (value >= 0) {
                                        widget.onUpdateWeight(param, link.id, value);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(n=${normalized.toStringAsFixed(2)})',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, size: 18, color: Colors.red),
                      onPressed: () => widget.onRemoveContributor(param, link.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (isExpanded || param.contributors.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextButton.icon(
                onPressed: () => _showAddContributorDialog(param),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Contributor'),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(Parameter param) {
    final nameController = TextEditingController(text: param.name);
    final maxValueController = TextEditingController(
      text: param.maxValue?.toString() ?? '',
    );
    AggregationType aggregation = param.aggregation;
    bool inverted = param.inverted;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Parameter'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: maxValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Value (optional)',
                    hintText: 'Leave empty for raw 0-1',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: inverted,
                      onChanged: maxValueController.text.trim().isEmpty
                          ? null
                          : (v) => setState(() => inverted = v!),
                    ),
                    const Text('Inverted'),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'When enabled, higher raw values produce lower scores. Useful for "bad when high" parameters like cost.',
                      child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    ),
                  ],
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
                param.name = nameController.text.trim();
                param.aggregation = aggregation;
                param.maxValue = maxValueController.text.trim().isEmpty
                    ? null
                    : double.tryParse(maxValueController.text.trim());
                param.inverted = inverted;
                widget.onEdit(param);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContributorDialog(Parameter target) {
    final available = widget.project.parameters
        .where((p) => p.id != target.id && !target.contributorIds.contains(p.id))
        .toList();

    if (available.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Contributor'),
          content: const Text('No available parameters to add as contributors.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Contributor to "${target.name}"'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (context, index) {
              final param = available[index];
              return ListTile(
                dense: true,
                title: Text(param.name),
                subtitle: Text(param.isLeaf ? 'Leaf' : 'Computed'),
                onTap: () {
                  final wouldCreateCycle = _wouldCreateCycle(target, param);
                  if (wouldCreateCycle) {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        title: const Text('Cycle Detected'),
                        content: Text(
                          'Adding "${param.name}" as a contributor of "${target.name}" would create a circular dependency.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx2),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  widget.onAddContributor(target, param);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  bool _wouldCreateCycle(Parameter target, Parameter contributor) {
    final visited = <String>{};
    return _contributesTo(target.id, contributor.id, visited);
  }

  bool _contributesTo(String fromId, String toId, Set<String> visited) {
    if (visited.contains(fromId)) return false;
    visited.add(fromId);
    final param = widget.project.getParameterById(fromId);
    if (param == null) return false;
    for (final cid in param.contributorIds) {
      if (cid == toId) return true;
      if (_contributesTo(cid, toId, visited)) return true;
    }
    return false;
  }
}
