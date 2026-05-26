import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/fuzzy_object.dart';
import '../widgets/result_tree.dart';

class ComparisonOverlay extends StatelessWidget {
  final Project project;
  final List<FuzzyObject> objects;
  final Map<String, List<double>> results;

  const ComparisonOverlay({
    super.key,
    required this.project,
    required this.objects,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildObjectList(),
            const Divider(height: 1),
            Expanded(
              child: ResultTree(
                project: project,
                objects: objects,
                results: results,
              ),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Comparison Result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectList() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Comparing:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: objects.asMap().entries.map((entry) {
                final index = entry.key;
                final obj = entry.value;
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: _objectColor(index),
                    radius: 10,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  label: Text(obj.name),
                  backgroundColor: _objectColor(index).withAlpha(40),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final roots = project.roots;
    final perObjectOverall = List<double>.filled(objects.length, 0.0);
    if (roots.isNotEmpty && results.isNotEmpty) {
      for (final root in roots) {
        final rootScores = results[root.id];
        if (rootScores != null) {
          for (var i = 0; i < objects.length && i < rootScores.length; i++) {
            perObjectOverall[i] += rootScores[i];
          }
        }
      }
      for (var i = 0; i < perObjectOverall.length; i++) {
        perObjectOverall[i] /= roots.length;
      }
    }

    // Sort by score descending
    final sortedIndices = List<int>.generate(objects.length, (i) => i)
      ..sort((a, b) => perObjectOverall[b].compareTo(perObjectOverall[a]));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Score (Ranked)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: sortedIndices.map((i) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: _objectColor(i),
                  radius: 10,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                label: Text(
                  '${objects[i].name}: ${perObjectOverall[i].toStringAsFixed(3)}',
                ),
                backgroundColor: _objectColor(i).withAlpha(40),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Color _objectColor(int index) {
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}
