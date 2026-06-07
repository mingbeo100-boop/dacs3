// --- HÀM TẢI DATA BIỂU ĐỒ VÀ CHI TIẾT PHÒNG THAY THẾ CHO FILE PHP CŨ ---
Future<void> _fetchData() async {
  if (!mounted) return;
  setState(() => isLoading = true);
  try {
    final firestore = FirebaseFirestore.instance;
    int targetMonth = int.tryParse(filterMonth) ?? DateTime.now().month;
    int targetYear = int.tryParse(filterYear) ?? DateTime.now().year;

    // Bước A: Tải toàn bộ danh sách thiết bị để tính lượng điện tiêu thụ hiện tại của các phòng
    final deviceSnapshot = await firestore.collection('devices').get();
    
    // Map gom lượng điện và số thiết bị theo room_id
    final Map<String, double> roomPowerMap = {};
    final Map<String, int> roomDeviceCountMap = {};
    
    for (var doc in deviceSnapshot.docs) {
      final d = doc.data();
      final String rId = d['room_id']?.toString() ?? "";
      final double totalKwh = double.tryParse(d['total_kwh']?.toString() ?? '0') ?? 0.0;
      
      if (rId.isNotEmpty) {
        roomPowerMap[rId] = (roomPowerMap[rId] ?? 0.0) + totalKwh;
        roomDeviceCountMap[rId] = (roomDeviceCountMap[rId] ?? 0) + 1;
      }
    }

    // Bước B: Tải danh sách hóa đơn đóng tiền của tháng/năm đang lọc để bốc trường 'status'
    final invoiceSnapshot = await firestore
        .collection('invoices')
        .where('month', isEqualTo: targetMonth)
        .where('year', isEqualTo: targetYear)
        .get();

    final Map<String, int> roomInvoiceStatusMap = {};
    for (var doc in invoiceSnapshot.docs) {
      final inv = doc.data();
      final String rId = inv['room_id']?.toString() ?? "";
      if (rId.isNotEmpty) {
        roomInvoiceStatusMap[rId] = int.tryParse(inv['status']?.toString() ?? '0') ?? 0;
      }
    }

    // Bước C: Kết hợp (Join) dữ liệu để dựng mảng chi tiết phòng cho Admin
    double currentTotalKtx = 0.0;
    final List<Map<String, dynamic>> parsedRooms = [];

    roomPowerMap.forEach((roomId, usage) {
      currentTotalKtx += usage;
      parsedRooms.add({
        "room": roomId,
        "usage": usage,
        "device_count": roomDeviceCountMap[roomId] ?? 0,
        "status": roomInvoiceStatusMap[roomId] ?? 0, // 0: Chưa đóng, 1: Chờ duyệt, 2: Đã đóng
      });
    });

    // Sắp xếp danh sách phòng tăng dần cho dễ quản lý
    parsedRooms.sort((a, b) => a['room'].toString().compareTo(b['room'].toString()));

    // Bước D: Tải xu hướng tiêu thụ 12 tháng của năm đang lọc phục vụ LineChart
    final allInvoicesInYearSnapshot = await firestore
        .collection('invoices')
        .where('year', isEqualTo: targetYear)
        .get();

    final Map<int, double> monthlyChartMap = { for (var i = 1; i <= 12; i++) i : 0.0 };
    for (var doc in allInvoicesInYearSnapshot.docs) {
      final inv = doc.data();
      int m = int.tryParse(inv['month']?.toString() ?? '1') ?? 1;
      double amt = double.tryParse(inv['usage_kwh']?.toString() ?? '0') ?? 0.0;
      monthlyChartMap[m] = (monthlyUsageMap[m] ?? 0.0) + amt;
    }

    final List<Map<String, dynamic>> parsedChartData = monthlyChartMap.entries.map((e) => {
      "month": "T${e.key < 10 ? '0' : ''}${e.key}",
      "usage": e.value
    }).toList();

    // Đồng bộ cập nhật lên giao diện 120 FPS
    setState(() {
      totalKtxUsage = currentTotalKtx;
      roomData = parsedRooms;
      historyChartData = parsedChartData;
      isLoading = false;
    });

  } catch (e) { 
    debugPrint("Lỗi tải tổng quan Admin điện mây: $e");
    if (mounted) setState(() => isLoading = false); 
  }
}