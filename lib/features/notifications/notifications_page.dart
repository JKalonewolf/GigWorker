import 'package:flutter/material.dart';
import 'package:gigworker/models/notification_model.dart';
import 'package:gigworker/services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  final String phoneNumber;

  const NotificationsPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final NotificationService _notifService = NotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _notifService.markAllAsRead(phoneNumber);
            },
            tooltip: "Mark all as read",
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notifService.streamNotifications(phoneNumber),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final notifs = snap.data ?? [];

          if (notifs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final n = notifs[index];
              return _NotificationTile(
                phoneNumber: phoneNumber,
                notification: n,
                service: _notifService,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String phoneNumber;
  final AppNotification notification;
  final NotificationService service;

  const _NotificationTile({
    required this.phoneNumber,
    required this.notification,
    required this.service,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return dt.toLocal().toString().split(' ').first;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'kyc':
        return Icons.verified_user;
      case 'loan':
        return Icons.request_page;
      case 'emi':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'kyc':
        return Colors.greenAccent;
      case 'loan':
        return Colors.cyanAccent;
      case 'emi':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(notification.type);

    return InkWell(
      onTap: () async {
        if (!notification.read) {
          await service.markAsRead(phoneNumber, notification.id);
        }
        // You can also navigate to relevant screen based on notification.type here.
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF202020), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF181818),
              child: Icon(
                _iconForType(notification.type),
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: notification.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (!notification.read)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "New",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
