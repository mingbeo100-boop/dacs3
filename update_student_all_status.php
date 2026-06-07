Future<void> saveStudentAllStatusCloud({
  required String studentUserId,   // ID/Mã sinh viên
  required String roomId,          // Mã phòng (Ví dụ: 2_208)
  required String selectedMonth,   // Định dạng: "Tháng 05" hoặc "05"
  required String selectedYear,    // Ví dụ: "2026"
  required bool isPaidStatus,      // true nếu tích chọn đã đóng tiền
  required Map<String, bool> blueSundayStatus, // Map 4 tuần sinh hoạt xanh
  required BuildContext context,
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();

    // Chuẩn hóa định dạng tháng (bỏ chữ "Tháng" nếu có để xử lý số nguyên thống nhất)
    String monthClean = selectedMonth.replaceAll(RegExp(r'[^0-9]'), '');
    int monthNum = int.tryParse(monthClean) ?? DateTime.now().month;
    int yearNum = int.tryParse(selectedYear) ?? DateTime.now().year;

    // --- BƯỚC 1: XỬ LÝ COLLECTION 'payments' (Chuyên cần + Học phí cá nhân) ---
    final paymentQuery = await firestore
        .collection('payments')
        .where('user_id', isEqualTo: studentUserId)
        .where('month', isEqualTo: "Tháng ${monthNum < 10 ? '0' : ''}$monthNum")
        .where('year', isEqualTo: selectedYear)
        .limit(1)
        .get();

    final Map<String, dynamic> paymentPayload = {
      "user_id": studentUserId,
      "month": "Tháng ${monthNum < 10 ? '0' : ''}$monthNum",
      "year": selectedYear,
      "status": isPaidStatus ? "1" : "0",
      "week1": blueSundayStatus["Tuần 01"]! ? "1" : "0",
      "week2": blueSundayStatus["Tuần 02"]! ? "1" : "0",
      "week3": blueSundayStatus["Tuần 03"]! ? "1" : "0",
      "week4": blueSundayStatus["Tuần 04"]! ? "1" : "0",
      "updated_at": DateTime.now().toString().substring(0, 19),
    };

    if (paymentQuery.docs.isNotEmpty) {
      batch.update(paymentQuery.docs.first.reference, paymentPayload);
    } else {
      DocumentReference newPayRef = firestore.collection('payments').doc();
      batch.set(newPayRef, paymentPayload);
    }

    // --- BƯỚC 2: ĐỒNG BỘ SANG COLLECTION 'invoices' (ĂN TIỀN TẠI ĐÂY) ---
    // Tìm đúng hóa đơn của phòng này trong tháng/năm đó để lật trạng thái sang 2 (Đã duyệt đóng tiền)
    final invoiceQuery = await firestore
        .collection('invoices')
        .where('room_id', isEqualTo: roomId)
        .where('month', isEqualTo: monthNum)
        .where('year', isEqualTo: yearNum)
        .limit(1)
        .get();

    if (invoiceQuery.docs.isNotEmpty) {
      // Nếu tìm thấy hóa đơn phòng -> Cập nhật status bằng 2 lập tức để ngoài danh sách sáng xanh
      batch.update(invoiceQuery.docs.first.reference, {
        "status": isPaidStatus ? 2 : 0, 
      });
    }

    // --- BƯỚC 3: CẬP NHẬT ĐỒNG BỘ SANG PROFILE SINH VIÊN ---
    final profileQuery = await firestore
        .collection('profiles')
        .where('user_id', isEqualTo: studentUserId)
        .limit(1)
        .get();

    if (profileQuery.docs.isNotEmpty) {
      batch.update(profileQuery.docs.first.reference, {
        "is_paid": isPaidStatus ? 1 : 0,
      });
    }

    // Kích hoạt bắn lệnh đồng loạt lên mây Firebase (An toàn, nguyên tử, 0ms delay)
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã cập nhật đồng bộ trạng thái học phí & hoạt động lên mây!"), backgroundColor: Colors.green),
      );
    }
  } catch (e) {
    debugPrint("Lỗi xử lý lưu mây payments & invoices gộp: $e");
  }
}