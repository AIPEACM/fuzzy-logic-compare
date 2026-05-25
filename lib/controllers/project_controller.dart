import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/parameter.dart';
import '../models/fuzzy_object.dart';
import '../services/json_storage.dart';

class ProjectController extends ChangeNotifier {
  Project? _project;
  String? _filePath;
  bool _hasUnsavedChanges = false;

  Project? get project => _project;
  String? get filePath => _filePath;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get hasProject => _project != null;

  void createNewProject(String name, {bool isTree = false}) {
    final root = Parameter(name: name);
    _project = Project(name: name, isTree: isTree, parameters: [root]);
    _filePath = null;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> openProject() async {
    final result = await JsonStorage.openProject();
    if (result == null) return false;
    final (proj, path) = result;
    _project = proj;
    _filePath = path;
    _hasUnsavedChanges = false;
    notifyListeners();
    return true;
  }

  void loadProject(Project project, String path) {
    _project = project;
    _filePath = path;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<String?> saveProject() async {
    if (_project == null) return null;
    // If opened from .json, first save prompts for .jsonfz location
    final usePath = (_filePath != null && _filePath!.endsWith('.jsonfz')) ? _filePath : null;
    final path = await JsonStorage.saveProject(_project!, path: usePath);
    if (path != null) {
      _filePath = path;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
    return path;
  }

  Future<String?> saveAsNewProject() async {
    if (_project == null) return null;
    final path = await JsonStorage.saveProject(_project!);
    if (path != null) {
      _filePath = path;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
    return path;
  }

  Future<String?> saveTemplate() async {
    if (_project == null) return null;
    final paramsJson = _project!.parameters.map((p) => p.toJson()).toList();
    return await JsonStorage.saveTemplate(paramsJson);
  }

  Future<bool> loadTemplate() async {
    final paramsJson = await JsonStorage.loadTemplate();
    if (paramsJson == null || _project == null) return false;
    for (final p in paramsJson) {
      _project!.parameters.add(Parameter.fromJson(p as Map<String, dynamic>));
    }
    _hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  void markChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  // Parameter operations
  void addParameter(Parameter param) {
    if (_project == null) return;
    _project!.parameters = [..._project!.parameters, param];
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void removeParameter(Parameter param) {
    if (_project == null) return;
    // Remove from all contributor lists first
    for (final p in _project!.parameters) {
      p.contributors = p.contributors.where((c) => c.id != param.id).toList();
    }
    _project!.parameters = _project!.parameters.where((p) => p.id != param.id).toList();
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void addContributor(Parameter target, Parameter contributor) {
    if (_project == null) return;
    if (target.id == contributor.id) return;
    if (target.contributorIds.contains(contributor.id)) return;
    target.contributors = [...target.contributors, ContributorLink(id: contributor.id)];
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void removeContributor(Parameter target, String contributorId) {
    if (_project == null) return;
    target.contributors = target.contributors.where((c) => c.id != contributorId).toList();
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateContributorWeight(Parameter target, String contributorId, double weight) {
    if (_project == null) return;
    final link = target.contributors.firstWhere((c) => c.id == contributorId);
    link.weight = weight;
    markChanged();
  }

  void convertToTree() {
    if (_project == null) return;

    // Multi-pass: keep duplicating until no parameter has multiple parents.
    // Each pass clones parameters with >1 parent, then recompute.
    while (true) {
      final parentCount = <String, int>{};
      for (final p in _project!.parameters) {
        for (final c in p.contributors) {
          parentCount[c.id] = (parentCount[c.id] ?? 0) + 1;
        }
      }

      final multiParent = parentCount.entries.where((e) => e.value > 1).toList();
      if (multiParent.isEmpty) break;

      for (final entry in multiParent) {
        final originalId = entry.key;
        final original = _project!.getParameterById(originalId);
        if (original == null) continue;

        final parents = _project!.parameters
            .where((p) => p.contributors.any((c) => c.id == originalId))
            .toList();

        for (var i = 1; i < parents.length; i++) {
          final parent = parents[i];
          // Deep clone: recursively copy the entire subtree rooted at original
          final duplicate = _deepClone(original, parent.name);
          _project!.parameters.addAll(duplicate.$2); // add all new params

          // Replace original contributor link with duplicate root
          parent.contributors = parent.contributors.map((c) {
            if (c.id == originalId) {
              return ContributorLink(id: duplicate.$1.id, weight: c.weight);
            }
            return c;
          }).toList();
        }
      }
    }

    _project!.isTree = true;
    markChanged();
  }

  /// Deep-clones a parameter and its entire subtree.
  /// Returns (newRoot, allNewParameters).
  (Parameter, List<Parameter>) _deepClone(Parameter root, String parentName) {
    final newParams = <Parameter>[];
    final idMap = <String, String>{}; // oldId -> newId

    Parameter cloneOne(Parameter p) {
      final dup = Parameter(
        name: p == root ? '${parentName}_${p.name}' : p.name,
        aggregation: p.aggregation,
        maxValue: p.maxValue,
      );
      idMap[p.id] = dup.id;
      newParams.add(dup);

      // Recursively clone contributors
      for (final link in p.contributors) {
        final child = _project!.getParameterById(link.id);
        if (child == null) continue;
        final childDup = cloneOne(child);
        dup.contributors.add(ContributorLink(
          id: childDup.id,
          weight: link.weight,
        ));
      }
      return dup;
    }

    final newRoot = cloneOne(root);
    return (newRoot, newParams);
  }

  void convertToNetwork() {
    if (_project == null) return;
    _project!.isTree = false;
    markChanged();
  }

  void updateParameter(Parameter param, {String? name, AggregationType? aggregation, double? maxValue}) {
    if (name != null) param.name = name;
    if (aggregation != null) param.aggregation = aggregation;
    if (maxValue != null) param.maxValue = maxValue;
    markChanged();
  }

  // Fuzzy object operations
  void addFuzzyObject(FuzzyObject obj) {
    if (_project == null) return;
    _project!.fuzzyObjects.add(obj);
    markChanged();
  }

  void removeFuzzyObject(FuzzyObject obj) {
    if (_project == null) return;
    _project!.fuzzyObjects.remove(obj);
    markChanged();
  }

  void updateFuzzyObjectName(FuzzyObject obj, String name) {
    obj.name = name;
    markChanged();
  }

  void setFuzzyValue(FuzzyObject obj, String parameterId, double value) {
    obj.values[parameterId] = value;
    markChanged();
  }

  // Comparison logic
  Map<String, double> compareObjects(List<FuzzyObject> objects) {
    if (_project == null || objects.isEmpty) return {};
    final result = <String, double>{};
    for (final param in _project!.parameters) {
      _evaluateParameter(param, objects, result, <String>{});
    }
    return result;
  }

  double _evaluateParameter(Parameter param, List<FuzzyObject> objects, Map<String, double> result, Set<String> visiting) {
    if (visiting.contains(param.id)) {
      result[param.id] = 0.0;
      return 0.0;
    }
    if (result.containsKey(param.id)) {
      return result[param.id]!;
    }

    if (param.isLeaf) {
      final values = objects.map((o) => o.values[param.id] ?? 0.0).toList();
      final score = values.reduce((a, b) => a + b) / values.length;
      result[param.id] = score;
      return score;
    }

    visiting.add(param.id);
    final contributorValues = <double>[];
    final totalWeight = param.contributors.fold(0.0, (sum, c) => sum + c.weight);
    for (final link in param.contributors) {
      final contributor = _project!.getParameterById(link.id);
      if (contributor == null) continue;
      final value = _evaluateParameter(contributor, objects, result, visiting);
      final normalizedWeight = totalWeight > 0 ? link.weight / totalWeight : 0;
      contributorValues.add(value * normalizedWeight);
    }
    visiting.remove(param.id);

    final score = _aggregate(contributorValues, param.aggregation);
    result[param.id] = score;
    return score;
  }

  double _aggregate(List<double> values, AggregationType type) {
    if (values.isEmpty) return 0.0;
    switch (type) {
      case AggregationType.min:
        return values.reduce((a, b) => a < b ? a : b);
      case AggregationType.max:
        return values.reduce((a, b) => a > b ? a : b);
      case AggregationType.avg:
      case AggregationType.weighted:
        return values.reduce((a, b) => a + b) / values.length;
    }
  }
}
