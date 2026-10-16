import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public legal pages shared by Login and both Settings experiences.
abstract final class MaLegalUrls {
  static const String terms = 'https://www.ma-spaceforart.com/terms-conditions';
  static const String privacy = 'https://www.ma-spaceforart.com/privacy-policy';
}

/// Preserves the legal-label typography while making the text tappable.
class MaLegalLink extends StatelessWidget {
  static const MethodChannel _androidExternalLinks = MethodChannel(
    'com.mamotion.ma_motion_mobile/external_links',
  );

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
    String? browserUnavailableMessage;

    // Bypass plugin resolution on Android: ask the operating system directly
    // to open the HTTPS page in any installed/default browser.
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final opened = await _androidExternalLinks.invokeMethod<bool>(
          'openExternalUrl',
          <String, String>{'url': uri.toString()},
        );
        if (opened == true) return;
        debugPrint('MA native browser intent returned false.');
      } on PlatformException catch (error) {
        debugPrint('MA native browser intent: ${error.code}: ${error.message}');
        if (error.code == 'no_browser') {
          browserUnavailableMessage = 'No browser app is installed to open this link.';
        }
      } catch (error) {
        debugPrint('MA native browser intent unavailable: $error');
      }
    }

    // Retain the plugin fallback for iOS and other supported platforms.
    for (final mode in <LaunchMode>[
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
        debugPrint('MA legal link was not handled by $mode.');
      } catch (error) {
        debugPrint('MA legal link launch failed ($mode): $error');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            browserUnavailableMessage ?? 'Could not open the link. Please try again.',
          ),
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
