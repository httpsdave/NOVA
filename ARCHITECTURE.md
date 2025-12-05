# Nova - Technical Architecture

## App Overview
Nova is a comprehensive note-taking and task management application with modern Material Design 3 UI and robust local storage.

## Core Architecture

### State Management
- **Provider Pattern**: Used for theme state management
- **setState**: Used for screen-level state updates
- Reactive UI updates on data changes

### Data Layer

#### Models
- **Note Model**: Stores note information with support for:
  - Title, content, timestamps
  - Color coding (8 predefined colors)
  - Pin/unpin functionality
  - Reminder date/time

- **Task Model**: Stores task information with:
  - Title, description
  - Due date, priority levels
  - Completion status
  - Reminder date/time

#### Database (SQLite)
- **DatabaseService**: Singleton pattern for database operations
- Two tables: `notes` and `tasks`
- CRUD operations for both entities
- Query support for date-based task filtering
- Search functionality for notes

### Services

#### NotificationService
- Handles local notifications using flutter_local_notifications
- Schedules future notifications using timezone
- Supports both Android and iOS
- Exact alarm permissions for Android
- Boot-completed notification restoration

#### ThemeProvider
- Manages app theme state (Light/Dark/System)
- Persists theme preference using SharedPreferences
- Provides Material Design 3 themes with custom color schemes

### UI Layer

#### Navigation Structure
```
MainScreen (BottomNavigationBar)
├── NotesScreen
│   └── NoteEditorScreen
└── TasksScreen
```

#### Screens

1. **NotesScreen**
   - Grid layout for notes (2 columns)
   - Search functionality
   - Pull-to-refresh
   - Swipe actions for note management
   - Color-coded note cards
   - Pin indicator for pinned notes

2. **NoteEditorScreen**
   - Auto-save on back navigation
   - Color picker (horizontal scroll)
   - Reminder date/time picker
   - Rich text input with title and content
   - Background color changes based on selection

3. **TasksScreen**
   - Full calendar view with task markers
   - Date selector with visual indicators
   - Task list filtered by selected date
   - Priority-based color coding
   - Task completion checkboxes
   - Reminder scheduling

## Key Features Implementation

### Notifications
```dart
- Request permissions on app startup
- Schedule notifications with exact timing
- Cancel notifications when items deleted
- Support for both notes and tasks
- Android: Requires SCHEDULE_EXACT_ALARM permission
- iOS: Requires notification permissions
```

### Theme System
```dart
- Three modes: Light, Dark, System
- Persistent across app restarts
- Dynamic color schemes with Material 3
- Smooth theme transitions
- Custom color palettes for both modes
```

### Data Persistence
```dart
- SQLite for structured data
- SharedPreferences for settings
- Automatic database initialization
- Migration-ready schema design
```

### Color System
8 predefined colors for notes:
1. White (adapts to theme)
2. Soft Orange
3. Soft Green
4. Soft Blue
5. Soft Purple
6. Soft Pink
7. Soft Yellow
8. Soft Teal

## Dependencies

### Core Flutter Packages
- `provider: ^6.1.2` - State management
- `sqflite: ^2.3.3+1` - SQLite database
- `path_provider: ^2.1.3` - File system paths
- `shared_preferences: ^2.3.2` - Key-value storage

### UI Packages
- `google_fonts: ^6.2.1` - Custom fonts (optional)
- `table_calendar: ^3.1.2` - Calendar widget
- `flutter_slidable: ^3.1.1` - Swipe actions
- `flutter_staggered_grid_view: ^0.7.0` - Masonry grid

### Functionality Packages
- `flutter_local_notifications: ^18.0.1` - Local notifications
- `timezone: ^0.9.4` - Timezone support for notifications
- `intl: ^0.19.0` - Date formatting
- `uuid: ^4.4.2` - Unique ID generation

## File Structure
```
lib/
├── main.dart                     # App entry point
├── models/
│   ├── note.dart                # Note data model
│   └── task.dart                # Task data model
├── providers/
│   └── theme_provider.dart      # Theme state management
├── screens/
│   ├── notes_screen.dart        # Notes list view
│   ├── note_editor_screen.dart  # Note creation/editing
│   └── tasks_screen.dart        # Calendar & tasks view
└── services/
    ├── database_service.dart    # SQLite operations
    └── notification_service.dart # Notification handling
```

## Platform-Specific Configurations

### Android (AndroidManifest.xml)
```xml
- RECEIVE_BOOT_COMPLETED: Restore notifications after reboot
- POST_NOTIFICATIONS: Show notifications (Android 13+)
- SCHEDULE_EXACT_ALARM: Precise notification timing
- USE_EXACT_ALARM: Alternative for exact alarms
- VIBRATE: Notification vibration
```

### iOS (Info.plist)
- Notification permissions requested at runtime
- Background modes for notifications

## Performance Considerations

1. **Database Queries**
   - Indexed primary keys
   - Optimized date-based queries
   - Batch operations where possible

2. **UI Rendering**
   - Efficient grid layouts
   - Lazy loading with ListView.builder
   - Minimal widget rebuilds

3. **Memory Management**
   - Proper disposal of controllers
   - Singleton services to avoid duplication
   - Efficient state updates

## Future Enhancement Possibilities

1. **Cloud Sync**
   - Firebase integration
   - User authentication
   - Real-time sync

2. **Advanced Features**
   - Rich text formatting
   - Voice notes
   - Image attachments
   - Note sharing
   - Categories/folders
   - Tags

3. **UI Enhancements**
   - Custom themes
   - Widget support
   - Tablet layouts
   - Animations

4. **Security**
   - Biometric lock
   - Encrypted database
   - Secure notes

## Testing Recommendations

1. **Unit Tests**
   - Model serialization/deserialization
   - Database CRUD operations
   - Theme provider logic

2. **Widget Tests**
   - Screen navigation
   - User interactions
   - Form validation

3. **Integration Tests**
   - End-to-end workflows
   - Notification scheduling
   - Data persistence

## Deployment Checklist

- [ ] Update app version in pubspec.yaml
- [ ] Test on physical devices (Android & iOS)
- [ ] Verify notification permissions
- [ ] Test theme switching
- [ ] Check database migrations
- [ ] Test offline functionality
- [ ] Verify UI on different screen sizes
- [ ] Build release APK/IPA
- [ ] Test release build

---

**Architecture Version**: 1.0.0  
**Last Updated**: December 2025
