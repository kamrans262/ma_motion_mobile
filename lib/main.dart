import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/core_providers.dart';
import 'features/notifications/application/ma_push_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MaPushNotifications.instance.initialize();

  runApp(const ProviderScope(child: MaMotionApp()));
}

class MaMotionApp extends ConsumerStatefulWidget {
  const MaMotionApp({
    super.key,
    this.splashAutoPlay = true,
    this.splashDuration = const Duration(milliseconds: 7500),
  });

  final bool splashAutoPlay;
  final Duration splashDuration;

  @override
  ConsumerState<MaMotionApp> createState() => _MaMotionAppState();
}

class _MaMotionAppState extends ConsumerState<MaMotionApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = createAppRouter(
      splashAutoPlay: widget.splashAutoPlay,
      splashDuration: widget.splashDuration,
    );
    WidgetsBinding.instance.addObserver(this);
    MaPushNotifications.instance.bind(
      api: ref.read(apiGatewayProvider),
      tokens: ref.read(authTokenStoreProvider),
      onOpenInbox: () => _router.go('/appreciator/notifications'),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(MaPushNotifications.instance.syncToken());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MaPushNotifications.instance.dispose();
    _router.dispose();
    super.dispose();
  }

  void _dismissKeyboardOutsideFocusedControl(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    final focusContext = focus?.context;

    if (focus == null || focusContext == null) {
      return;
    }

    final renderObject = focusContext.findRenderObject();

    if (renderObject is RenderBox && renderObject.hasSize) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final focusedRect = topLeft & renderObject.size;

      if (focusedRect.contains(event.position)) {
        return;
      }
    }

    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _dismissKeyboardOutsideFocusedControl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
