import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/parameter.dart';

class ParameterTree extends StatefulWidget {
  final Project project;
  final ValueChanged<Parameter> onAddChild;
  final ValueChanged<Parameter> onRemove;
  final void Function(Parameter param, double weight) onEdit;
  final VoidCallback? onChanged;

  const ParameterTree({
    super.key,
    required this.project,
    required this.onAddChild,
    required this.onRemove,
    required this.onEdit,
    this.onChanged,
  });

  @override
  State<ParameterTree> createState() => _ParameterTreeState();
}

class _ParameterTreeState extends State<ParameterTree> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final roots = widget.project.roots;
    return ListView.builder(
      itemCount: roots.length,
      itemBuilder: (context, index) {
        return _buildNode(roots[index], 0);
      },
    );
  }

  Widget _buildNode(Parameter param, int depth) {
    final isExpanded = _expanded.contains(param.id);
    final children = param.contributorIds
        .map((id) => widget.project.getParameterById(id))
        .where((p) => p != null)
        .cast<Parameter>()
        .toList();
    final hasChildren = children.isNotEmpty;
    final isRoot = widget.project.roots.any((r) => r.id == param.id);
    final weight = isRoot ? null : widget.project.getContributorWeight(param.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onSecondaryTapUp: (details) => _showContextMenu(param, details.globalPosition),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expanded.remove(param.id);
                } else {
                  _expanded.add(param.id);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(left: depth * 16.0 + 8, top: 4, bottom: 4),
              child: Row(
                children: [
                  if (hasChildren)
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    )
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          param.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isRoot) ...[
                          Builder(
                            builder: (context) {
                              final parent = widget.project.getParentOf(param.id);
                              final totalWeight = parent?.contributors.fold(0.0, (s, c) => s + c.weight) ?? 1.0;
                              final normalized = totalWeight > 0 ? (weight ?? 1.0) / totalWeight : 0.0;
                              return Text(
                                'w=${(weight ?? 1.0).toStringAsFixed(2)} (n=${normalized.toStringAsFixed(2)}) • ${param.aggregation.name}${param.maxValue != null ? ' • max=${param.maxValue}${param.inverted ? " (inv)" : ""}' : ""}',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => _showAddChildDialog(param),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(param),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.onRemove(param),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          ...children.map((child) => _buildNode(child, depth + 1)),
      ],
    );
  }

  void _showContextMenu(Parameter param, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          onTap: () => _evenlyArrangeChildren(param),
          child: Row(
            children: [
              const Icon(Icons.format_align_justify, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Evenly arrange children')),
              Tooltip(
                message: 'Set aggregation to avg and make all direct children contribute equally to this parameter. Does not affect grandchildren.',
                child: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => _evenlyArrangeLeaves(param),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Evenly arrange all leaves')),
              Tooltip(
                message: 'Set aggregation to avg for this parameter and all descendants, then adjust weights so every leaf contributes equally.',
                child: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _evenlyArrangeChildren(Parameter param) {
    param.aggregation = AggregationType.avg;
    final n = param.contributors.length;
    if (n > 0) {
      for (final link in param.contributors) {
        link.weight = 1.0;
      }
    }
    widget.onChanged?.call();
  }

  void _evenlyArrangeLeaves(Parameter param) {
    // Count leaves in each node's subtree (bottom-up via DFS post-order)
    final leafCount = <String, int>{};

    int countLeaves(String id) {
      if (leafCount.containsKey(id)) return leafCount[id]!;
      final p = widget.project.getParameterById(id);
      if (p == null || p.isLeaf) {
        leafCount[id] = 1;
        return 1;
      }
      int sum = 0;
      for (final link in p.contributors) {
        sum += countLeaves(link.id);
      }
      leafCount[id] = sum;
      return sum;
    }

    // Compute leaf counts for all nodes in subtree
    countLeaves(param.id);

    // Set aggregation to avg for all nodes in subtree, and set weights
    void apply(String id) {
      final p = widget.project.getParameterById(id);
      if (p == null) return;
      p.aggregation = AggregationType.avg;
      final parentLeaves = leafCount[id]!;
      for (final link in p.contributors) {
        final childLeaves = leafCount[link.id]!;
        link.weight = childLeaves / parentLeaves;
        apply(link.id);
      }
    }

    apply(param.id);
    widget.onChanged?.call();
  }

  void _showAddChildDialog(Parameter parent) {
    final nameController = TextEditingController();
    final maxValueController = TextEditingController();
    AggregationType aggregation = AggregationType.avg;
    bool inverted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add Child to "${parent.name}"'),
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
                      onChanged: (v) => setState(() => inverted = v!),
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
                if (nameController.text.trim().isNotEmpty) {
                  final child = Parameter(
                    name: nameController.text.trim(),
                    aggregation: aggregation,
                    maxValue: maxValueController.text.trim().isEmpty
                        ? null
                        : double.tryParse(maxValueController.text.trim()),
                    inverted: inverted,
                  );
                  widget.onAddChild(child);
                  parent.contributors = [...parent.contributors, ContributorLink(id: child.id)];
                  setState(() => _expanded.add(parent.id));
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

  void _showEditDialog(Parameter param) {
    final nameController = TextEditingController(text: param.name);
    final maxValueController = TextEditingController(
      text: param.maxValue?.toString() ?? '',
    );
    final isRoot = widget.project.roots.any((r) => r.id == param.id);
    final weight = isRoot ? 1.0 : widget.project.getContributorWeight(param.id);
    double editedWeight = weight;
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
                if (!isRoot) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: weight.toStringAsFixed(2)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final value = double.tryParse(v.trim()) ?? 0;
                      if (value >= 0) editedWeight = value;
                    },
                  ),
                ],
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
                      onChanged: (v) => setState(() => inverted = v!),
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
                setState(() {});
                widget.onEdit(param, editedWeight);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
