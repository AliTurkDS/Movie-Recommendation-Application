import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/repositories/account_repository.dart';
import '../providers/account_provider.dart';
import '../providers/login_prompt_provider.dart';

/// One-time welcome / sign-in screen shown on first launch.
///
/// Signing in remembers the email + password as the cloud-backup key and
/// restores any existing backup. It is fully skippable — the email + password
/// are only a backup key, not a real login. Backup can be set up later from the
/// Account / Sync sheet.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || email.length < 4) {
      _toast('Enter a valid email.');
      return;
    }
    if (password.length < 4) {
      _toast('Password must be at least 4 characters.');
      return;
    }

    setState(() => _busy = true);
    final creds = AccountCredentials(email: email, password: password);
    final result = await ref.read(syncStatusProvider.notifier).signIn(creds);
    // signIn() persists the credentials; the root gate now swaps to the app.
    await ref.read(loginPromptedProvider.notifier).markPrompted();
    if (!mounted) return;
    if (result == SignInResult.error) {
      _toast('Signed in, but cloud restore failed — check your connection.');
    }
    setState(() => _busy = false);
  }

  Future<void> _skip() async {
    await ref.read(loginPromptedProvider.notifier).markPrompted();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    RichText(
                      text: const TextSpan(
                        style: AppText.logo,
                        children: [
                          TextSpan(
                            text: 'Cine',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Swipe',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in to back up your watchlist and sync it across your '
                      'devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _field(
                      controller: _email,
                      hint: 'Email',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _password,
                      hint: 'Backup password',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      enabled: !_busy,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tip: don\'t reuse a real password — this is a simple backup '
                      'key, not a secure login.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PrimaryButton(
                      label: 'Continue',
                      loading: _busy,
                      onTap: _busy ? null : _continue,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _busy ? null : _skip,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.cardBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.saveGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: color,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
