import 'package:uuid/uuid.dart';

enum AggregationType { min, max, avg, weighted }

class Parameter {
  final String id;
  String name;
  double weight;
  AggregationType aggregation;
  final List<Parameter> children;

  Parameter({
    String? id,
    required this.name,
    this.weight = 1.0,
    this.aggregation = AggregationType.avg,
    List<Parameter>? children,
  })  : id = id ?? const Uuid().v4(),
        children = children ?? [];

  bool get isLeaf => children.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weight': weight,
        'aggregation': aggregation.name,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory Parameter.fromJson(Map<String, dynamic> json) => Parameter(
        id: json['id'] as String,
        name: json['name'] as String,
        weight: (json['weight'] as num).toDouble(),
        aggregation: AggregationType.values.byName(json['aggregation'] as String),
        children: (json['children'] as List<dynamic>)
            .map((c) => Parameter.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Parameter copy() {
    return Parameter(
      id: id,
      name: name,
      weight: weight,
      aggregation: aggregation,
      children: children.map((c) => c.copy()).toList(),
    );
  }

  void collectLeafIds(List<String> ids) {
    if (isLeaf) {
      ids.add(id);
    } else {
      for (final child in children) {
        child.collectLeafIds(ids);
      }
    }
  }

  List<String> get leafIds {
    final ids = <String>[];
    collectLeafIds(ids);
    return ids;
  }
}
