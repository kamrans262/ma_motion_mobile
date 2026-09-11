import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/maker_entry_repository.dart';
import '../domain/maker_entry_destination.dart';

final makerAuthControllerProvider =
    NotifierProvider<MakerAuthController, MakerAuthState>(
      MakerAuthController.new,
    );

enum MakerAuthMode { signIn, createAccount }

class MakerAuthState {
  const MakerAuthState({
    this.mode = MakerAuthMode.signIn,
    this.isBusy = false,
    this.errorMessage,
    this.infoMessage,
  });

  final MakerAuthMode mode;
  final bool isBusy;
  final String? errorMessage;
  final String? infoMessage;

  MakerAuthState copyWith({
    MakerAuthMode? mode,
    bool? isBusy,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return MakerAuthState(
      mode: mode ?? this.mode,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class MakerAuthController extends Notifier<MakerAuthState> {
  @override
  MakerAuthState build() => const MakerAuthState();

  MakerEntryRepositoryContract get _repository =>
      ref.read(makerEntryRepositoryProvider);

  void setMode(MakerAuthMode mode) {
    if (state.isBusy) {
      return;
    }

    state = MakerAuthState(mode: mode);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  Future<MakerEntryDestination?> signIn({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.loginMaker(email: email, password: password));
  }

  Future<MakerEntryDestination?> createAccount({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _run(
      () => _repository.registerMaker(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ),
    );
  }

  Future<void> forgotPassword(String email) async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true, clearInfo: true);

    try {
      final message = await _repository.requestPasswordReset(email);
      state = state.copyWith(
        isBusy: false,
        infoMessage: message,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _messageFor(error),
        clearInfo: true,
      );
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'The request could not be completed. Please try again.',
        clearInfo: true,
      );
    }
  }

  Future<MakerEntryDestination?> _run(
    Future<MakerEntryDestination> Function() operation,
  ) async {
    if (state.isBusy) {
      return null;
    }

    state = state.copyWith(isBusy: true, clearError: true, clearInfo: true);

    try {
      final destination = await operation();
      state = state.copyWith(isBusy: false, clearError: true);
      return destination;
    } on ApiException catch (error) {
      state = state.copyWith(isBusy: false, errorMessage: _messageFor(error));
      return null;
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'The request could not be completed. Please try again.',
      );
      return null;
    }
  }

  static String _messageFor(ApiException error) {
    if (error.fieldErrors.isNotEmpty) {
      for (final messages in error.fieldErrors.values) {
        for (final message in messages) {
          if (message.trim().isNotEmpty) {
            return message;
          }
        }
      }
    }

    return error.message;
  }
}
