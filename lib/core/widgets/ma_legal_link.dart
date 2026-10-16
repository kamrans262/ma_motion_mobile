import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public legal pages shared by Login and both Settings experiences.
abstract final class MaLegalUrls {
  static const String terms = 'https://www.ma-spaceforart.com/terms-conditions';
  static const String privacy = 'https://www.ma-spaceforart.com/privacy-policy';
}

/// Preserves the legal-label typography while making the text tappable.
class MaLegalLink extends StatelessWidget {
  const MaLegalLink({
    super.key,
    required this.label,
    required this.url,
    required this.textKey,
    required this.style,
  });

  final String label;
  final String url;
  final Key textKey;
  final TextStyle style;

  Future<void> _open(BuildContext context) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {
      // A browser may not be available on the device.
    }

    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Could not open the link. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Text(label, key: textKey, style: style),
      ),
    );
  }
}
