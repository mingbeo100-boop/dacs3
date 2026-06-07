import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  // Class này bây giờ đóng vai trò là một Helper tập trung để bốc nhanh dữ liệu Firestore khi cần.
  // Bạn không còn cần biến 'baseUrl' hay các hàm http.post/get nữa.

  /// Hàm phụ trợ: Lấy nhanh thông tin chi tiết của một sinh viên dựa vào Mã sinh viên (username)
  static Future<Map<String, dynamic>?> getUserProfile(String username) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username.trim().toUpperCase())
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        data['id'] = userDoc.id; // Gán ID tài liệu làm định danh
        return data;
      }
      return null;
    } catch (e) {
      print("Lỗi helper ApiService khi lấy profile: $e");
      return null;
    }
  }
}