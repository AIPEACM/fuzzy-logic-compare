import 'package:flutter/material.dart';
import '../models/parameter.dart';
import '../models/fuzzy_object.dart';
import '../models/project.dart';

class FuzzyObjectEditor extends StatefulWidget {
  final Project project;
  final FuzzyObject fuzzyObject;
  final ValueChanged<FuzzyObject> onChanged;

  const FuzzyObjectEditor({
    super.key,
    required this.project,
    required this.fuzzyObject,
    required this.onChanged,
  });

  @override
  State<FuzzyObjectEditor> createState() => _FuzzyObjectEditorState();
}

class _FuzzyObjectEditorState extends State<FuzzyObjectEditor> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fuzzyObject.name);
  }

  @override
  void didUpdateWidget(covariant FuzzyObjectEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuzzyObject.id != widget.fuzzyObject.id) {
      _nameController.text = widget.fuzzyObject.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaves = widget.project.leaves;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Object Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              widget.fuzzyObject.name = v;
              widget.onChanged(widget.fuzzyObject);
            },
          ),
        ),
        const Divider(height: 1),
        if (leaves.isEmpty)
          const Expanded(
            child: Center(child: Text('No leaf parameters defined.')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                return _buildLeafEditor(leaves[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLeafEditor(Parameter param) {
    final hasMax = param.maxValue != null && param.maxValue! > 0;
    final rawValue = widget.fuzzyObject.values[param.id] ?? 0.0;
    final displayValue = hasMax ? rawValue * param.maxValue! : rawValue;
    final max = hasMax ? param.maxValue! : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              param.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Slider(
              value: rawValue.clamp(0.0, 1.0),
              min: 0,
              max: 1,
              divisions: 100,
              label: hasMax ? displayValue.toStringAsFixed(2) : rawValue.toStringAsFixed(2),
              onChanged: (v) {
                setState(() {
                  widget.fuzzyObject.values[param.id] = v;
                });
                widget.onChanged(widget.fuzzyObject);
              },
            ),
          ),
          SizedBox(
            width: hasMax ? 80 : 50,
            child: Text(
              hasMax
                  ? '${displayValue.toStringAsFixed(1)}/${max.toStringAsFixed(0)}'
                  : rawValue.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: hasMax ? 11 : 14,
                color: hasMax ? Colors.blue.shade700 : null,
                fontWeight: hasMax ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
