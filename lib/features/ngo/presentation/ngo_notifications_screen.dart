import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../services/ngo_notification_service.dart';
import '../../../services/session_service.dart';

class NgoNotificationsScreen extends StatefulWidget {
  const NgoNotificationsScreen({super.key});

  @override
  State<NgoNotificationsScreen> createState() =>
      _NgoNotificationsScreenState();
}

class _NgoNotificationsScreenState extends State<NgoNotificationsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF174A7E); // Primary Navy Blue
  static const Color darkBlue = Color(0xFF123A63); // Dark Navy
  static const Color background = Color(0xFFF7F8FA);
  static const Color cardBackground = Color(0xFFFFFFFF); // Surface/White
  static const Color softBlueGrey = Color(0xFFEAF2F9); // Light Blue
  static const Color green = Color(0xFF2E7D5B); // Success
  static const Color orange = Color(0xFFB7791F); // Warning
  static const Color red = Color(0xFFC0392B); // Danger
  static const Color redLight = Color(0xFFFCEBE9); // Danger Background
  static const Color info = Color(0xFF2468A8);
  static const Color borderColor = Color(0xFFD5D9DE);
  static const Color textDark = Color(0xFF202124); // Primary Text
  static const Color textGrey = Color(0xFF5F6368); // Secondary Text

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, darkBlue],
  );

  // ============================================================
  // SERVICE
  // ============================================================

  final NgoNotificationService _notificationService =
      NgoNotificationService.instance;

  // ============================================================
  // STATE
  // ============================================================

  List<NgoNotification> _notifications = [];

  bool _isLoading = true;
  bool _isMarkingAllRead = false;

  String? _errorMessage;

  StreamSubscription<List<NgoNotification>>?
      _notificationSubscription;

  // ============================================================
  // FILTER
  // ============================================================
  //
  // Today  -> Last 24 hours
  // Unread -> Unread notifications from last 30 days
  // All    -> All notifications from last 30 days
  //

  _NotificationFilter _selectedFilter =
      _NotificationFilter.today;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadNotifications();
    _startRealtimeNotifications();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationService.disposeRealtime();

    super.dispose();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  AppUser? get _currentUser {
    return SessionService.instance.currentUser;
  }

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    final user = _currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'User session not found.';
      });

      return;
    }

    try {
      final notifications =
          await _notificationService.fetchNotifications(
        user.id,
      );

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint(
        'NGO notifications load error: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load notifications. Please try again.';
      });
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _startRealtimeNotifications() {
    final user = _currentUser;

    if (user == null) return;

    _notificationSubscription =
        _notificationService.watchNotifications(user.id).listen(
      (notifications) {
        if (!mounted) return;

        setState(() {
          _notifications = notifications;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        debugPrint(
          'NGO notification realtime error: $error',
        );
      },
    );
  }

  // ============================================================
  // TODAY
  // ============================================================

  List<NgoNotification> get _todayNotifications {
    final now = DateTime.now();

    final twentyFourHoursAgo =
        now.subtract(const Duration(hours: 24));

    return _notifications.where((notification) {
      final createdAt = notification.createdAt.toLocal();

      return createdAt.isAfter(twentyFourHoursAgo) ||
          createdAt.isAtSameMomentAs(twentyFourHoursAgo);
    }).toList();
  }

  // ============================================================
  // UNREAD
  // ============================================================

  List<NgoNotification> get _unreadNotifications {
    final now = DateTime.now();

    final thirtyDaysAgo =
        now.subtract(const Duration(days: 30));

    return _notifications.where((notification) {
      final createdAt = notification.createdAt.toLocal();

      final withinThirtyDays =
          createdAt.isAfter(thirtyDaysAgo) ||
              createdAt.isAtSameMomentAs(thirtyDaysAgo);

      return !notification.isRead && withinThirtyDays;
    }).toList();
  }

  // ============================================================
  // LAST 30 DAYS
  // ============================================================

  List<NgoNotification> get _last30DaysNotifications {
    final now = DateTime.now();

    final thirtyDaysAgo =
        now.subtract(const Duration(days: 30));

    return _notifications.where((notification) {
      final createdAt = notification.createdAt.toLocal();

      return createdAt.isAfter(thirtyDaysAgo) ||
          createdAt.isAtSameMomentAs(thirtyDaysAgo);
    }).toList();
  }

  // ============================================================
  // ALL NOTIFICATIONS
  // ============================================================

  List<NgoNotification> get _allNotifications {
    return _last30DaysNotifications;
  }

  // ============================================================
  // DISPLAYED NOTIFICATIONS
  // ============================================================

  List<NgoNotification> get _displayedNotifications {
    switch (_selectedFilter) {
      case _NotificationFilter.today:
        return _todayNotifications;

      case _NotificationFilter.unread:
        return _unreadNotifications;

      case _NotificationFilter.all:
        return _allNotifications;
    }
  }

  // ============================================================
  // TOTAL UNREAD COUNT
  // ============================================================

  int get _unreadCount {
    return _notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  // ============================================================
  // TODAY COUNT
  // ============================================================

  int get _todayCount {
    return _todayNotifications.length;
  }

  // ============================================================
  // ALL COUNT
  // ============================================================

  int get _allCount {
    return _allNotifications.length;
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> _markAsRead(
    NgoNotification notification,
  ) async {
    if (notification.isRead) return;

    // ----------------------------------------------------------
    // Optimistic UI update
    // ----------------------------------------------------------

    setState(() {
      _notifications = _notifications.map((item) {
        if (item.id == notification.id) {
          return NgoNotification(
            id: item.id,
            title: item.title,
            message: item.message,
            type: item.type,
            isRead: true,
            createdAt: item.createdAt,
          );
        }

        return item;
      }).toList();
    });

    // ----------------------------------------------------------
    // Update Supabase
    // ----------------------------------------------------------

    try {
      await _notificationService.markAsRead(
        notification.id,
      );
    } catch (error) {
      debugPrint(
        'Mark notification as read error: $error',
      );

      await _loadNotifications();
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _markAllAsRead() async {
    final user = _currentUser;

    if (user == null || _unreadCount == 0) {
      return;
    }

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await _notificationService.markAllAsRead(
        user.id,
      );

      await _loadNotifications();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'All notifications marked as read.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      debugPrint(
        'Mark all notifications as read error: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to mark notifications as read.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (!mounted) return;

      setState(() {
        _isMarkingAllRead = false;
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadNotifications();
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData _getNotificationIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'attendance':
        return Icons.groups_rounded;

      case 'report':
      case 'reports':
        return Icons.description_rounded;

      case 'camera':
      case 'cctv':
        return Icons.videocam_rounded;

      case 'warning':
      case 'alert':
      case 'risk':
        return Icons.warning_amber_rounded;

      case 'inspection':
        return Icons.fact_check_rounded;

      case 'system':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  // ============================================================
  // NOTIFICATION COLOR
  // ============================================================

  Color _getNotificationColor(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'attendance':
        return green;

      case 'report':
      case 'reports':
        return darkBlue;

      case 'camera':
      case 'cctv':
        return navy;

      case 'warning':
      case 'alert':
      case 'risk':
        return orange;

      case 'inspection':
        return orange;

      case 'system':
      default:
        return darkBlue;
    }
  }

  // ============================================================
  // DATE/TIME
  // ============================================================

  String _formatNotificationTime(
    DateTime dateTime,
  ) {
    final localDateTime = dateTime.toLocal();

    final now = DateTime.now();

    final difference =
        now.difference(localDateTime);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;

      return '$minutes min${minutes == 1 ? '' : 's'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;

      return '$hours hr${hours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;

      return '$days day${days == 1 ? '' : 's'} ago';
    }

    final day =
        localDateTime.day.toString().padLeft(2, '0');

    final month =
        localDateTime.month.toString().padLeft(2, '0');

    final year =
        localDateTime.year.toString();

    final hour =
        localDateTime.hour.toString().padLeft(2, '0');

    final minute =
        localDateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: darkBlue,
        backgroundColor: Colors.white,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: primaryGradient),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 18,

      title: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            size: 24,
          ),

          const SizedBox(width: 9),

          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),

            Container(
              constraints: const BoxConstraints(
                minWidth: 21,
                minHeight: 21,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              decoration: const BoxDecoration(
                color: red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 99
                      ? '99+'
                      : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),

      actions: [
        if (_unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: TextButton(
              onPressed: _isMarkingAllRead
                  ? null
                  : _markAllAsRead,
              child: _isMarkingAllRead
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Read all',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.35,
            child: const Center(
              child: CircularProgressIndicator(
                color: darkBlue,
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 90),
          _buildErrorState(),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        24,
      ),

      children: [
        _buildIntroCard(),

        const SizedBox(height: 16),

        _buildFilterTabs(),

        const SizedBox(height: 18),

        _buildNotificationContent(),
      ],
    );
  }

  // ============================================================
  // INTRO CARD
  // ============================================================

  Widget _buildIntroCard() {
    String message;

    if (_unreadCount == 0) {
      message = 'You are all caught up.';
    } else if (_unreadCount == 1) {
      message = '1 unread notification requires your attention.';
    } else {
      message =
          '$_unreadCount unread notifications require your attention.';
    }

    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: softBlueGrey,
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: const Icon(
              Icons.notifications_rounded,
              color: darkBlue,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Notification Centre',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER TABS
  // ============================================================

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: softBlueGrey,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              title: 'Today',
              count: _todayCount,
              selected:
                  _selectedFilter ==
                      _NotificationFilter.today,
              onTap: () {
                setState(() {
                  _selectedFilter =
                      _NotificationFilter.today;
                });
              },
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildFilterButton(
              title: 'Unread',
              count: _unreadCount,
              selected:
                  _selectedFilter ==
                      _NotificationFilter.unread,
              onTap: () {
                setState(() {
                  _selectedFilter =
                      _NotificationFilter.unread;
                });
              },
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildFilterButton(
              title: 'All',
              count: _allCount,
              selected:
                  _selectedFilter ==
                      _NotificationFilter.all,
              onTap: () {
                setState(() {
                  _selectedFilter =
                      _NotificationFilter.all;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _buildFilterButton({
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      borderRadius:
          BorderRadius.circular(9),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(9),

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),

          padding:
              const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 5,
          ),

          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.transparent,

            borderRadius:
                BorderRadius.circular(9),

            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 4,
                      offset:
                          const Offset(0, 2),
                    ),
                  ]
                : null,
          ),

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    color: selected
                        ? navy
                        : textGrey,

                    fontSize: 11,

                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),

              if (count > 0) ...[
                const SizedBox(width: 5),

                Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),

                  decoration: BoxDecoration(
                    color: selected
                        ? darkBlue
                        : Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),

                  child: Center(
                    child: Text(
                      count > 99
                          ? '99+'
                          : '$count',

                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : navy,

                        fontSize: 9,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CONTENT
  // ============================================================

  Widget _buildNotificationContent() {
    final notifications =
        _displayedNotifications;

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    String heading;

    switch (_selectedFilter) {
      case _NotificationFilter.today:
        heading = 'Today';

      case _NotificationFilter.unread:
        heading = 'Unread Notifications';

      case _NotificationFilter.all:
        heading = 'All Notifications';
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: const TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            Text(
              '${notifications.length} '
              'item${notifications.length == 1 ? '' : 's'}',

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ...notifications.map(
          (notification) => Padding(
            padding:
                const EdgeInsets.only(
              bottom: 9,
            ),

            child:
                _buildNotificationCard(
              notification,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard(
    NgoNotification notification,
  ) {
    final isUnread =
        !notification.isRead;

    final iconColor =
        _getNotificationColor(
      notification.type,
    );

    return Material(
      color: Colors.transparent,

      borderRadius:
          BorderRadius.circular(13),

      child: InkWell(
        onTap: () {
          _markAsRead(notification);
        },

        borderRadius:
            BorderRadius.circular(13),

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),

          padding:
              const EdgeInsets.all(13),

          decoration: BoxDecoration(
            color: isUnread
                ? Colors.white
                : background,

            borderRadius:
                BorderRadius.circular(13),

            border: Border.all(
              color: isUnread
                  ? const Color(0xFFBFD9EC)
                  : borderColor,
            ),

            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.035,
                      ),
                      blurRadius: 6,
                      offset:
                          const Offset(0, 2),
                    ),
                  ]
                : null,
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // ICON + UNREAD DOT
              // ==================================================

              Stack(
                clipBehavior: Clip.none,

                children: [
                  Container(
                    width: 43,
                    height: 43,

                    decoration:
                        BoxDecoration(
                      color:
                          iconColor.withValues(
                        alpha: 0.10,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: Icon(
                      _getNotificationIcon(
                        notification.type,
                      ),

                      color: iconColor,
                      size: 22,
                    ),
                  ),

                  // ------------------------------------------------
                  // RED UNREAD DOT
                  // ------------------------------------------------

                  if (isUnread)
                    Positioned(
                      right: -2,
                      top: -2,

                      child: Container(
                        width: 11,
                        height: 11,

                        decoration:
                            BoxDecoration(
                          color: red,
                          shape:
                              BoxShape.circle,

                          border:
                              Border.all(
                            color:
                                Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ----------------------------------------------
                    // TITLE + TIME
                    // ----------------------------------------------

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Text(
                            notification.title,

                            maxLines: 2,

                            overflow:
                                TextOverflow.ellipsis,

                            style: TextStyle(
                              color: textDark,
                              fontSize: 13,

                              fontWeight:
                                  isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 5),

                        Flexible(
                          child: Text(
                            _formatNotificationTime(
                              notification
                                  .createdAt,
                            ),

                            maxLines: 1,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 8,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // ----------------------------------------------
                    // MESSAGE
                    // ----------------------------------------------

                    Text(
                      notification.message,

                      maxLines: 4,

                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ----------------------------------------------
                    // TYPE + STATUS
                    // ----------------------------------------------

                    Row(
                      children: [
                        // ------------------------------------------
                        // TYPE
                        // ------------------------------------------

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                softBlueGrey,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              6,
                            ),
                          ),

                          child: Text(
                            _formatType(
                              notification.type,
                            ),

                            style:
                                const TextStyle(
                              color: navy,
                              fontSize: 8,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // ------------------------------------------
                        // UNREAD
                        // ------------------------------------------

                        if (isUnread)
                          const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: red,
                                size: 6,
                              ),

                              SizedBox(width: 4),

                              Text(
                                'Unread',
                                style: TextStyle(
                                  color:
                                      red,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          )

                        // ------------------------------------------
                        // READ
                        // ------------------------------------------

                        else
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .check_circle_rounded,
                                color:
                                    Colors.grey,
                                size: 12,
                              ),

                              SizedBox(width: 4),

                              Text(
                                'Read',
                                style: TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPE TEXT
  // ============================================================

  String _formatType(
    String type,
  ) {
    if (type.trim().isEmpty) {
      return 'System';
    }

    final value = type
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    if (value.isEmpty) {
      return 'System';
    }

    return value
        .split(' ')
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) =>
              '${word[0].toUpperCase()}'
              '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    IconData icon;
    String title;
    String message;

    switch (_selectedFilter) {
      case _NotificationFilter.today:
        icon = Icons.today_rounded;
        title = 'No notifications today';
        message =
            'Notifications received during the last 24 hours will appear here.';
        break;

      case _NotificationFilter.unread:
        icon = Icons.notifications_none_rounded;
        title = 'No unread notifications';
        message =
            'You are all caught up. New notifications will appear here automatically.';
        break;

      case _NotificationFilter.all:
        icon = Icons.history_rounded;
        title = 'No notifications in the last 30 days';
        message =
            'Your notification history from the last 30 days will appear here.';
        break;
    }

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 38,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: borderColor,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,

            decoration:
                const BoxDecoration(
              color: softBlueGrey,
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: darkBlue,
              size: 31,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              height: 1.4,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: borderColor,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.grey,
            size: 42,
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage ??
                'Something went wrong.',

            textAlign:
                TextAlign.center,

            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _loadNotifications,

            style:
                ElevatedButton.styleFrom(
              backgroundColor: darkBlue,
              foregroundColor:
                  Colors.white,
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
              ),
            ),

            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),

            label: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// NOTIFICATION FILTER
// ================================================================

enum _NotificationFilter {
  today,
  unread,
  all,
}