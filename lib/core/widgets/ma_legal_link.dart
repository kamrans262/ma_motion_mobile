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
    final uri = Uri.parse(url);
    // Prefer the device browser, then try the platform handler and a browser
    // tab if the device cannot resolve the first request.
    for (final mode in <LaunchMode>[
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (error) {
        debugPrint('MA legal link launch failed ($mode): $error');
      }
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
