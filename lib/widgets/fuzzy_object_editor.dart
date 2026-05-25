import 'package:flutter/material.dart';
import '../models/parameter.dart';
import '../models/fuzzy_object.dart';

class FuzzyObjectEditor extends StatefulWidget {
  final List<Parameter> parameters;
  final FuzzyObject fuzzyObject;
  final ValueChanged<FuzzyObject> onChanged;

  const FuzzyObjectEditor({
    super.key,
    required this.parameters,
    required this.fuzzyObject,
    required this.onChanged,
  });

  @override
  State<FuzzyObjectEditor> createState() => _FuzzyObjectEditorState();
}

class _FuzzyObjectEditorState extends State<FuzzyObjectEditor> {
  final Map<String, bool> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: TextEditingController(text: widget.fuzzyObject.name),
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
        Expanded(
          child: ListView.builder(
            itemCount: widget.parameters.length,
            itemBuilder: (context, index) {
              return _buildParameterNode(widget.parameters[index], 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParameterNode(Parameter param, int depth) {
    final isExpanded = _expanded[param.id] ?? true;
    if (param.isLeaf) {
      final hasMax = param.maxValue != null && param.maxValue! > 0;
      final rawValue = widget.fuzzyObject.values[param.id] ?? 0.0;
      final displayValue = hasMax ? rawValue * param.maxValue! : rawValue;
      final max = hasMax ? param.maxValue! : 1.0;
      return Padding(
        padding: EdgeInsets.only(left: depth * 16.0 + 12, top: 4, bottom: 4),
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
              width: hasMax ? 70 : 50,
              child: Text(
                hasMax ? '${displayValue.toStringAsFixed(2)} / ${max.toStringAsFixed(0)}' : rawValue.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: hasMax ? 11 : 14,
                  color: hasMax ? Colors.blue.shade700 : null,
                  fontWeight: hasMax ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded[param.id] = !isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(left: depth * 16.0 + 8, top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  param.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${param.aggregation.name}, w=${param.weight.toStringAsFixed(2)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...param.children.map((child) => _buildParameterNode(child, depth + 1)),
      ],
    );
  }
}
