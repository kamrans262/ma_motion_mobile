import 'dart:math' as math;

class DiscoveryLayoutMetrics {
  const DiscoveryLayoutMetrics._({
    required this.width,
    required this.scale,
    required this.gridHorizontalPadding,
    required this.toolbarHeight,
    required this.toolbarIconSize,
    required this.controlsToGridGap,
    required this.gridSpacing,
  });

  factory DiscoveryLayoutMetrics.fromWidth(double width) {
    final scale = (width / 430).clamp(0.82, 1.12).toDouble();

    return DiscoveryLayoutMetrics._(
      width: width,
      scale: scale,
      gridHorizontalPadding: (20 * scale).clamp(16.0, 24.0).toDouble(),
      toolbarHeight: (62 * scale).clamp(54.0, 68.0).toDouble(),
      toolbarIconSize: (24 * scale).clamp(22.0, 26.0).toDouble(),
      controlsToGridGap: (10 * scale).clamp(8.0, 12.0).toDouble(),
      gridSpacing: (2 * scale).clamp(1.0, 3.0).toDouble(),
    );
  }

  final double width;
  final double scale;
  final double gridHorizontalPadding;
  final double toolbarHeight;
  final double toolbarIconSize;
  final double controlsToGridGap;
  final double gridSpacing;

  int itemsPerPageFor(double gridHeight) {
    final contentWidth = math.max(0.0, width - (gridHorizontalPadding * 2));
    final cellWidth = math.max(1.0, (contentWidth - gridSpacing) / 2);
    final rowExtent = cellWidth + gridSpacing;
    final rows = math.max(
      1,
      ((math.max(0.0, gridHeight) + gridSpacing) / rowExtent).floor(),
    );

    return rows * 2;
  }
}
