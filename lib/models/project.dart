import 'parameter.dart';
import 'fuzzy_object.dart';

class Project {
  String name;
  List<Parameter> parameters;
  List<FuzzyObject> fuzzyObjects;

  Project({
    required this.name,
    List<Parameter>? parameters,
    List<FuzzyObject>? fuzzyObjects,
  })  : parameters = parameters ?? [],
        fuzzyObjects = fuzzyObjects ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'fuzzyObjects': fuzzyObjects.map((o) => o.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        name: json['name'] as String,
        parameters: (json['parameters'] as List<dynamic>)
            .map((p) => Parameter.fromJson(p as Map<String, dynamic>))
            .toList(),
        fuzzyObjects: (json['fuzzyObjects'] as List<dynamic>)
            .map((o) => FuzzyObject.fromJson(o as Map<String, dynamic>))
            .toList(),
      );

  Project copy() => Project(
        name: name,
        parameters: parameters.map((p) => p.copy()).toList(),
        fuzzyObjects: fuzzyObjects.map((o) => o.copy()).toList(),
      );
}
