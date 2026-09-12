class DiscoveryLayoutMetrics {
  const DiscoveryLayoutMetrics._({
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
      scale: scale,
      gridHorizontalPadding: (20 * scale).clamp(16.0, 24.0).toDouble(),
      toolbarHeight: (62 * scale).clamp(54.0, 68.0).toDouble(),
      toolbarIconSize: (24 * scale).clamp(22.0, 26.0).toDouble(),
      controlsToGridGap: (10 * scale).clamp(8.0, 12.0).toDouble(),
      gridSpacing: (2 * scale).clamp(1.0, 3.0).toDouble(),
    );
  }

  final double scale;
  final double gridHorizontalPadding;
  final double toolbarHeight;
  final double toolbarIconSize;
  final double controlsToGridGap;
  final double gridSpacing;
}
