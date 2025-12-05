import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import 'setup_pin_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isPinEnabled = false;
  bool _biometricEnabled = false;
  bool _autoLockEnabled = false;
  int _autoLockTimeout = 5;
  bool _canUseBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isPinSet = await AuthService.instance.isPinSet();
    final biometricEnabled = await AuthService.instance.isBiometricEnabled();
    final autoLockEnabled = await AuthService.instance.isAutoLockEnabled();
    final timeout = await AuthService.instance.getAutoLockTimeout();
    final canUse = await AuthService.instance.canUseBiometrics();
    final available = await AuthService.instance.getAvailableBiometrics();

    setState(() {
      _isPinEnabled = isPinSet;
      _biometricEnabled = biometricEnabled;
      _autoLockEnabled = autoLockEnabled;
      _autoLockTimeout = timeout;
      _canUseBiometrics = canUse;
      _availableBiometrics = available;
    });
  }

  Future<void> _setupPin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetupPinScreen()),
    );

    if (result == true) {
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN setup complete')),
        );
      }
    }
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove your PIN? This will disable app lock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.removePin();
      await AuthService.instance.setBiometricEnabled(false);
      await AuthService.instance.setAutoLockEnabled(false);
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN removed')),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final success = await AuthService.instance.authenticateWithBiometrics();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication failed')),
          );
        }
        return;
      }
    }

    await AuthService.instance.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _toggleAutoLock(bool value) async {
    await AuthService.instance.setAutoLockEnabled(value);
    setState(() => _autoLockEnabled = value);
  }

  Future<void> _changeAutoLockTimeout() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-lock timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeoutOption(1, '1 minute'),
            _buildTimeoutOption(5, '5 minutes'),
            _buildTimeoutOption(15, '15 minutes'),
            _buildTimeoutOption(30, '30 minutes'),
            _buildTimeoutOption(60, '1 hour'),
          ],
        ),
      ),
    );

    if (result != null) {
      await AuthService.instance.setAutoLockTimeout(result);
      setState(() => _autoLockTimeout = result);
    }
  }

  Widget _buildTimeoutOption(int minutes, String label) {
    return ListTile(
      title: Text(label),
      selected: _autoLockTimeout == minutes,
      onTap: () => Navigator.pop(context, minutes),
    );
  }

  String _getTimeoutLabel() {
    if (_autoLockTimeout < 60) {
      return '$_autoLockTimeout ${_autoLockTimeout == 1 ? 'minute' : 'minutes'}';
    }
    final hours = _autoLockTimeout ~/ 60;
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }

  String _getBiometricLabel() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App Lock',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2DBD6C),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN'),
            subtitle: Text(_isPinEnabled ? 'Enabled' : 'Not set'),
            trailing: _isPinEnabled
                ? TextButton(
                    onPressed: _removePin,
                    child: const Text('Remove'),
                  )
                : null,
            onTap: _isPinEnabled ? null : _setupPin,
          ),
          if (_isPinEnabled && _canUseBiometrics) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(_getBiometricLabel()),
              subtitle: const Text('Unlock with biometric authentication'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ],
          if (_isPinEnabled) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Auto-lock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2DBD6C),
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Auto-lock'),
              subtitle: const Text('Lock app after inactivity'),
              value: _autoLockEnabled,
              onChanged: _toggleAutoLock,
            ),
            if (_autoLockEnabled)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Timeout'),
                subtitle: Text(_getTimeoutLabel()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _changeAutoLockTimeout,
              ),
          ],
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Info',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2DBD6C),
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About app lock'),
            subtitle: Text(
              'Protect your notes with a PIN. Enable biometric authentication for quick access.',
            ),
          ),
        ],
      ),
    );
  }
}
