import 'package:flutter/material.dart';

class MaFullLogo extends StatelessWidget {
  const MaFullLogo({super.key, this.assetPath = 'assets/logo.png'});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 240),
              child: SizedBox(
                width: (width * 0.62).clamp(180.0, 420.0),
                child: Image.asset(
                  assetPath,
                  key: const Key('ma_splash_logo'),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'MA space for art logo',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
