import 'package:flutter/material.dart';
import '../models/parameter.dart';

class ResultTree extends StatefulWidget {
  final List<Parameter> parameters;
  final Map<String, double> results;

  const ResultTree({
    super.key,
    required this.parameters,
    required this.results,
  });

  @override
  State<ResultTree> createState() => _ResultTreeState();
}

class _ResultTreeState extends State<ResultTree> {
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
    final hasChildren = param.children.isNotEmpty;
    final score = widget.results[param.id] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                child: Text(
                  param.name,
                  style: TextStyle(
                    fontWeight: param.isLeaf ? FontWeight.w500 : FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _scoreColor(score),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score.toStringAsFixed(3),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        if (isExpanded)
          ...param.children.map((child) => _buildNode(child, depth + 1)),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return Colors.green.shade700;
    if (score >= 0.6) return Colors.lightGreen.shade700;
    if (score >= 0.4) return Colors.orange.shade700;
    if (score >= 0.2) return Colors.deepOrange.shade700;
    return Colors.red.shade700;
  }
}
