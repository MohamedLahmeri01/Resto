import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _pin = '';
  static const int pinLength = 4;

  void _addDigit(String digit) {
    if (_pin.length >= pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == pinLength) {
      _submit();
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _clear() {
    setState(() => _pin = '');
  }

  Future<void> _submit() async {
    if (_pin.length != pinLength) return;
    final success = await ref.read(authProvider.notifier).loginPin(_pin);
    if (success && mounted) {
      context.go('/');
    } else {
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.pin_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Code PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: i < _pin.length ? AppColors.primary : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                  ),
                )),
              ),

              // Error
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ),

              if (auth.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),

              const SizedBox(height: 32),

              // Numpad
              _buildNumpad(),

              const SizedBox(height: 24),

              // Back to email login
              TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Connexion par email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildKey(key),
          )).toList(),
        ),
      )).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isAction = key == 'C' || key == '⌫';
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isAction ? AppColors.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (key == 'C') {
              _clear();
            } else if (key == '⌫') {
              _backspace();
            } else {
              _addDigit(key);
            }
          },
          child: Center(
            child: key == '⌫'
                ? const Icon(Icons.backspace_outlined, size: 24)
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: isAction ? 16 : 28,
                      fontWeight: FontWeight.w600,
                      color: isAction ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
