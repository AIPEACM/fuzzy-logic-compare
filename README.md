# Fuzzy Logic Compare

A Flutter desktop application for defining hierarchical fuzzy logic parameters, creating fuzzy objects with specific values, and comparing multiple objects with visual result trees.

## Features

- **Hierarchical Parameter Trees** — Define fuzzy logic parameters in a tree structure with weights (0-1) and aggregation methods (min, max, avg, weighted)
- **Fuzzy Objects** — Create multiple objects and assign values to each leaf parameter
- **Visual Comparison** — Select 2+ objects and compare them; results displayed in a color-coded tree overlay
- **JSON Persistence** — Save and load projects as JSON files
- **Cross-Platform** — Supports Linux desktop, Android, and web

## Screenshots

*Launcher Screen* — Create a new project or open an existing JSON file

*Main Editor* — Split-screen layout with parameter tree (left) and fuzzy object editor (right)

*Comparison Result* — Floating overlay showing computed scores per parameter

## How to Use

1. **Create a Project**
   - Launch the app and click "New Project"
   - Enter a project name

2. **Define Parameters** (Left Panel)
   - Click the **+** button to add root parameters
   - Use the expand/collapse arrows to navigate the tree
   - Click **+** on any parameter to add child parameters
   - Click the **edit** icon to adjust name, weight, and aggregation method
   - Click the **delete** icon to remove a parameter (and its children)

3. **Add Fuzzy Objects** (Right Panel)
   - Click the **+** button to add a new fuzzy object
   - Select an object from the list to edit its values
   - Use sliders to set values (0-1) for each leaf parameter

4. **Compare Objects**
   - Check the checkbox next to 2 or more objects
   - Click the **Compare** button
   - View the color-coded result tree showing computed scores

5. **Save Your Work**
   - **Ctrl+S** — Save (overwrite current file)
   - **Save As...** — Save to a new file

## JSON File Format

```json
{
  "name": "My Project",
  "parameters": [
    {
      "id": "...",
      "name": "Quality",
      "weight": 1.0,
      "aggregation": "avg",
      "children": [
        {
          "id": "...",
          "name": "Durability",
          "weight": 0.8,
          "aggregation": "avg",
          "children": []
        }
      ]
    }
  ],
  "fuzzyObjects": [
    {
      "id": "...",
      "name": "Product A",
      "values": {
        "durability-id": 0.85
      }
    }
  ]
}
```

## Running the App

### Linux Desktop
```bash
flutter run -d linux
```

### Android
```bash
flutter run -d android
```

### Web
```bash
flutter run -d chrome
```

### Build Release
```bash
flutter build linux
flutter build apk
flutter build web
```

## Architecture

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── project.dart               # Project data model
│   ├── parameter.dart             # Parameter tree node
│   └── fuzzy_object.dart          # Fuzzy object with values
├── controllers/
│   └── project_controller.dart    # State management (ChangeNotifier)
├── services/
│   └── json_storage.dart          # File open/save logic
├── screens/
│   ├── launcher_screen.dart       # New / Open project
│   ├── main_editor_screen.dart    # Split-screen editor
│   ├── comparison_overlay.dart    # Comparison result dialog
│   └── settings_screen.dart       # App settings & help
└── widgets/
    ├── parameter_tree.dart        # Editable parameter tree
    ├── fuzzy_object_editor.dart   # Value editor with sliders
    └── result_tree.dart           # Color-coded result tree
```

## Dependencies

- `provider` — State management
- `file_selector` — Native file dialogs
- `package_info_plus` — App version display
- `path_provider` — Default directories
- `uuid` — Unique IDs for parameters and objects

## License

This project is licensed under the GPLv3 License. See [LICENSE](LICENSE) for details.
