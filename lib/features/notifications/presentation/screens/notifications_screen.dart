import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/ma_push_notifications.dart';

/// MA Motion's existing database inbox, accessible when a push is opened.
/// It uses existing app colors and does not modify discovery layout.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  bool _busy = false;
  bool _showAlerts = true;
  int _unreadCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    MaPushNotifications.instance.inboxChanges.addListener(_onPush);
    _load();
  }

  void _onPush() => _load();

  @override
  void dispose() {
    MaPushNotifications.instance.inboxChanges.removeListener(_onPush);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiGatewayProvider);
      final results = await Future.wait([
        api.get(ApiPaths.notifications, queryParameters: {'per_page': 50}),
        api.get(ApiPaths.notificationSettings),
      ]);
      if (!mounted) return;
      final list = ApiEnvelope(raw: results[0]);
      final settings = ApiEnvelope(raw: results[1]).dataMap;
      setState(() {
        _items = list.dataList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _unreadCount = int.tryParse(list.meta['unread_count']?.toString() ?? '') ?? 0;
        _showAlerts = settings['saved_maker_show_alerts'] != false;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load notifications. Pull down to retry.';
        });
      }
    }
  }

  Future<void> _setAlerts(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiGatewayProvider).patch(
        ApiPaths.notificationSettings,
        data: {'saved_maker_show_alerts': value},
      );
      if (mounted) setState(() => _showAlerts = value);
    } catch (_) {
      if (mounted) _showError('Could not update notification settings.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null || item['is_read'] == true) return;
    try {
      await ref.read(apiGatewayProvider).patch(ApiPaths.notificationRead(id));
      await _load();
    } catch (_) {
      if (mounted) _showError('Could not mark notification as read.');
    }
  }

  Future<void> _markAllRead() async {
    if (_busy || _unreadCount == 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiGatewayProvider).patch(ApiPaths.notificationsReadAll);
      await _load();
    } catch (_) {
      if (mounted) _showError('Could not mark notifications as read.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(message, style: const TextStyle(color: AppColors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('ma_notifications_screen'),
      backgroundColor: AppColors.artworkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.artworkBackground,
        foregroundColor: AppColors.white,
        leading: IconButton(
          tooltip: 'Back to discovery',
          icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            fontSize: 24,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _busy ? null : _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.savedBackground),
              child: SwitchListTile(
                title: const Text('Saved Maker show alerts',
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )),
                subtitle: const Text('Get notified when a Maker you saved announces a show.',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: 12,
                    )),
                value: _showAlerts,
                activeThumbColor: AppColors.primary,
                onChanged: _busy ? null : _setAlerts,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, style: const TextStyle(color: AppColors.white)),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 45),
                child: Center(
                  child: Text('No notifications yet.',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 14)),
                ),
              )
            else
              for (final item in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: item['is_read'] == true
                        ? AppColors.artworkNavBackground
                        : AppColors.savedBackground,
                    child: InkWell(
                      onTap: () => _markRead(item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title']?.toString() ?? 'Maker update',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              )),
                            const SizedBox(height: 6),
                            Text(item['body']?.toString() ?? '',
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: 12,
                              )),
                            if (item['is_read'] != true) ...[
                              const SizedBox(height: 8),
                              const Text('Unread',
                                style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
