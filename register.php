Future<void> registerStudentCloud({
  required String fullname,
  required String username, // Mã sinh viên
  required String password,
  required String roomInput,
  required BuildContext context,
}) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // 1. Kiểm tra mã sinh viên đã tồn tại trên mây chưa
    final userCheck = await firestore.collection('users').doc(username.trim()).get();
    if (userCheck.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Mã sinh viên này đã tồn tại trên mây!"), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // 2. Tự động kiểm tra và chèn 4 thiết bị mẫu nếu phòng chưa từng có trên hệ thống
    final deviceCheck = await firestore.collection('devices').where('room_id', isEqualTo: roomInput.trim()).get();
    
    if (deviceCheck.docs.isEmpty) {
      WriteBatch deviceBatch = firestore.batch();
      final List<Map<String, dynamic>> defaultDevices = [
        {'name': 'Bóng đèn', 'type': 'light', 'watt': 20},
        {'name': 'Quạt máy', 'type': 'fan', 'watt': 65},
        {'name': 'Điều hòa', 'type': 'ac', 'watt': 1200},
        {'name': 'Khóa cửa', 'type': 'lock', 'watt': 10}
      ];

      for (var d in defaultDevices) {
        DocumentReference devRef = firestore.collection('devices').doc();
        String cleanRoom = roomInput.trim().replaceAll('_', '');
        deviceBatch.set(devRef, {
          'room_id': roomInput.trim(),
          'device_name': d['name'],
          'device_type': d['type'],
          'status': '0',
          'mqtt_topic': "vku/nhatlong/room$cleanRoom/all",
          'watt_usage': d['watt'],
          'total_kwh': 0.0,
        });
      }
      await deviceBatch.commit();
    }

    // 3. Sử dụng WriteBatch tạo đồng bộ bản ghi bảng users và profiles khít khịt
    WriteBatch userBatch = firestore.batch();
    DocumentReference userRef = firestore.collection('users').doc(username.trim());
    DocumentReference profileRef = firestore.collection('profiles').doc();

    userBatch.set(userRef, {
      'fullname': fullname.trim(),
      'username': username.trim(),
      'password': password.trim(), // Long nhớ dùng mật khẩu thô đã giải quyết lỗi băm MySQL nhé
      'room_id': roomInput.trim(),
      'role': 'student',
      'created_at': DateTime.now().toString().substring(0, 19),
    });

    userBatch.set(profileRef, {
      'user_id': username.trim(),
      'fullname': fullname.trim(),
      'room_id': roomInput.trim(),
      'avatar_url': '',
      'phone': '',
      'cccd': '',
    });

    await userBatch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Đăng ký thành công lên hệ thống mây!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    debugPrint("Lỗi đăng ký mây: $e");
  }
}