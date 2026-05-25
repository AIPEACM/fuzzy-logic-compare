import 'parameter.dart';
import 'fuzzy_object.dart';

class Project {
  String name;
  int version;
  List<Parameter> parameters;
  List<FuzzyObject> fuzzyObjects;

  Project({
    required this.name,
    this.version = 1,
    List<Parameter>? parameters,
    List<FuzzyObject>? fuzzyObjects,
  })  : parameters = parameters ?? [],
        fuzzyObjects = fuzzyObjects ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'fuzzyObjects': fuzzyObjects.map((o) => o.toJson()).toList(),
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
      );

  Project copy() => Project(
        name: name,
        version: version,
        parameters: parameters.map((p) => p.copy()).toList(),
        fuzzyObjects: fuzzyObjects.map((o) => o.copy()).toList(),
      );
}
