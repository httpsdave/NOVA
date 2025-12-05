import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  
  const LockScreen({super.key, this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final List<String> _enteredPin = [];
  bool _isError = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final biometricEnabled = await AuthService.instance.isBiometricEnabled();
    final canUse = await AuthService.instance.canUseBiometrics();
    
    setState(() {
      _canUseBiometrics = biometricEnabled && canUse;
    });

    // Auto-trigger biometrics if available
    if (_canUseBiometrics && mounted) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await AuthService.instance.authenticateWithBiometrics();
    if (success && mounted) {
      await AuthService.instance.updateLastActiveTime();
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  Future<void> _verifyPin() async {
    final pin = _enteredPin.join();
    final isValid = await AuthService.instance.verifyPin(pin);

    if (isValid) {
      await AuthService.instance.updateLastActiveTime();
      if (mounted) {
        if (widget.onUnlocked != null) {
          widget.onUnlocked!();
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      setState(() {
        _isError = true;
        _enteredPin.clear();
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isError = false);
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _isError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2DBD6C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nova',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter PIN to unlock',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? Colors.red
                          : isFilled
                              ? const Color(0xFF2DBD6C)
                              : Colors.transparent,
                      border: Border.all(
                        color: _isError
                            ? Colors.red
                            : isFilled
                                ? const Color(0xFF2DBD6C)
                                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_isError) ...[
                const SizedBox(height: 16),
                Text(
                  'Incorrect PIN',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              const Spacer(),
              // Number pad
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...List.generate(9, (index) {
                    final number = (index + 1).toString();
                    return _buildNumberButton(number);
                  }),
                  // Biometric button
                  if (_canUseBiometrics)
                    _buildActionButton(
                      icon: Icons.fingerprint,
                      onPressed: _authenticateWithBiometrics,
                    )
                  else
                    const SizedBox(),
                  _buildNumberButton('0'),
                  _buildActionButton(
                    icon: Icons.backspace_outlined,
                    onPressed: _onBackspacePressed,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: const Color(0xFF2DBD6C),
          ),
        ),
      ),
    );
  }
}
