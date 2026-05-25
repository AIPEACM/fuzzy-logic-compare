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

  void createNewProject(String name) {
    _project = Project(name: name);
    _filePath = null;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> openProject() async {
    final proj = await JsonStorage.openProject();
    if (proj == null) return false;
    _project = proj;
    _filePath = null; // user picked it, but we don't track path from openFile
    _hasUnsavedChanges = false;
    notifyListeners();
    return true;
  }

  Future<String?> saveProject() async {
    if (_project == null) return null;
    final path = await JsonStorage.saveProject(_project!, path: _filePath);
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

  Future<String?> saveNewVersion() async {
    if (_project == null) return null;
    _project!.version += 1;
    _hasUnsavedChanges = true;
    notifyListeners();
    final path = await JsonStorage.saveProject(_project!);
    if (path != null) {
      _filePath = path;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
    return path;
  }

  void markChanged() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // Parameter operations
  void addParameter(Parameter parent, Parameter child) {
    if (_project == null) return;
    parent.children.add(child);
    markChanged();
  }

  void removeParameter(Parameter parent, Parameter child) {
    if (_project == null) return;
    parent.children.remove(child);
    markChanged();
  }

  void updateParameter(Parameter param, {String? name, double? weight, AggregationType? aggregation}) {
    if (name != null) param.name = name;
    if (weight != null) param.weight = weight;
    if (aggregation != null) param.aggregation = aggregation;
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

  void removeFuzzyValue(FuzzyObject obj, String parameterId) {
    obj.values.remove(parameterId);
    markChanged();
  }

  // Comparison logic
  Map<String, double> compareObjects(List<FuzzyObject> objects) {
    if (_project == null || objects.isEmpty) return {};
    final result = <String, double>{};
    for (final param in _project!.parameters) {
      _evaluateParameter(param, objects, result);
    }
    return result;
  }

  double _evaluateParameter(Parameter param, List<FuzzyObject> objects, Map<String, double> result) {
    if (param.isLeaf) {
      final values = objects.map((o) => o.values[param.id] ?? 0.0).toList();
      final score = _aggregate(values, param.aggregation, param.weight);
      result[param.id] = score;
      return score;
    }

    final childScores = param.children.map((c) => _evaluateParameter(c, objects, result)).toList();
    final score = _aggregate(childScores, param.aggregation, param.weight);
    result[param.id] = score;
    return score;
  }

  double _aggregate(List<double> values, AggregationType type, double weight) {
    if (values.isEmpty) return 0.0;
    double raw;
    switch (type) {
      case AggregationType.min:
        raw = values.reduce((a, b) => a < b ? a : b);
        break;
      case AggregationType.max:
        raw = values.reduce((a, b) => a > b ? a : b);
        break;
      case AggregationType.avg:
        raw = values.reduce((a, b) => a + b) / values.length;
        break;
      case AggregationType.weighted:
        raw = values.reduce((a, b) => a + b) / values.length;
        break;
    }
    return (raw * weight).clamp(0.0, 1.0);
  }
}
