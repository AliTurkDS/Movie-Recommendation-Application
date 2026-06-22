import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/repositories/account_repository.dart';
import '../providers/account_provider.dart';

/// Opens the "Account / Sync" bottom sheet for cloud backup & restore.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AccountSheet(),
  );
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet();

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _prefilled = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// The credentials to act on: the remembered account when signed in,
  /// otherwise whatever is typed into the (set-up) form.
  AccountCredentials? _creds() {
    final saved = ref.read(accountProvider).valueOrNull;
    if (saved != null) return saved;
    return _readForm();
  }

  /// Validates the form and returns credentials, or null (with a snackbar).
  AccountCredentials? _readForm() {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || email.length < 4) {
      _toast('Enter a valid email.');
      return null;
    }
    if (password.length < 4) {
      _toast('Password must be at least 4 characters.');
      return null;
    }
    return AccountCredentials(email: email, password: password);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _backup() async {
    final creds = _creds();
    if (creds == null) return;
    await ref.read(syncStatusProvider.notifier).backup(creds);
  }

  Future<void> _restore() async {
    final creds = _creds();
    if (creds == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Restore from cloud?'),
        content: const Text(
          'This will replace your current lists (watchlist, watched, '
          'unwatched and history) with your backup. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace my data',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(syncStatusProvider.notifier).restore(creds);
  }

  Future<void> _forget() async {
    await ref.read(accountProvider.notifier).forget();
    _email.clear();
    _password.clear();
    ref.read(syncStatusProvider.notifier).reset();
    _toast('Account forgotten on this device.');
  }

  @override
  Widget build(BuildContext context) {
    // Prefill remembered credentials once they resolve.
    final saved = ref.watch(accountProvider).valueOrNull;
    if (!_prefilled && saved != null) {
      _prefilled = true;
      _email.text = saved.email;
      _password.text = saved.password;
    }

    final status = ref.watch(syncStatusProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.cloud_sync_outlined,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                const Text('Account / Sync', style: AppText.sectionTitle),
              ],
            ),
            const SizedBox(height: 6),
            if (saved != null) ...[
              // Signed in — no need to retype credentials; just back up/restore.
              Text(
                'Signed in as ${saved.email}. Back up to save your lists, or '
                'restore them on another device.',
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 18),
            ] else ...[
              // Not signed in (skipped at startup) — show the set-up form.
              const Text(
                'Back up your lists to the cloud, then restore them on any '
                'device with the same email and password.',
                style: TextStyle(
                    color: AppColors.textSecondary, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _field(
                controller: _email,
                hint: 'Email',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _password,
                hint: 'Backup password',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: don\'t reuse a real password — this is a simple backup '
                'key, not a secure login.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 18),
            ],
            _StatusLine(status: status),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Back up',
                    icon: Icons.cloud_upload_outlined,
                    color: AppColors.saveGreen,
                    loading: status.phase == SyncPhase.backingUp,
                    onTap: status.busy ? null : _backup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Restore',
                    icon: Icons.cloud_download_outlined,
                    color: AppColors.watchedBlue,
                    loading: status.phase == SyncPhase.restoring,
                    onTap: status.busy ? null : _restore,
                  ),
                ),
              ],
            ),
            if (saved != null) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: status.busy ? null : _forget,
                  child: const Text('Switch / forget account',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Inline status / result message under the form.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.message == null) return const SizedBox.shrink();
    final isError = status.phase == SyncPhase.error;
    final color = isError ? AppColors.accent : AppColors.saveGreen;
    return Row(
      children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status.message!,
            style: TextStyle(color: color, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !loading ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.24),
                color.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: color),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
