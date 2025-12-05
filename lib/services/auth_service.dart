import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService instance = AuthService._init();
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  AuthService._init();

  // Keys for secure storage
  static const String _keyPin = 'user_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyAutoLockEnabled = 'auto_lock_enabled';
  static const String _keyAutoLockTimeout = 'auto_lock_timeout'; // in minutes
  static const String _keyLastActiveTime = 'last_active_time';

  // Hash the PIN for security
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Set PIN
  Future<void> setPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _secureStorage.write(key: _keyPin, value: hashedPin);
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _keyPin);
    if (storedHash == null) return false;
    
    final hashedPin = _hashPin(pin);
    return hashedPin == storedHash;
  }

  // Check if PIN is set
  Future<bool> isPinSet() async {
    final pin = await _secureStorage.read(key: _keyPin);
    return pin != null && pin.isNotEmpty;
  }

  // Remove PIN
  Future<void> removePin() async {
    await _secureStorage.delete(key: _keyPin);
  }

  // Biometric settings
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // Check if biometrics are available
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Nova',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Auto-lock settings
  Future<void> setAutoLockEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyAutoLockEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isAutoLockEnabled() async {
    final value = await _secureStorage.read(key: _keyAutoLockEnabled);
    return value == 'true';
  }

  Future<void> setAutoLockTimeout(int minutes) async {
    await _secureStorage.write(
      key: _keyAutoLockTimeout,
      value: minutes.toString(),
    );
  }

  Future<int> getAutoLockTimeout() async {
    final value = await _secureStorage.read(key: _keyAutoLockTimeout);
    return int.tryParse(value ?? '5') ?? 5; // Default 5 minutes
  }

  // Track activity for auto-lock
  Future<void> updateLastActiveTime() async {
    await _secureStorage.write(
      key: _keyLastActiveTime,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastActiveTime() async {
    final value = await _secureStorage.read(key: _keyLastActiveTime);
    if (value == null) return null;
    return DateTime.parse(value);
  }

  // Check if app should be locked
  Future<bool> shouldLock() async {
    final isPinEnabled = await isPinSet();
    if (!isPinEnabled) return false;

    final autoLockEnabled = await isAutoLockEnabled();
    if (!autoLockEnabled) return false;

    final lastActive = await getLastActiveTime();
    if (lastActive == null) return true;

    final timeout = await getAutoLockTimeout();
    final elapsed = DateTime.now().difference(lastActive);
    
    return elapsed.inMinutes >= timeout;
  }

  // Clear all auth data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
