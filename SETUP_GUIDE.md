# Nova - Note Taking App Setup Guide

## Features Implemented

✅ **Notes Management**
- Create, edit, and delete notes
- Pin important notes to the top
- Color-coded notes (8 colors available)
- Search functionality
- Rich text editing with title and content

✅ **Task Scheduling & Calendar**
- Full calendar view with task markers
- Create, edit, and delete tasks
- Task priorities (Low, Medium, High)
- Mark tasks as complete
- View tasks by date

✅ **Reminders & Notifications**
- Set reminders for notes
- Set reminders for tasks
- Scheduled notifications
- Notification permissions handled
- Boot-completed notification restoration

✅ **Theme Support**
- Light mode
- Dark mode
- Automatic theme switching
- Modern Material 3 design
- Persistent theme selection

✅ **Modern UI/UX**
- Material Design 3
- Smooth animations
- Responsive grid layout for notes
- Interactive calendar
- Bottom navigation
- Floating action buttons
- Slide-to-delete gestures

## Project Structure

```
lib/
├── main.dart                 # App entry point with navigation
├── models/
│   ├── note.dart            # Note data model
│   └── task.dart            # Task data model
├── screens/
│   ├── notes_screen.dart    # Notes list and management
│   ├── note_editor_screen.dart  # Note editing interface
│   └── tasks_screen.dart    # Calendar and task management
├── services/
│   ├── database_service.dart    # SQLite database operations
│   └── notification_service.dart # Local notifications
└── providers/
    └── theme_provider.dart   # Theme state management
```

## Running the App

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code with Flutter extension
- Android device/emulator or iOS device/simulator

### Steps to Run

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run on Android**
   ```bash
   flutter run
   ```

3. **Run on iOS** (Mac only)
   ```bash
   flutter run
   ```

4. **Build APK** (Android)
   ```bash
   flutter build apk
   ```

## Key Technologies Used

- **Flutter 3.x** - Cross-platform UI framework
- **Provider** - State management
- **SQLite (sqflite)** - Local database
- **flutter_local_notifications** - Push notifications
- **table_calendar** - Calendar widget
- **shared_preferences** - Theme persistence
- **Material Design 3** - Modern UI components

## Features in Detail

### Notes
- **Create Notes**: Tap the + button to create a new note
- **Edit Notes**: Tap any note to edit it
- **Pin Notes**: Use the menu to pin important notes to the top
- **Color Coding**: Choose from 8 different colors for organization
- **Reminders**: Set date/time reminders for notes
- **Search**: Search through note titles and content
- **Delete**: Swipe or use menu to delete notes

### Tasks
- **Calendar View**: Visual calendar showing task distribution
- **Add Tasks**: Create tasks with title, description, priority
- **Set Due Dates**: Choose specific dates and times
- **Reminders**: Get notified before task deadlines
- **Mark Complete**: Check off completed tasks
- **Priority Levels**: Low, Medium, High priority indicators
- **Edit/Delete**: Manage tasks through the popup menu

### Theme
- **Toggle Themes**: Use the theme icon in the app bar
- **Auto Dark Mode**: Respects system settings when set to auto
- **Persistent**: Your theme choice is saved across app restarts

## Database Schema

### Notes Table
- id (PRIMARY KEY)
- title
- content
- createdAt
- updatedAt
- color
- isPinned
- reminderDateTime

### Tasks Table
- id (PRIMARY KEY)
- title
- description
- dueDate
- isCompleted
- createdAt
- completedAt
- reminderDateTime
- priority

## Notification Permissions

The app automatically requests notification permissions on:
- Android 13+
- iOS

Make sure to grant permissions when prompted for full functionality.

## Tips for Best Experience

1. **Organize with Colors**: Use different colors for different categories
2. **Pin Important Notes**: Keep frequently accessed notes at the top
3. **Set Reminders**: Never forget important tasks and notes
4. **Use Search**: Quickly find notes with the search feature
5. **Calendar View**: Plan your week/month with the calendar
6. **Priority Tasks**: Use priority levels to focus on important tasks

## Troubleshooting

### Notifications Not Working
- Check app notification permissions in device settings
- Ensure battery optimization is disabled for the app
- For Android: Verify exact alarm permissions

### Dark Mode Issues
- Try toggling the theme manually
- Check system dark mode settings
- Restart the app

### Database Issues
- Clear app data to reset database
- Uninstall and reinstall the app

## Future Enhancements (Optional)

- Cloud sync
- Categories/folders for notes
- Voice notes
- Note sharing
- Widgets
- Biometric lock
- Export/import functionality
- Markdown support
- Attachments (images, files)

---

**Enjoy using Nova!** 📝✨
