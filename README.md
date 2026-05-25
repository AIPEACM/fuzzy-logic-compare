# Fuzzy Logic Compare

A Flutter desktop application for defining fuzzy logic parameters as a directed acyclic graph (DAG), creating fuzzy objects with specific values, and comparing multiple objects with visual result trees.

## Features

- **DAG Parameter Structure** — Parameters can contribute to multiple other parameters (not just a tree). Cycle detection prevents circular dependencies.
- **Fuzzy Objects** — Create multiple objects and assign values to each leaf parameter
- **Visual Comparison** — Select 2+ objects and compare them; results displayed in a color-coded tree overlay
- **JSON Persistence** — Save and load projects as JSON files
- **Close Warning** — Warns before closing if there are unsaved changes
- **Cross-Platform** — Supports Linux desktop, Android, and web

## Screenshots

*Launcher Screen* — Create a new project or open an existing JSON file

*Main Editor* — Split-screen layout with parameter list (left) and fuzzy object editor (right)

*Comparison Result* — Floating overlay showing computed scores per parameter

## How to Use

1. **Create a Project**
   - Launch the app and click "New Project"
   - Enter a project name
   - A root parameter is automatically created with the project name

2. **Define Parameters** (Left Panel)
   - Click the **+** button to add new parameters
   - Each parameter shows its weight, aggregation method, and optional max value
   - Click **"Add Contributor"** to link an existing parameter as an input
   - Click the **edit** icon to adjust name, weight, aggregation, and max value
   - Click the **delete** icon to remove a parameter
   - **Root parameters** (those with no parents) don't have weight — they are final outputs

3. **Add Fuzzy Objects** (Right Panel)
   - Click the **+** button to add a new fuzzy object
   - Select an object from the list to edit its values
   - Use sliders to set values (0-1) for each leaf parameter
   - If a max value is set, the display shows normalized values

4. **Compare Objects**
   - Check the checkbox next to 2 or more objects
   - Click the **Compare** button
   - View the color-coded result tree showing computed scores

5. **Save Your Work**
   - **Ctrl+S** — Save (overwrite current file)
   - **Save As...** — Save to a new file
   - **Open Another Project** — Switch to a different JSON file without restarting

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
      "contributorIds": ["durability-id", "comfort-id"]
    },
    {
      "id": "durability-id",
      "name": "Durability",
      "weight": 0.8,
      "aggregation": "avg",
      "contributorIds": [],
      "maxValue": 100
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
│   ├── parameter.dart             # Parameter node (DAG)
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
    ├── parameter_list.dart        # Editable parameter list (DAG)
    ├── fuzzy_object_editor.dart   # Value editor with sliders
    └── result_tree.dart           # Color-coded result tree
```

## Dependencies

- `provider` — State management
- `file_selector` — Native file dialogs
- `package_info_plus` — App version display
- `path_provider` — Default directories
- `window_manager` — Desktop window management (close warning)
- `uuid` — Unique IDs for parameters and objects

## License

This project is licensed under the GPLv3 License. See [LICENSE](LICENSE) for details.
