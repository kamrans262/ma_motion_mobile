import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared two-layer glass presentation for Filter and Maker Settings popups.
class MaGlassPopup extends StatelessWidget {
  const MaGlassPopup({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  static const Color overlayColor = Color(0xCC000000);
  static const Color panelColor = Color(0xB3000000);
  static const double overlayBlurSigma = 8;
  static const double panelBlurSigma = 12;
  static const double panelPadding = 24;
  static const double horizontalMargin = 16;
  static const double maxPanelWidth = 448;
  static const double maxPanelHeightFraction = 0.9;

  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: overlayBlurSigma,
                sigmaY: overlayBlurSigma,
              ),
              child: GestureDetector(
                key: const Key('ma_glass_popup_overlay'),
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: const ColoredBox(color: overlayColor),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final usableHeight = (constraints.maxHeight - keyboardInset)
                    .clamp(0.0, constraints.maxHeight)
                    .toDouble();
                final panelHeight = usableHeight * maxPanelHeightFraction;

                return AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalMargin,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: maxPanelWidth,
                        ),
                        child: SizedBox(
                          height: panelHeight,
                          child: ClipRect(
                            key: const Key('ma_glass_popup_panel'),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: panelBlurSigma,
                                sigmaY: panelBlurSigma,
                              ),
                              child: ColoredBox(
                                color: panelColor,
                                child: Padding(
                                  key: const Key('ma_glass_popup_padding'),
                                  padding: const EdgeInsets.all(panelPadding),
                                  // The popup already accounts for the keyboard,
                                  // so its embedded Scaffold must not resize twice.
                                  child: MediaQuery.removeViewInsets(
                                    context: context,
                                    removeBottom: true,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
