import 'parameter.dart';
import 'fuzzy_object.dart';

class Project {
  String name;
  bool isTree;
  List<Parameter> parameters;
  List<FuzzyObject> fuzzyObjects;

  Project({
    required this.name,
    this.isTree = false,
    List<Parameter>? parameters,
    List<FuzzyObject>? fuzzyObjects,
  })  : parameters = parameters ?? [],
        fuzzyObjects = fuzzyObjects ?? [];

  Parameter? getParameterById(String id) {
    try {
      return parameters.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Parameter> get roots => parameters
      .where((p) => !parameters.any((other) => other.contributorIds.contains(p.id)))
      .toList();

  List<Parameter> get leaves => parameters.where((p) => p.isLeaf).toList();

  bool get hasCycle {
    final visited = <String>{};
    for (final param in parameters) {
      if (_hasCycleFrom(param.id, <String>{}, visited)) return true;
    }
    return false;
  }

  bool _hasCycleFrom(String id, Set<String> path, Set<String> visited) {
    if (path.contains(id)) return true;
    if (visited.contains(id)) return false;
    path.add(id);
    visited.add(id);
    final param = getParameterById(id);
    if (param != null) {
      for (final cid in param.contributorIds) {
        if (_hasCycleFrom(cid, path, visited)) return true;
      }
    }
    path.remove(id);
    return false;
  }

  List<String> getLeafIdsFor(String parameterId) {
    final ids = <String>{};
    final visited = <String>{};
    _collectLeafIds(parameterId, ids, visited);
    return ids.toList();
  }

  void _collectLeafIds(String id, Set<String> ids, Set<String> visited) {
    if (visited.contains(id)) return;
    visited.add(id);
    final param = getParameterById(id);
    if (param == null) return;
    if (param.isLeaf) {
      ids.add(id);
      return;
    }
    for (final cid in param.contributorIds) {
      _collectLeafIds(cid, ids, visited);
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'isTree': isTree,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'fuzzyObjects': fuzzyObjects.map((o) => o.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    final allParameters = <Parameter>[];

    void flatten(dynamic paramJson) {
      final map = paramJson as Map<String, dynamic>;
      final param = Parameter.fromJson(map);
      allParameters.add(param);
      // Old format had nested children - flatten them into the list
      final children = map['children'] as List<dynamic>?;
      if (children != null) {
        for (final child in children) {
          flatten(child);
        }
      }
    }

    final paramsJson = json['parameters'] as List<dynamic>? ?? [];
    for (final p in paramsJson) {
      flatten(p);
    }

    return Project(
      name: json['name'] as String,
      isTree: json['isTree'] as bool? ?? false,
      parameters: allParameters,
      fuzzyObjects: (json['fuzzyObjects'] as List<dynamic>?)
              ?.map((o) => FuzzyObject.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Project copy() => Project(
        name: name,
        isTree: isTree,
        parameters: parameters.map((p) => p.copy()).toList(),
        fuzzyObjects: fuzzyObjects.map((o) => o.copy()).toList(),
      );
}
