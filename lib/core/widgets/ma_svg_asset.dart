import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MaSvgAsset extends StatefulWidget {
  const MaSvgAsset({
    super.key,
    required this.assetName,
    required this.fallbackAssetName,
    this.fit = BoxFit.contain,
    this.color,
  });

  final String assetName;
  final String fallbackAssetName;
  final BoxFit fit;
  final Color? color;

  @override
  State<MaSvgAsset> createState() => _MaSvgAssetState();
}

class _MaSvgAssetState extends State<MaSvgAsset> {
  AssetBundle? _bundle;
  Future<ByteData?>? _primaryBytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshPrimaryAsset();
  }

  @override
  void didUpdateWidget(covariant MaSvgAsset oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assetName != widget.assetName) {
      _primaryBytes = null;
      _refreshPrimaryAsset();
    }
  }

  void _refreshPrimaryAsset() {
    final bundle = DefaultAssetBundle.of(context);

    if (_bundle == bundle && _primaryBytes != null) {
      return;
    }

    _bundle = bundle;
    _primaryBytes = _loadPrimary(bundle);
  }

  Future<ByteData?> _loadPrimary(AssetBundle bundle) async {
    try {
      return await bundle.load(widget.assetName);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorFilter = widget.color == null
        ? null
        : ColorFilter.mode(widget.color!, BlendMode.srcIn);

    return FutureBuilder<ByteData?>(
      future: _primaryBytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        if (bytes != null) {
          final data = bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          );

          return SvgPicture.memory(
            data,
            fit: widget.fit,
            colorFilter: colorFilter,
          );
        }

        return SvgPicture.asset(
          widget.fallbackAssetName,
          fit: widget.fit,
          colorFilter: colorFilter,
        );
      },
    );
  }
}
