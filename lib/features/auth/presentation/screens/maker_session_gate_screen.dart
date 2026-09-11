import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/maker_entry_repository.dart';
import '../../domain/maker_entry_destination.dart';

class MakerSessionGateScreen extends ConsumerStatefulWidget {
  const MakerSessionGateScreen({super.key, required this.onResolved});

  final ValueChanged<MakerEntryDestination> onResolved;

  @override
  ConsumerState<MakerSessionGateScreen> createState() =>
      _MakerSessionGateScreenState();
}

class _MakerSessionGateScreenState
    extends ConsumerState<MakerSessionGateScreen> {
  String? _errorMessage;
  bool _running = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolve();
    });
  }

  Future<void> _resolve() async {
    if (_running) {
      return;
    }

    setState(() {
      _running = true;
      _errorMessage = null;
    });

    try {
      final destination = await ref
          .read(makerEntryRepositoryProvider)
          .restoreAppEntry();

      if (!mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onResolved(destination);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _running = false;
        _errorMessage = 'We could not restore your session. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('maker_session_gate'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Center(
          child: _errorMessage == null
              ? const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingHelper,
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        key: const Key('session_retry_button'),
                        onPressed: _resolve,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
