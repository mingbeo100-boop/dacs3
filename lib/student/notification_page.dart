import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  final String userId;
  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);

  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await http.get(Uri.parse("http://192.168.4.21/dacs3/manage_notifications.php?user_id=${widget.userId}"));
      if (res.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(res.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("THÔNG BÁO CỦA BẠN", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: vkuBlue,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: vkuOrange))
          : notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) => _buildNotiCard(notifications[index]),
      ),
    );
  }

  Widget _buildNotiCard(dynamic noti) {
    bool isRead = noti['is_read'].toString() == "1";
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRead ? Colors.white.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isRead ? null : Border.all(color: vkuOrange.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_rounded, color: isRead ? Colors.grey : vkuOrange, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(noti['title'], style: TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 14)),
                const SizedBox(height: 5),
                Text(noti['content'], style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
                const SizedBox(height: 10),
                Text(noti['created_at'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          if (!isRead) Container(width: 10, height: 10, decoration: const BoxDecoration(color: vkuOrange, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text("Bạn chưa có thông báo nào", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}