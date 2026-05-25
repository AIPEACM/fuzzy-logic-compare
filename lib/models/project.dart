import 'parameter.dart';
import 'fuzzy_object.dart';
import 'project_version.dart';

class Project {
  String name;
  int version;
  List<Parameter> parameters;
  List<FuzzyObject> fuzzyObjects;
  List<ProjectVersion> versionHistory;

  Project({
    required this.name,
    this.version = 1,
    List<Parameter>? parameters,
    List<FuzzyObject>? fuzzyObjects,
    List<ProjectVersion>? versionHistory,
  })  : parameters = parameters ?? [],
        fuzzyObjects = fuzzyObjects ?? [],
        versionHistory = versionHistory ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'fuzzyObjects': fuzzyObjects.map((o) => o.toJson()).toList(),
        'versionHistory': versionHistory.map((v) => v.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        name: json['name'] as String,
        version: (json['version'] as num?)?.toInt() ?? 1,
        parameters: (json['parameters'] as List<dynamic>)
            .map((p) => Parameter.fromJson(p as Map<String, dynamic>))
            .toList(),
        fuzzyObjects: (json['fuzzyObjects'] as List<dynamic>)
            .map((o) => FuzzyObject.fromJson(o as Map<String, dynamic>))
            .toList(),
        versionHistory: (json['versionHistory'] as List<dynamic>?)
                ?.map((v) => ProjectVersion.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Project copy() => Project(
        name: name,
        version: version,
        parameters: parameters.map((p) => p.copy()).toList(),
        fuzzyObjects: fuzzyObjects.map((o) => o.copy()).toList(),
        versionHistory: versionHistory.map((v) => v).toList(),
      );
}
