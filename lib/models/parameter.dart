import 'package:uuid/uuid.dart';

enum AggregationType { min, max, avg, weighted }

class Parameter {
  final String id;
  String name;
  double weight;
  AggregationType aggregation;
  double? maxValue;
  List<String> contributorIds;

  Parameter({
    String? id,
    required this.name,
    this.weight = 1.0,
    this.aggregation = AggregationType.avg,
    this.maxValue,
    List<String>? contributorIds,
  })  : id = id ?? const Uuid().v4(),
        contributorIds = contributorIds ?? [];

  bool get isLeaf => contributorIds.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weight': weight,
        'aggregation': aggregation.name,
        'maxValue': maxValue,
        'contributorIds': contributorIds,
      };

  factory Parameter.fromJson(Map<String, dynamic> json) {
    // Handle old format (children: List<Parameter>) and new format (contributorIds: List<String>)
    List<String> contributorIds;
    final contributorIdsJson = json['contributorIds'] as List<dynamic>?;
    if (contributorIdsJson != null) {
      contributorIds = contributorIdsJson.map((c) => c as String).toList();
    } else {
      final childrenJson = json['children'] as List<dynamic>?;
      contributorIds = childrenJson
          ?.map((c) => (c as Map<String, dynamic>)['id'] as String)
          .toList() ?? [];
    }

    return Parameter(
      id: json['id'] as String,
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      aggregation: AggregationType.values.byName(json['aggregation'] as String),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      contributorIds: contributorIds,
    );
  }

  Parameter copy() => Parameter(
        id: id,
        name: name,
        weight: weight,
        aggregation: aggregation,
        maxValue: maxValue,
        contributorIds: List.from(contributorIds),
      );


}
