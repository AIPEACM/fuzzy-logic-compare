import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class JsonStorage {
  static const String _extension = 'json';

  static Future<Project?> openProject() async {
    const typeGroup = XTypeGroup(
      label: 'JSON files',
      extensions: [_extension],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return Project.fromJson(json);
  }

  static Future<String?> saveProject(Project project, {String? path}) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(project.toJson());
    final bytes = utf8.encode(jsonStr);

    if (path != null) {
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }

    final suggested = '${project.name}_v${project.version}.$_extension';
    final location = await getSaveLocation(
      suggestedName: suggested,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON files', extensions: [_extension]),
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
}
