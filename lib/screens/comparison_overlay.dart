import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/fuzzy_object.dart';
import '../widgets/result_tree.dart';

class ComparisonOverlay extends StatelessWidget {
  final Project project;
  final List<FuzzyObject> objects;
  final Map<String, double> results;

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
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildObjectList(),
            const Divider(height: 1),
            Expanded(
              child: ResultTree(
                project: project,
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
              children: objects.map((obj) {
                return Chip(
                  label: Text(obj.name),
                  backgroundColor: Colors.indigo.shade100,
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
    final overall = roots.isNotEmpty && results.isNotEmpty
        ? roots.map((r) => results[r.id] ?? 0.0).reduce((a, b) => a + b) / roots.length
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Overall Score: ${overall.toStringAsFixed(3)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
