import 'package:uuid/uuid.dart';

class FuzzyObject {
  final String id;
  String name;
  final Map<String, double> values;

  FuzzyObject({
    String? id,
    required this.name,
    Map<String, double>? values,
  })  : id = id ?? const Uuid().v4(),
        values = values ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'values': values,
      };

  factory FuzzyObject.fromJson(Map<String, dynamic> json) => FuzzyObject(
        id: json['id'] as String,
        name: json['name'] as String,
        values: (json['values'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );

  FuzzyObject copy() => FuzzyObject(
        id: id,
        name: name,
        values: Map.from(values),
      );
}
