// --- HÀM KHỞI TẠO PHÒNG MỚI VÀ TỰ ĐỘNG THÊM 4 THIẾT BỊ MẪU LÊN FIRESTORE ---
Future<void> addRoomWithDefaultDevices(String newRoomNumber, BuildContext context) async {
  if (newRoomNumber.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vui lòng nhập số phòng!"), backgroundColor: Colors.redAccent),
    );
    return;
  }

  // Khởi tạo hàng đợi chứa cấu hình 4 thiết bị IoT mẫu chuẩn của nhóm ông
  final List<Map<String, dynamic>> defaultDevices = [
    {'name': 'Bóng đèn', 'type': 'light', 'watt': 20},
    {'name': 'Quạt máy', 'type': 'fan', 'watt': 65},
    {'name': 'Điều hòa', 'type': 'ac', 'watt': 1200},
    {'name': 'Khóa cửa', 'type': 'lock', 'watt': 10}
  ];

  try {
    final firestore = FirebaseFirestore.instance;
    
    // Sử dụng WriteBatch (Cơ chế tương đương Transaction của SQL để ghi đồng loạt bảo mật)
    WriteBatch batch = firestore.batch();

    for (var device in defaultDevices) {
      // Tạo một tài liệu (document) ngẫu nhiên mới trong collection 'devices'
      DocumentReference deviceRef = firestore.collection('devices').doc();

      // Định dạng chuỗi Topic MQTT đồng bộ theo số phòng (ví dụ: vku/nhatlong/room101/all)
      String cleanRoomNumber = newRoomNumber.trim().replaceAll('_', '');
      String mqttTopic = "vku/nhatlong/room$cleanRoomNumber/all";

      batch.set(deviceRef, {
        'room_id': newRoomNumber.trim(), // Mã phòng quản lý
        'device_name': device['name'],
        'device_type': device['type'],
        'status': '0', // Mặc định ban đầu ở trạng thái TẮT
        'mqtt_topic': mqttTopic,
        'watt_usage': device['watt'],
        'total_kwh': 0.0, // Chỉ số điện năng tiêu thụ ban đầu bằng 0
        'created_at': DateTime.now().toString().substring(0, 19),
      });
    }

    // Thực thi đẩy đồng loạt 4 thiết bị lên mây cùng 1 thời điểm (0ms delay)
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Đã tạo xong phòng $newRoomNumber và 4 thiết bị IoT!"),
          backgroundColor: const Color(0xFF072C6C), // Màu vkuBlue đặc trưng
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    debugPrint("Lỗi khởi tạo phòng IoT mây: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }
}