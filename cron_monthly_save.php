// --- HÀM TỰ ĐỘNG CHỐT SỐ ĐIỆN VÀ KHỞI TẠO HOÁ ĐƠN MÂY (THAY THẾ FILE PHP) ---
Future<void> cronMonthlyPowerSave(BuildContext context, VoidCallback onRefreshCallback) async {
  final int currentMonth = DateTime.now().month;
  final int currentYear = DateTime.now().year;
  const double pricePerKwh = 3500.0; // Đơn giá điện chuẩn 3.500 VNĐ/kWh của VKU

  try {
    final firestore = FirebaseFirestore.instance;
    
    // Bước 1: Lấy toàn bộ danh sách thiết bị từ collection 'devices'
    final deviceSnapshot = await firestore.collection('devices').get();
    
    if (deviceSnapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Không có dữ liệu thiết bị trên mây để chốt số!"), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // Bước 2: Gom tổng lượng điện tiêu thụ (total_kwh) theo từng room_id trên RAM
    final Map<String, double> roomConsumptionMap = {};
    for (var doc in deviceSnapshot.docs) {
      final data = doc.data();
      final String roomId = data['room_id']?.toString() ?? "";
      final double totalKwh = double.tryParse(data['total_kwh']?.toString() ?? '0') ?? 0.0;
      
      if (roomId.isNotEmpty) {
        roomConsumptionMap[roomId] = (roomConsumptionMap[roomId] ?? 0.0) + totalKwh;
      }
    }

    // Bước 3: Quét kiểm tra trùng lặp và tiến hành tạo hóa đơn mới bằng WriteBatch
    int createdInvoicesCount = 0;
    WriteBatch batch = firestore.batch();

    // Lấy danh sách hóa đơn hiện tại của tháng và năm đó để đối soát chống tạo trùng
    final existingInvoicesSnapshot = await firestore
        .collection('invoices')
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: currentYear)
        .get();

    // Đưa các mã phòng đã có hóa đơn trong tháng vào Set để tra cứu nhanh 0ms
    final Set<String> existingRooms = existingInvoicesSnapshot.docs
        .map((doc) => doc.data()['room_id']?.toString() ?? "")
        .toSet();

    // Duyệt qua từng phòng để tính tiền và tạo hóa đơn
    for (var entry in roomConsumptionMap.entries) {
      final String roomId = entry.key;
      final double consumption = entry.value;
      final double amount = (consumption * pricePerKwh).roundToDouble(); // Tính thành tiền điện

      // Nếu phòng này chưa được chốt hóa đơn trong tháng hiện tại -> Tiến hành băm document mới
      if (!existingRooms.contains(roomId)) {
        DocumentReference invoiceRef = firestore.collection('invoices').doc();
        
        batch.set(invoiceRef, {
          'room_id': roomId,
          'usage_kwh': consumption, // Số điện tiêu thụ
          'amount': amount,          // Thành tiền điện (VNĐ)
          'month': currentMonth,
          'year': currentYear,
          'status': 0,               // Mặc định: 0 - CHƯA ĐÓNG TIỀN
          'receipt_image': '',       // Trống, chờ sinh viên tải biên lai lên
          'created_at': DateTime.now().toString().substring(0, 19),
        });
        createdInvoicesCount++;
      }
    }

    // Thực thi lệnh ghi đồng loạt lên mây Firebase
    if (createdInvoicesCount > 0) {
      await batch.commit();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚡ Đã chốt số điện thành công cho $createdInvoicesCount phòng trong Tháng $currentMonth/$currentYear!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Gọi lại hàm làm mới dữ liệu để cập nhật biểu đồ và bộ tiến trình LinearProgressIndicator trên UI
      onRefreshCallback();
    }

  } catch (e) {
    debugPrint("Lỗi chốt số điện hệ thống mây: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi hệ thống: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }
}