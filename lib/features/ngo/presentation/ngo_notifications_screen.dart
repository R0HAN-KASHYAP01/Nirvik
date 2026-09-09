// FILE: lib/features/ngo/presentation/ngo_notifications_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../services/ngo_notification_service.dart';

class NgoNotificationsScreen extends StatefulWidget {
  const NgoNotificationsScreen({super.key});

  @override
  State<NgoNotificationsScreen> createState() =>
      _NgoNotificationsScreenState();
}

class _NgoNotificationsScreenState
    extends State<NgoNotificationsScreen> {
  List<NgoNotification> _notifications = [];

  StreamSubscription<List<NgoNotification>>? _subscription;

  bool _loading = true;
  bool _markingAll = false;

  static const Color navy = Color(0xFF123E68);
  static const Color darkBlue = Color(0xFF0D4778);
  static const Color background = Color(0xFFF4F8FB);
  static const Color borderColor = Color(0xFFDDE6ED);
  static const Color greyText = Color(0xFF6B7785);
  static const Color green = Color(0xFF159447);
  static const Color lightGreen = Color(0xFFE5F7ED);
  static const Color blue = Color(0xFF1769AA);
  static const Color lightBlue = Color(0xFFEAF4FB);
  static const Color orange = Color(0xFFF5A623);
  static const Color lightOrange = Color(0xFFFFF3DD);
  static const Color red = Color(0xFFD94141);
  static const Color lightRed = Color(0xFFFDE8E8);

  @override
  void initState() {
    super.initState();
    _startRealtimeNotifications();
  }

  Future<void> _startRealtimeNotifications() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    _subscription = NgoNotificationService.instance
        .watchNotifications(user.id)
        .listen(
      (notifications) {
        if (!mounted) return;

        setState(() {
          _notifications = notifications;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    NgoNotificationService.instance.disposeRealtime();
    super.dispose();
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> _openNotification(
    NgoNotification notification,
  ) async {
    if (!notification.isRead) {
      try {
        await NgoNotificationService.instance.markAsRead(
          notification.id,
        );

        if (!mounted) return;

        setState(() {
          final index = _notifications.indexWhere(
            (item) => item.id == notification.id,
          );

          if (index != -1) {
            _notifications[index] = NgoNotification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              isRead: true,
              createdAt: notification.createdAt,
            );
          }
        });
      } catch (_) {}
    }

    if (!mounted) return;

    _showNotificationDetails(notification);
  }

  // ============================================================
  // MARK ALL READ
  // ============================================================

  Future<void> _markAllAsRead() async {
    final user = SessionService.instance.currentUser;

    if (user == null) return;

    final unreadExists =
        _notifications.any((notification) => !notification.isRead);

    if (!unreadExists) return;

    setState(() {
      _markingAll = true;
    });

    try {
      await NgoNotificationService.instance.markAllAsRead(
        user.id,
      );

      if (!mounted) return;

      setState(() {
        _notifications = _notifications
            .map(
              (notification) => NgoNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                isRead: true,
                createdAt: notification.createdAt,
              ),
            )
            .toList();
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not mark notifications as read.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _markingAll = false;
        });
      }
    }
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showNotificationDetails(
    NgoNotification notification,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  _buildTypeIcon(notification.type),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                notification.message,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                _formatDateTime(notification.createdAt),
                style: const TextStyle(
                  color: greyText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            _markingAll
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Mark all as read',
                    onPressed: _markAllAsRead,
                    icon: const Icon(
                      Icons.done_all_rounded,
                    ),
                  ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user =
              SessionService.instance.currentUser;

          if (user == null) return;

          try {
            final notifications =
                await NgoNotificationService.instance
                    .fetchNotifications(user.id);

            if (!mounted) return;

            setState(() {
              _notifications = notifications;
            });
          } catch (_) {}
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: darkBlue,
        ),
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
          ),
          const Icon(
            Icons.notifications_none_rounded,
            size: 62,
            color: greyText,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'No notifications',
              style: TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Center(
            child: Text(
              'New updates will appear here in real time.',
              style: TextStyle(
                color: greyText,
                fontSize: 11,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        24,
      ),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];

        return _buildNotificationCard(notification);
      },
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildNotificationCard(
    NgoNotification notification,
  ) {
    return GestureDetector(
      onTap: () => _openNotification(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : lightBlue,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: notification.isRead
                ? borderColor
                : blue.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(notification.type),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    _formatDateTime(
                      notification.createdAt,
                    ),
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right_rounded,
              color: greyText,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPE ICON
  // ============================================================

  Widget _buildTypeIcon(String type) {
    final normalized = type.toLowerCase();

    IconData icon = Icons.notifications_rounded;
    Color iconColor = blue;
    Color backgroundColor = lightBlue;

    if (normalized == 'report') {
      icon = Icons.description_rounded;
      iconColor = blue;
      backgroundColor = lightBlue;
    } else if (normalized == 'attendance') {
      icon = Icons.groups_rounded;
      iconColor = green;
      backgroundColor = lightGreen;
    } else if (normalized == 'inspection') {
      icon = Icons.fact_check_rounded;
      iconColor = orange;
      backgroundColor = lightOrange;
    } else if (normalized == 'alert') {
      icon = Icons.warning_rounded;
      iconColor = red;
      backgroundColor = lightRed;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    var hour = local.hour;
    final minute =
        local.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '${local.day} ${months[local.month - 1]} '
        '${local.year} • '
        '$hour:$minute $period';
  }
}