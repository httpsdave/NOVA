# Nova Changelog

## Version 1.1.0 (2024)

### 🎉 Major New Features

#### 1. Backup & Restore System
- **Full Data Backup**: Create complete ZIP backups containing:
  - SQLite database with all notes, tasks, and notebooks
  - All attachments (images, audio, HTML files)
  - Note content and metadata
- **Easy Restore**: One-tap restore from backup files with automatic app restart
- **Backup Management**: 
  - View all backups with file sizes and creation dates
  - Delete old backups to free space
  - Backups stored in Downloads folder for easy access
- **Access**: Settings drawer > "Backup & Restore"

#### 2. Home Screen Widgets (Android)
Three widget types for quick access to your notes:

- **Quick Note Widget** (3x2):
  - Displays total note count
  - Tap to open Nova app
  - Minimal design for at-a-glance info

- **Recent Notes Widget** (4x2):
  - Shows 5 most recent notes
  - Displays title and content preview
  - Tap any note to open Nova

- **Pinned Notes Widget** (4x2):
  - Shows all your pinned notes
  - Keep important notes on home screen
  - Quick access to critical information

**Widget Features**:
- Auto-update when notes change (create, edit, delete, pin)
- Resizable (horizontal and vertical)
- Dark theme matching app design
- See `WIDGETS.md` for detailed documentation

#### 3. Advanced Search Filters
Powerful filtering system to find exactly what you need:

- **Notebook Filter**: Filter by specific notebook
- **Color Filter**: Find notes by color (8 colors supported)
- **Date Range**: Filter by creation date (start and end date)
- **Tags**: Select multiple tags to filter
- **Attachments**: Show only notes with attachments
- **Reminders**: Show only notes with reminders set
- **Pinned Notes**: Show only pinned notes

**Filter UI Features**:
- Filter button in search bar (green when active)
- Badge showing active filter count
- Clear all filters option
- Filters persist during search session
- Enhanced search includes title, description, and tags

### 🔧 Technical Improvements

#### Database
- Optimized search with dynamic SQL queries
- Post-processing for complex filters (attachments)
- No database version change (still v7)

#### Services
- `BackupService`: ZIP creation and extraction
- `WidgetService`: Widget data management and updates
- Enhanced `DatabaseService` with widget auto-update hooks

#### Dependencies Added
- `archive ^3.6.1`: ZIP file operations
- `file_picker ^8.1.4`: Backup file selection
- `home_widget ^0.6.0`: Android widget support

### 📱 Android Native Code
- 3 Kotlin widget providers (QuickNote, RecentNotes, PinnedNotes)
- RemoteViews service for ListView widgets
- 5 XML layout files for widget UI
- Widget metadata and configurations
- AndroidManifest.xml updated with widget receivers

### 🐛 Bug Fixes
- None (all existing features preserved)

### 📝 Notes
- Backup files stored in `Downloads/nova_backup_*.zip`
- Widget data synced via SharedPreferences
- All 30+ existing features working as before
- No breaking changes

---

## Version 1.0.0 (2024)

### Initial Release Features

#### Core Note Features (10)
1. ✏️ Create, edit, and delete notes
2. 🎨 8 color themes for notes
3. 📌 Pin important notes to top
4. 🗑️ Trash/Recycle bin with 30-day auto-delete
5. 🔍 Search notes by title and content
6. 📓 Organize notes in notebooks
7. 🏷️ Tag system for categorization
8. ⏰ Reminder notifications
9. 🔄 Version history (restore previous versions)
10. ✅ Note descriptions

#### Enhanced Content (7)
11. 🖼️ Image attachments with caption support
12. 📷 Take photos directly in notes
13. ✂️ Crop and compress images
14. 🎤 Voice notes with recording
15. 🎨 Drawing canvas in notes
16. 🔍 Photo viewer with zoom/pan
17. 📎 Multiple attachments per note

#### Task Management (5)
18. ✅ Create and manage tasks
19. 📅 Set due dates
20. ⭐ Priority levels (High, Medium, Low)
21. ⏰ Task reminders
22. ✔️ Mark tasks as complete

#### Organization & Views (4)
23. 📊 Statistics dashboard
24. 📚 Notebook management (create, edit, delete)
25. 🎨 Custom notebook colors and icons
26. 📂 Filter notes by notebook

#### Security & Privacy (3)
27. 🔒 Biometric authentication (fingerprint/face)
28. 🔐 PIN/Pattern lock
29. 🔄 Lock timeout settings

#### Bulk Operations (3)
30. ☑️ Multi-select notes
31. 🗑️ Bulk delete
32. 📌 Bulk pin/unpin

#### User Experience (3)
33. 🌓 Dark/Light theme
34. 🎯 Onboarding tutorial
35. 📱 Material Design 3 UI

### Technical Stack
- **Framework**: Flutter 3.x
- **Database**: SQLite (sqflite package) v7
- **State Management**: Provider
- **Key Packages**:
  - flutter_local_notifications: Push notifications
  - local_auth: Biometric authentication
  - flutter_secure_storage: Secure credential storage
  - image_cropper: Image editing
  - flutter_sound: Audio recording
  - flutter_drawing_board: Drawing canvas
  - photo_view: Image viewing
  - share_plus: Sharing functionality

### Supported Platforms
- ✅ Android
- ⏳ iOS (planned)
- ⏳ Web (planned)
- ⏳ Desktop (planned)

---

## Roadmap

### Version 1.2.0 (Planned)
- [ ] Cloud sync (Google Drive, Dropbox)
- [ ] Markdown editor mode
- [ ] Rich text formatting toolbar
- [ ] Export to PDF
- [ ] Widget customization (themes, sizes)
- [ ] Quick note from widget
- [ ] Folder system (nested organization)

### Version 1.3.0 (Planned)
- [ ] Collaboration (shared notes)
- [ ] Note templates
- [ ] Custom reminder intervals
- [ ] Recurring tasks
- [ ] Task subtasks
- [ ] Kanban board view

### Version 2.0.0 (Planned)
- [ ] iOS app release
- [ ] Web app release
- [ ] Desktop apps (Windows, macOS, Linux)
- [ ] End-to-end encryption
- [ ] Multi-language support
- [ ] Accessibility improvements

---

## Contributing
Contributions are welcome! Please read the contributing guidelines before submitting pull requests.

## License
This project is licensed under the MIT License.

## Support
For issues, feature requests, or questions, please open an issue on GitHub.
