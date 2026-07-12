import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = await LocalStorageService.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final data = await Supabase.instance.client
          .from('Notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('Notifications')
          .update({'is_read': true}).eq('id', id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) _notifications[idx]['is_read'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final userId = await LocalStorageService.getUserId();
      if (userId == null) return;
      await Supabase.instance.client
          .from('Notifications')
          .update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bell, size: 56, color: context.textHint),
                      const SizedBox(height: 20),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  itemCount: _notifications.length,
                  itemBuilder: (context, i) {
                    final n = _notifications[i];
                    final isRead = n['is_read'] == true;
                    final title = n['title'] ?? 'Notification';
                    final body = n['body'] ?? '';
                    final createdAt = n['created_at'];
                    String timeStr = '';
                    if (createdAt != null) {
                      try {
                        final dt = DateTime.parse(createdAt).toLocal();
                        timeStr = DateFormat('MMM d, h:mm a').format(dt);
                      } catch (_) {}
                    }

                    return GestureDetector(
                      onTap: () {
                        if (!isRead) _markAsRead(n['id']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? context.cardBg : AppColors.accent.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead ? context.cardBorder : AppColors.accent.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.bell, size: 16, color: AppColors.accent),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.textMuted,
                                      ),
                                    ),
                                  ],
                                  if (timeStr.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.textHint,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
