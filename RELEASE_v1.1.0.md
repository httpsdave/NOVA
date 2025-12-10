# Nova v1.1.0 Release Notes

## 🚀 Second Release - Bug Fixes & Improvements

**Release Date**: December 10, 2025  
**Version**: 1.1.0+2

---

## 🐛 Critical Bug Fixes

### ✅ Reminder & Notification System
- **Fixed immediate notifications**: Reminders set for NOW or within 1 minute now trigger immediately
- **Calendar reminders**: Fixed error when saving date reminders on calendar  
- **Better reliability**: Improved notification scheduling for all scenarios

### ✅ Auto-Save Functionality
- **Auto-save on back button**: Notes now automatically save when pressing back (not just save button)
- **Rich text editor**: Added auto-save support in rich note editor
- **Prevents data loss**: No more lost work from unsaved changes

### ✅ Biometric Authentication
- **Fixed enable failure**: Biometric lock now properly enables without errors
- **Enhanced checks**: Validates device capability, support, and biometric enrollment
- **Better feedback**: Clearer error messages when biometrics unavailable

### ✅ Attachment Handling  
- **Fixed image/voice saving**: Attachments now properly save on existing notes (not just new ones)
- **Proper persistence**: New attachments correctly associated with notes during updates
- **Both editors fixed**: Works in standard and rich text note editors

---

## 📋 Existing Features (from v1.0.0)

All features from the first release are included:
- ✅ Rich text notes with Markdown support
- ✅ Voice recording and playback
- ✅ Drawing canvas with multiple tools
- ✅ Version history and restore
- ✅ Note sorting (10 options)
- ✅ Multi-select and bulk operations
- ✅ Notebooks and tags
- ✅ Task management with calendar
- ✅ Biometric lock
- ✅ Dark/Light theme
- ✅ Note templates (10+ templates)
- ✅ PDF export/share/print
- ✅ Home screen widgets
- ✅ Backup & restore system
- ✅ Advanced search filters

---

## 📦 Build Instructions

### Prerequisites
1. **Enable Developer Mode** (Windows):
   - Press `Win + I` to open Settings
   - Go to: **Settings** → **Privacy & Security** → **For developers**
   - Toggle **Developer Mode** to ON
   - Restart if prompted

### Building the APK

```powershell
# Clean previous builds
flutter clean

# Build release APK
flutter build apk --release
```

The APK will be created at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📤 GitHub Release Instructions

1. **Go to your repository**: https://github.com/httpsdave/NOVA

2. **Create new release**:
   - Click "Releases" → "Draft a new release"
   - Tag version: `v1.1.0`
   - Release title: `Nova v1.1.0 - Bug Fixes & Improvements`

3. **Release description** (copy this):

```markdown
## 🐛 Critical Bug Fixes

### Reminder & Notification System
- Fixed immediate notifications for reminders set to NOW
- Fixed calendar reminder saving errors
- Improved notification scheduling reliability

### Auto-Save Functionality  
- Notes now auto-save when pressing back button
- Added auto-save to rich text editor
- Prevents accidental data loss

### Biometric Authentication
- Fixed biometric lock enable failure
- Enhanced device capability validation
- Better error handling and feedback

### Attachment Handling
- Fixed image/voice saving on existing notes
- Proper attachment persistence during updates
- Works in both standard and rich text editors

## 📱 Installation
Download `app-release.apk` and install on your Android device.

**Note**: You may need to enable "Install from Unknown Sources" in your device settings.

## 🔗 Full Changelog
See [CHANGELOG.md](https://github.com/httpsdave/NOVA/blob/main/CHANGELOG.md) for complete details.
```

4. **Upload APK**:
   - Drag and drop `app-release.apk` to the assets section
   - Or click "Attach binaries" and select the file

5. **Publish release**: Click "Publish release"

---

## 📊 File Information

**APK Name**: `app-release.apk`  
**Version Code**: 2  
**Version Name**: 1.1.0  
**Min SDK**: 21 (Android 5.0)  
**Target SDK**: 34 (Android 14)

---

## ✅ Pre-Release Checklist

- [x] Version bumped to 1.1.0+2 in `pubspec.yaml`
- [x] CHANGELOG.md updated with bug fixes
- [x] All 4 critical bugs fixed:
  - [x] Reminder notifications
  - [x] Auto-save on back
  - [x] Biometric authentication
  - [x] Attachment saving
- [ ] Enable Developer Mode on Windows
- [ ] Build release APK
- [ ] Test APK on device
- [ ] Upload to GitHub
- [ ] Create release v1.1.0

---

## 🎯 Next Steps

1. Enable Developer Mode in Windows Settings
2. Run: `flutter build apk --release`
3. Locate APK: `build/app/outputs/flutter-apk/app-release.apk`
4. Test on Android device
5. Upload to GitHub releases
6. Share with users!

---

**Questions or issues?** Check the documentation:
- `CHANGELOG.md` - Complete version history
- `SETUP_GUIDE.md` - Setup instructions
- `WIDGETS.md` - Widget documentation
- `SECURITY_GUIDE.md` - Security features
