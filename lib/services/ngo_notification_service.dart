// FILE: lib/services/ngo_notification_service.dart

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

class NgoNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NgoNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NgoNotification.fromMap(Map<String, dynamic> map) {
    return NgoNotification(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Notification',
      message: map['message'] as String? ?? '',
      type: map['notification_type'] as String? ?? 'system',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NgoNotificationService {
  NgoNotificationService._();

  static final NgoNotificationService instance =
      NgoNotificationService._();

  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _channel;

  // ============================================================
  // FETCH NOTIFICATIONS
  // ============================================================

  Future<List<NgoNotification>> fetchNotifications(
    String profileId,
  ) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => NgoNotification.fromMap(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // FETCH UNREAD COUNT
  // ============================================================

  Future<int> fetchUnreadCount(String profileId) async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('profile_id', profileId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead(String profileId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('profile_id', profileId)
        .eq('is_read', false);
  }

  // ============================================================
  // REALTIME STREAM
  // ============================================================

  Stream<List<NgoNotification>> watchNotifications(
    String profileId,
  ) {
    final controller =
        StreamController<List<NgoNotification>>();

    _channel?.unsubscribe();

    _channel = _client
        .channel('ngo-notifications-$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: profileId,
          ),
          callback: (_) async {
            try {
              final notifications =
                  await fetchNotifications(profileId);

              if (!controller.isClosed) {
                controller.add(notifications);
              }
            } catch (error) {
              if (!controller.isClosed) {
                controller.addError(error);
              }
            }
          },
        )
        .subscribe();

    fetchNotifications(profileId).then((notifications) {
      if (!controller.isClosed) {
        controller.add(notifications);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    controller.onCancel = () async {
      await _channel?.unsubscribe();
      _channel = null;
    };

    return controller.stream;
  }

  // ============================================================
  // CREATE NOTIFICATION
  // ============================================================

  Future<void> createNotification({
    required AppUser user,
    required String title,
    required String message,
    String type = 'system',
  }) async {
    await _client.from('notifications').insert({
      'profile_id': user.id,
      'title': title,
      'message': message,
      'notification_type': type,
      'is_read': false,
    });
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  Future<void> disposeRealtime() async {
    await _channel?.unsubscribe();
    _channel = null;
  }
}