class ProjectVersion {
  final int version;
  final String filePath;
  final DateTime savedAt;

  ProjectVersion({
    required this.version,
    required this.filePath,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'filePath': filePath,
        'savedAt': savedAt.toIso8601String(),
      };

  factory ProjectVersion.fromJson(Map<String, dynamic> json) => ProjectVersion(
        version: (json['version'] as num).toInt(),
        filePath: json['filePath'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
