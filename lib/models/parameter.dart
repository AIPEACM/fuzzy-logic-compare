import 'package:uuid/uuid.dart';

enum AggregationType { min, max, avg, weighted }

class ContributorLink {
  final String id;
  double weight;

  ContributorLink({required this.id, this.weight = 1.0});

  Map<String, dynamic> toJson() => {'id': id, 'weight': weight};

  factory ContributorLink.fromJson(Map<String, dynamic> json) => ContributorLink(
        id: json['id'] as String,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );

  ContributorLink copy() => ContributorLink(id: id, weight: weight);
}

class Parameter {
  final String id;
  String name;
  AggregationType aggregation;
  double? maxValue;
  List<ContributorLink> contributors;

  Parameter({
    String? id,
    required this.name,
    this.aggregation = AggregationType.avg,
    this.maxValue,
    List<ContributorLink>? contributors,
  })  : id = id ?? const Uuid().v4(),
        contributors = contributors ?? [];

  bool get isLeaf => contributors.isEmpty;

  List<String> get contributorIds => contributors.map((c) => c.id).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aggregation': aggregation.name,
        'maxValue': maxValue,
        'contributors': contributors.map((c) => c.toJson()).toList(),
      };

  factory Parameter.fromJson(Map<String, dynamic> json) {
    List<ContributorLink> contributors;
    final contributorsJson = json['contributors'] as List<dynamic>?;
    if (contributorsJson != null) {
      contributors = contributorsJson
          .map((c) => ContributorLink.fromJson(c as Map<String, dynamic>))
          .toList();
    } else {
      final contributorIdsJson = json['contributorIds'] as List<dynamic>?
          ?? json['children'] as List<dynamic>?;
      contributors = contributorIdsJson
          ?.map((item) {
            if (item is String) return ContributorLink(id: item);
            return ContributorLink(id: (item as Map<String, dynamic>)['id'] as String);
          })
          .toList() ?? [];
    }

    return Parameter(
      id: json['id'] as String,
      name: json['name'] as String,
      aggregation: AggregationType.values.byName(json['aggregation'] as String),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      contributors: contributors,
    );
  }

  Parameter copy() => Parameter(
        id: id,
        name: name,
        aggregation: aggregation,
        maxValue: maxValue,
        contributors: contributors.map((c) => c.copy()).toList(),
      );
}
