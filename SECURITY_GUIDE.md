# Nova Security System Guide

## Overview
Nova now includes a comprehensive local authentication system with PIN and biometric support.

## Features Implemented

### 1. PIN Authentication
- **4-digit PIN**: Users can set up a secure 4-digit PIN
- **SHA256 Hashing**: PINs are hashed using SHA256 before storage for security
- **Secure Storage**: PINs are stored using `flutter_secure_storage` (platform-encrypted storage)
- **Visual Feedback**: PIN dots show entered digits with error states

### 2. Biometric Authentication
- **Multi-platform Support**: 
  - Android: Fingerprint, Face, Iris
  - iOS: Face ID, Touch ID
  - Windows: Windows Hello
- **Auto-trigger**: Biometric prompt automatically appears on lock screen
- **Fallback**: Users can manually enter PIN if biometrics fail

### 3. Auto-lock
- **Configurable Timeout**: Choose from 1, 5, 15, 30, or 60 minutes
- **Activity Tracking**: Last active time is tracked and updated
- **App Lifecycle**: Lock screen appears when app resumes from background if timeout exceeded
- **Smart Unlocking**: Unlocking updates the last active time

## How to Use

### Setting Up Security
1. Open Nova app
2. Tap the drawer menu (☰)
3. Select "Security"
4. Enable "PIN Protection"
5. Create a 4-digit PIN
6. Confirm your PIN
7. (Optional) Enable "Biometric Authentication"
8. (Optional) Enable "Auto-lock" and select timeout

### Accessing Security Settings
- **Location**: Drawer menu → Security (🔒 icon)
- **Options**:
  - Enable/Disable PIN Protection
  - Enable/Disable Biometric Authentication
  - Enable/Disable Auto-lock
  - Change Auto-lock Timeout (1-60 minutes)
  - Remove PIN (with confirmation)

### Unlocking the App
When the lock screen appears:

**Option 1: Biometric**
- Biometric prompt appears automatically
- Follow device prompts (fingerprint, face, etc.)

**Option 2: PIN Entry**
- Tap numbers on the PIN pad
- Enter your 4-digit PIN
- Use backspace (⌫) to correct mistakes
- Lock screen dismisses on correct PIN

## Security Architecture

### AuthService (Singleton)
Located: `lib/services/auth_service.dart`

Key Methods:
- `setPin(String pin)` - Hashes and stores PIN
- `verifyPin(String pin)` - Compares hashed PIN
- `isPinSet()` - Checks if PIN exists
- `removePin()` - Deletes stored PIN
- `authenticateWithBiometrics()` - Triggers biometric prompt
- `isBiometricEnabled()` - Checks biometric setting
- `canUseBiometrics()` - Checks device capability
- `shouldLock()` - Determines if app should lock based on timeout
- `updateLastActiveTime()` - Updates activity timestamp

### Storage Keys
- `user_pin` - Hashed PIN (SHA256)
- `biometric_enabled` - Boolean flag
- `auto_lock_enabled` - Boolean flag
- `auto_lock_timeout` - Timeout in minutes
- `last_active_time` - ISO 8601 timestamp

### App Lifecycle Integration
Located: `lib/main.dart`

- `WidgetsBindingObserver` monitors app lifecycle
- `didChangeAppLifecycleState()` checks lock status on resume
- `_checkAuthenticationStatus()` determines if lock screen should show
- `WillPopScope` prevents back button dismissal of lock screen

## Screens

### 1. LockScreen
**Path**: `lib/screens/lock_screen.dart`
- 4-digit PIN pad with numbers 0-9
- Backspace button (⌫)
- Biometric button (🔒)
- Visual PIN dots (4 circles)
- Error state (red dots + shake)
- Auto-triggers biometrics if enabled

### 2. SetupPinScreen
**Path**: `lib/screens/setup_pin_screen.dart`
- Two-step PIN creation
- Step 1: Create PIN
- Step 2: Confirm PIN
- Validation and mismatch detection
- Error messages

### 3. SecuritySettingsScreen
**Path**: `lib/screens/security_settings_screen.dart`
- PIN toggle with setup flow
- Biometric toggle (detects type: Face ID/Fingerprint/Iris)
- Auto-lock toggle
- Timeout selector dropdown
- Remove PIN option with confirmation
- Informational section

## Security Best Practices

### Implemented
✅ SHA256 hashing for PINs
✅ Platform-encrypted secure storage
✅ No plain-text PIN storage
✅ Biometric authentication using platform APIs
✅ Auto-lock timeout
✅ Activity tracking
✅ Lock screen on app resume

### Recommendations for Users
- Choose a PIN that's not easily guessable
- Enable biometric authentication for convenience
- Set auto-lock timeout appropriate for your security needs
- Don't share your PIN with others

## Technical Dependencies

```yaml
dependencies:
  local_auth: ^2.3.0          # Biometric authentication
  flutter_secure_storage: ^9.2.2  # Encrypted storage
  crypto: ^3.0.3               # SHA256 hashing
```

## Future Enhancements (Not Implemented)
- User profiles with different PINs
- Cloud backup encryption using PIN
- PIN change functionality (currently must remove and recreate)
- Longer PINs (6-digit option)
- Pattern lock alternative
- Failed attempt lockout
- Emergency bypass option

## Testing Checklist

- [ ] Set up PIN from security settings
- [ ] Lock screen appears with correct PIN pad
- [ ] Entering correct PIN unlocks app
- [ ] Entering wrong PIN shows error
- [ ] Biometric prompt appears automatically
- [ ] Biometric authentication works
- [ ] Auto-lock triggers after timeout
- [ ] App locks when returning from background (if timeout exceeded)
- [ ] Removing PIN disables lock screen
- [ ] Settings persist across app restarts

## Troubleshooting

### Lock screen not appearing
- Check if PIN is set in Security settings
- Verify auto-lock is enabled
- Ensure timeout has been exceeded

### Biometric not working
- Check device supports biometrics
- Verify biometrics are set up in device settings
- Ensure biometric permission granted
- Toggle biometric setting in Nova security settings

### Can't access security settings
- Open drawer menu (☰) from Notes screen
- Tap "Security" option (🔒 icon)

### Forgot PIN
Currently, there's no recovery mechanism. You would need to:
1. Uninstall and reinstall the app (loses all data), or
2. Clear app data from device settings (loses all data)

**Recommendation**: Remember your PIN or use biometrics as primary method.
