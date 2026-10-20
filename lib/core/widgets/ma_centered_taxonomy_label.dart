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
  });

  final String label;
  final TextStyle style;
  final double verticalOffset;

  static const double opticalOffsetY = 1.5;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Transform.translate(
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
      ),
    );
  }
}
