import 'package:flutter/material.dart';

class MaFullLogo extends StatelessWidget {
  const MaFullLogo({super.key, this.assetPath = 'assets/logo.png'});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth = (constraints.maxWidth * 0.48)
            .clamp(150.0, 320.0)
            .toDouble();

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: logoWidth,
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
        );
      },
    );
  }
}
