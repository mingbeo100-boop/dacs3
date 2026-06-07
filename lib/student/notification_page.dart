import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để lắng nghe thông báo thời gian thực

class NotificationPage extends StatefulWidget {
  final String userId; // Nhận Mã sinh viên (username) từ trang chủ truyền sang
  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);

  @override
  Widget build(BuildContext context) {
    // TẠO LUỒNG LẮNG NGHE THỜI GIAN THỰC (REALTIME STREAM)
    // Lọc ra các thông báo dành riêng cho Mã sinh viên này, xếp tin mới nhất lên đầu
    final Stream<QuerySnapshot> _notificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('username', isEqualTo: widget.userId.trim())
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("THÔNG BÁO CỦA BẠN", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: vkuBlue,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải thông báo: ${snapshot.error}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: vkuOrange));
          }

          // Chuyển đổi dữ liệu tài liệu Firestore sang danh sách List
          List<dynamic> notifications = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Giữ lại ID tài liệu phục vụ cập nhật trạng thái đã đọc (is_read) nếu cần
            return data;
          }).toList();

          return notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) => _buildNotiCard(notifications[index]),
          );
        },
      ),
    );
  }

  Widget _buildNotiCard(dynamic noti) {
    // Trạng thái đã đọc hỗ trợ cả kiểu bool hoặc kiểu chuỗi/số cũ từ SQL của bạn
    bool isRead = noti['is_read'] == true || noti['is_read'].toString() == "1" || noti['is_read'].toString() == "true";

    return GestureDetector(
      onTap: () async {
        // TÍNH NĂNG THÊM: Sinh viên ấn vào thông báo thì tự động cập nhật đã đọc 'is_read = true' lên mây luôn
        if (!isRead) {
          try {
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(noti['id'].toString())
                .update({'is_read': true});
          } catch (e) {
            debugPrint("Lỗi cập nhật trạng thái đã đọc thông báo: $e");
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRead ? Colors.white.withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isRead ? null : Border.all(color: vkuOrange.withOpacity(0.3), width: 1.5),
          boxShadow: isRead ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                  Text(noti['title'] ?? "Thông báo", style: TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(noti['content'] ?? "", style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 10),
                  Text(noti['created_at'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            if (!isRead) Container(width: 10, height: 10, decoration: const BoxDecoration(color: vkuOrange, shape: BoxShape.circle)),
          ],
        ),
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