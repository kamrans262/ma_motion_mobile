import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MaMotionApp()));
}

class MaMotionApp extends StatefulWidget {
  const MaMotionApp({
    super.key,
    this.splashAutoPlay = true,
    this.splashDuration = const Duration(milliseconds: 12000),
  });

  final bool splashAutoPlay;
  final Duration splashDuration;

  @override
  State<MaMotionApp> createState() => _MaMotionAppState();
}

class _MaMotionAppState extends State<MaMotionApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = createAppRouter(
      splashAutoPlay: widget.splashAutoPlay,
      splashDuration: widget.splashDuration,
    );
  }

  @override
  void dispose() {
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
