// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
//
// /// Hàm upload ảnh lên Firebase Storage với cấu hình tối ưu
// Future<String?> uploadImageToStorage(File imageFile, String folderName) async {
//   try {
//     // 1. Tạo tên file duy nhất dựa trên timestamp
//     String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
//
//     // 2. Tham chiếu tới vị trí lưu trữ
//     Reference ref = FirebaseStorage.instance.ref().child('$folderName/$fileName');
//
//     // 3. Thiết lập Metadata cho file (giúp trình duyệt hiển thị đúng định dạng)
//     final metadata = SettableMetadata(contentType: 'image/jpeg');
//
//     // 4. Upload ảnh với metadata
//     TaskSnapshot snapshot = await ref.putFile(imageFile, metadata);
//
//     // 5. Lấy URL công khai
//     String downloadUrl = await snapshot.ref.getDownloadURL();
//     return downloadUrl;
//   } on FirebaseException catch (e) {
//     // Xử lý lỗi riêng cho Firebase (ví dụ: quyền truy cập, kết nối)
//     print("Lỗi Firebase Storage: ${e.message}");
//     return null;
//   } catch (e) {
//     print("Lỗi chung khi upload: $e");
//     return null;
//   }
// }