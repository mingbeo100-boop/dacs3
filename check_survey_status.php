// --- HÀM KIỂM TRA KHẢO SÁT CHUYỂN SANG FIRESTORE (THAY THẾ FILE PHP) ---
Future<bool> checkStudentSurvey(String userId) async {
  try {
    // Truy vấn thẳng vào collection 'student_preferences' tìm doc có user_id khớp
    final snapshot = await FirebaseFirestore.instance
        .collection('student_preferences')
        .where('user_id', isEqualTo: userId)
        .get();

    // Nếu snapshot không rỗng (docs.isNotEmpty) tức là đã làm khảo sát rồi -> trả về true
    return snapshot.docs.isNotEmpty;
  } catch (e) {
    debugPrint("Lỗi check khảo sát mây: $e");
    return false; // Dự phòng lỗi thì coi như chưa làm
  }
}