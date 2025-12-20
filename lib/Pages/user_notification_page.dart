import 'package:Velorex/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserNotificationPage extends StatefulWidget {
 final String userId;
  const UserNotificationPage({super.key, required this.userId,});

  @override
  State<UserNotificationPage> createState() => _UserNotificationPageState();
}

class _UserNotificationPageState extends State<UserNotificationPage> {
  bool loading = true;
  List notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await NotificationService.getNotifications(widget.userId);
      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading notifications: $e");
      setState(() => loading = false);
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return '';
    return DateFormat('dd MMM, yyyy • hh:mm a').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "🔔 Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text("No notifications yet 📭",
                      style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final title = item['Title'] ?? '';
                    final message = item['Description'] ?? '';
                    final imageUrl = item['ImageUrl'];
                    final createdAt = item['CreatedAt'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.notifications,
                                    color: Colors.deepPurple,
                                    size: 32,
                                  ),
                                ),
                              )
                            : const Icon(Icons.notifications_active,
                                color: Colors.deepPurple, size: 30),
                        title: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(message),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
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
