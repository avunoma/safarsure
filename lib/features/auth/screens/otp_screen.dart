import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safarsure/core/constants/app_constants.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.name});

  final String phone;
  final String name;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 6-digit OTP')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).loginWithPhone(
            widget.phone,
            widget.name,
          );
      if (mounted) {
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the code sent to',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${AppConstants.countryCode} ${widget.phone}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: '6-digit OTP',
                  hintText: AppConstants.demoOtp,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Any 6-digit code works in demo mode.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.charcoalMuted,
                    ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify & continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
