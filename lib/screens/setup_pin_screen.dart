import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final List<String> _enteredPin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  bool _isError = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    final currentPin = _isConfirming ? _confirmPin : _enteredPin;
    
    if (currentPin.length < 4) {
      setState(() {
        currentPin.add(number);
        _isError = false;
      });

      if (currentPin.length == 4) {
        if (_isConfirming) {
          _verifyAndSavePin();
        } else {
          setState(() => _isConfirming = true);
        }
      }
    }
  }

  Future<void> _verifyAndSavePin() async {
    final pin = _enteredPin.join();
    final confirm = _confirmPin.join();

    if (pin != confirm) {
      setState(() {
        _isError = true;
        _errorMessage = 'PINs do not match';
        _confirmPin.clear();
        _isConfirming = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isError = false;
          _enteredPin.clear();
        });
      }
      return;
    }

    // Save PIN
    await AuthService.instance.setPin(pin);
    await AuthService.instance.updateLastActiveTime();

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onBackspacePressed() {
    final currentPin = _isConfirming ? _confirmPin : _enteredPin;
    
    if (currentPin.isNotEmpty) {
      setState(() {
        currentPin.removeLast();
        _isError = false;
      });
    } else if (_isConfirming) {
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPin = _isConfirming ? _confirmPin : _enteredPin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PIN'),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline,
                size: 64,
                color: const Color(0xFF2DBD6C),
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirming ? 'Confirm PIN' : 'Create PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Re-enter your PIN'
                    : 'Enter a 4-digit PIN',
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
                  final isFilled = index < currentPin.length;
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
                  _errorMessage,
                  style: const TextStyle(
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
