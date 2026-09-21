import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Reuses the existing dark Settings surface, purple outlines and typography.
Future<void> showMaVideoTooLongDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      key: const Key('ma_video_duration_dialog'),
      backgroundColor: AppColors.artworkBackground,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  key: const Key('ma_video_duration_close'),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.white, size: 18),
                ),
              ),
              const Icon(
                Icons.videocam_off_outlined,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'Video must be 5 seconds or less.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please choose a shorter video and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Returns true only after the account DELETE endpoint has succeeded and
/// the local authentication token has been cleared.
Future<bool> showMaDeleteAccountDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _DeleteAccountConfirmation(),
      ) ??
      false;
}

class _DeleteAccountConfirmation extends ConsumerStatefulWidget {
  const _DeleteAccountConfirmation();

  @override
  ConsumerState<_DeleteAccountConfirmation> createState() =>
      _DeleteAccountConfirmationState();
}

class _DeleteAccountConfirmationState
    extends ConsumerState<_DeleteAccountConfirmation> {
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _checkingPassword = true;
  bool _hasPassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPasswordRequirement());
  }

  Future<void> _loadPasswordRequirement() async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      if (!mounted) return;
      setState(() {
        _hasPassword = user.hasPassword;
        _checkingPassword = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingPassword = false;
        _error = 'Could not verify your account. Check your connection and try again.';
      });
    }
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy || _checkingPassword) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(apiGatewayProvider).delete(
        ApiPaths.account,
        data: <String, String>{
          if (_hasPassword) 'current_password': _password.text,
          'confirmation': 'DELETE',
        },
      );
      await ref.read(authTokenStoreProvider).clear();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.fieldErrors['current_password']?.firstOrNull ??
            exception.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not delete your account. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        key: const Key('ma_delete_account_dialog'),
        backgroundColor: AppColors.artworkBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_forever_outlined,
                  size: 44,
                  color: AppColors.error,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please confirm to delete your account',
                  key: Key('ma_delete_account_prompt'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This permanently deletes your account, including both Maker and Appreciator profiles if you use both.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                  ),
                ),
                if (_checkingPassword) ...[
                  const SizedBox(height: 14),
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (_hasPassword && !_checkingPassword) ...[
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('ma_delete_account_password'),
                    controller: _password,
                    obscureText: true,
                    enabled: !_busy,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      labelStyle: TextStyle(color: AppColors.mutedText),
                      filled: true,
                      fillColor: AppColors.filterInputFill,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    key: const Key('ma_delete_account_error'),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          key: const Key('ma_delete_account_confirm'),
                          onPressed: _busy || _checkingPassword ? null : _confirm,
                          style: AppButtonStyles.filterAction(),
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Text('Confirm'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          key: const Key('ma_delete_account_close'),
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: AppButtonStyles.filterAction(),
                          child: const Text('Close'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
