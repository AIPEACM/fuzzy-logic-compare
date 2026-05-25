import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/project_controller.dart';
import 'screens/launcher_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProjectController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuzzy Logic Compare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const LauncherScreen(),
    );
  }
}
