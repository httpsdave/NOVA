# Nova Home Screen Widgets

Nova supports three types of Android home screen widgets to give you quick access to your notes.

## Widget Types

### 1. Quick Note Widget
- **Size**: 3x2 cells (180dp x 180dp minimum)
- **Features**:
  - Displays total note count
  - Tap to open Nova app
  - Shows app icon and title
- **Use Case**: Quick overview of your note collection

### 2. Recent Notes Widget
- **Size**: 4x2 cells (250dp x 180dp minimum)
- **Features**:
  - Shows 5 most recent notes
  - Displays note title and preview
  - Tap any note to open Nova
- **Use Case**: Fast access to recently created or updated notes

### 3. Pinned Notes Widget
- **Size**: 4x2 cells (250dp x 180dp minimum)
- **Features**:
  - Shows all pinned notes
  - Displays note title and preview
  - Tap any note to open Nova
- **Use Case**: Keep important notes visible on your home screen

## Adding Widgets to Home Screen

1. Long-press on your Android home screen
2. Tap "Widgets" in the menu
3. Find "Nova" in the widget list
4. Drag your desired widget to the home screen
5. Resize if needed (all widgets support horizontal and vertical resizing)

## Widget Updates

Widgets automatically update when you:
- Create a new note
- Edit an existing note
- Delete or restore a note
- Pin or unpin a note

The widget data is synced instantly through the app's SharedPreferences.

## Technical Details

### Architecture
- **Flutter Layer**: `lib/services/widget_service.dart` manages widget data
- **Native Layer**: Kotlin widget providers in `android/app/src/main/kotlin/`
- **Data Bridge**: `home_widget` package (v0.6.0) for Flutter-Android communication
- **Layouts**: XML layouts in `android/app/src/main/res/layout/`

### Data Storage
Widget data is stored in SharedPreferences with these keys:
- `note_count`: Total number of active notes (integer)
- `recent_notes`: JSON array of 5 most recent notes
- `pinned_notes`: JSON array of all pinned notes

Each note object contains:
```json
{
  "id": "note_id",
  "title": "Note Title",
  "preview": "First 100 characters of content..."
}
```

### Widget Files
```
android/app/src/main/
├── kotlin/com/nova/nova/
│   ├── QuickNoteWidgetProvider.kt
│   ├── RecentNotesWidgetProvider.kt
│   ├── PinnedNotesWidgetProvider.kt
│   └── NotesListService.kt
├── res/
│   ├── layout/
│   │   ├── quick_note_widget.xml
│   │   ├── recent_notes_widget.xml
│   │   ├── pinned_notes_widget.xml
│   │   └── note_item.xml
│   ├── xml/
│   │   ├── quick_note_widget_info.xml
│   │   ├── recent_notes_widget_info.xml
│   │   └── pinned_notes_widget_info.xml
│   └── drawable/
│       └── widget_background.xml
└── AndroidManifest.xml (widget receivers registered)
```

## Customization

### Changing Widget Colors
Edit `android/app/src/main/res/drawable/widget_background.xml` to change background color:
```xml
<solid android:color="#1F1F1F" /> <!-- Change this hex color -->
```

Edit layout XML files to change text colors:
```xml
android:textColor="#FFFFFF" <!-- Change this hex color -->
```

### Changing Widget Size
Edit widget info XML files to adjust minimum sizes:
```xml
android:minWidth="250dp"
android:minHeight="180dp"
```

## Troubleshooting

### Widget Not Updating
1. Force-close and reopen the Nova app
2. Remove and re-add the widget to your home screen
3. Check Android Settings > Apps > Nova > Permissions

### Widget Shows "0 notes" or Empty List
1. Ensure you have created notes in the app
2. Open the app to trigger widget refresh
3. Pin some notes to see them in the Pinned Notes widget

### Widget Tap Not Opening App
1. Ensure Nova app is installed and not disabled
2. Check that the MainActivity is properly registered in AndroidManifest.xml
3. Reinstall the app if the issue persists

## Performance Considerations

- Widgets use minimal battery (update on demand only)
- No periodic updates (updatePeriodMillis = 0)
- Data is cached in SharedPreferences for fast access
- ListView in Recent/Pinned widgets uses RemoteViews for efficiency
- Widget updates are asynchronous and non-blocking

## Future Enhancements

Potential improvements for future versions:
- Widget configuration activities (choose notebook to display)
- Direct note creation from Quick Note widget
- Color-coded note items based on note color
- Date/time stamps on note items
- Expandable widgets showing more notes
- Dark/light theme support matching system theme
