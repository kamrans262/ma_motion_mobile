import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Centers Type/Style labels optically in their existing chip bounds.
///
/// Helvetica Neue LT Std reserves space below its visible letterforms. A
/// centered Text layout box can therefore leave the visible label too high.
/// This small paint-only correction preserves chip sizes and tap targets.
class MaCenteredTaxonomyLabel extends StatelessWidget {
  const MaCenteredTaxonomyLabel({
    super.key,
    required this.label,
    required this.style,
    this.verticalOffset = opticalOffsetY,
    this.stableSelectedFontWeight,
  });

  final String label;
  final TextStyle style;
  final double verticalOffset;
  // Preallocate the wider W500/W600 text width to prevent selected chips from
  // shifting their neighbors in a Wrap without changing padding or colors.
  final FontWeight? stableSelectedFontWeight;

  static const double opticalOffsetY = 1.5;

  @override
  Widget build(BuildContext context) {
    double? stableWidth;
    if (stableSelectedFontWeight != null) {
      final direction = Directionality.of(context);
      final scaler = MediaQuery.textScalerOf(context);

      double measure(FontWeight weight) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: style.copyWith(fontWeight: weight)),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final width = painter.width;
        painter.dispose();
        return width;
      }

      stableWidth = math.max(
        measure(FontWeight.w500),
        measure(stableSelectedFontWeight!),
      );
    }

    final visibleLabel = Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Text(
        label,
        textAlign: TextAlign.center,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: style,
      ),
    );

    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: stableWidth == null
          ? visibleLabel
          : SizedBox(width: stableWidth, child: visibleLabel),
    );
  }
}
