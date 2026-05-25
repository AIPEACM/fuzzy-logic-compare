import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class JsonStorage {
  static Future<Project?> openProjectAtPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final jsonStr = utf8.decode(bytes);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static Future<(Project, String)?> openProject() async {
    const typeGroup = XTypeGroup(
      label: 'Fuzzy Logic files',
      extensions: ['jsonfz', 'json'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return (Project.fromJson(json), file.path);
  }

  static Future<String?> saveProject(Project project, {String? path}) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(project.toJson());
    final bytes = utf8.encode(jsonStr);

    if (path != null) {
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }

    final suggested = '${project.name}.jsonfz';
    final location = await getSaveLocation(
      suggestedName: suggested,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Fuzzy Logic files', extensions: ['jsonfz']),
      ],
    );
    if (location == null) return null;

    final file = File(location.path);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<String?> getDefaultDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return dir?.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  // Template operations (parameters only, no fuzzy objects)
  static Future<String?> saveTemplate(List<dynamic> parametersJson) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert({
      'parameters': parametersJson,
    });
    final bytes = utf8.encode(jsonStr);

    final location = await getSaveLocation(
      suggestedName: 'template.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON files', extensions: ['json']),
      ],
    );
    if (location == null) return null;

    final file = File(location.path);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<List<dynamic>?> loadTemplate() async {
    const typeGroup = XTypeGroup(
      label: 'JSON files',
      extensions: ['json'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return json['parameters'] as List<dynamic>?;
  }
}
