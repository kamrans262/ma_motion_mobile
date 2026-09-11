import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/ma_splash_sequence_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaMotionApp());
}

class MaMotionApp extends StatelessWidget {
  const MaMotionApp({super.key, this.splashAutoPlay = true});

  final bool splashAutoPlay;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MA Motion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MaSplashSequenceScreen(autoPlay: splashAutoPlay),
    );
  }
}
