import 'package:flutter/material.dart';
import '../models/parameter.dart';

class ParameterTree extends StatefulWidget {
  final List<Parameter> parameters;
  final void Function(Parameter parent, Parameter child) onAddChild;
  final ValueChanged<Parameter> onRemove;
  final ValueChanged<Parameter> onEdit;
  final Parameter? selectedParameter;
  final ValueChanged<Parameter>? onSelect;

  const ParameterTree({
    super.key,
    required this.parameters,
    required this.onAddChild,
    required this.onRemove,
    required this.onEdit,
    this.selectedParameter,
    this.onSelect,
  });

  @override
  State<ParameterTree> createState() => _ParameterTreeState();
}

class _ParameterTreeState extends State<ParameterTree> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.parameters.length,
      itemBuilder: (context, index) {
        return _buildNode(widget.parameters[index], 0);
      },
    );
  }

  Widget _buildNode(Parameter param, int depth) {
    final isExpanded = _expanded.contains(param.id);
    final isSelected = widget.selectedParameter?.id == param.id;
    final hasChildren = param.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => widget.onSelect?.call(param),
          child: Container(
            color: isSelected ? Colors.indigo.withValues(alpha: 0.1) : null,
            padding: EdgeInsets.only(left: depth * 16.0 + 8, top: 4, bottom: 4),
            child: Row(
              children: [
                if (hasChildren)
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expanded.remove(param.id);
                        } else {
                          _expanded.add(param.id);
                        }
                      });
                    },
                  )
                else
                  const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        param.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'w=${param.weight.toStringAsFixed(2)} • ${param.aggregation.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
        if (isExpanded)
          ...param.children.map((child) => _buildNode(child, depth + 1)),
      ],
    );
  }

  void _showAddChildDialog(Parameter parent) {
    final nameController = TextEditingController();
    final maxValueController = TextEditingController();
    double weight = 1.0;
    AggregationType aggregation = AggregationType.avg;

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
                const SizedBox(height: 12),
                TextField(
                  controller: maxValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Value (optional, for normalization)',
                    hintText: 'Leave empty for raw 0-1',
                  ),
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
                  setState(() => _expanded.add(parent.id));
                  final child = Parameter(
                    name: nameController.text.trim(),
                    weight: weight,
                    aggregation: aggregation,
                    maxValue: maxValueController.text.trim().isEmpty
                        ? null
                        : double.tryParse(maxValueController.text.trim()),
                  );
                  widget.onAddChild(parent, child);
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
    double weight = param.weight;
    AggregationType aggregation = param.aggregation;

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
                const SizedBox(height: 12),
                TextField(
                  controller: maxValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Value (optional)',
                    hintText: param.maxValue == null ? 'Leave empty for raw 0-1' : 'Current: ${param.maxValue}',
                  ),
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
                param.weight = weight;
                param.aggregation = aggregation;
                param.maxValue = maxValueController.text.trim().isEmpty
                    ? null
                    : double.tryParse(maxValueController.text.trim());
                setState(() {});
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
}
