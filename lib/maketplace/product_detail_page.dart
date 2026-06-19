import 'package:flutter/material.dart';
import 'dart:convert'; // BẮT BUỘC: Giải mã Base64 ảnh hàng hóa tại chỗ

class ProductDetailPage extends StatelessWidget {
  final dynamic product;
  const ProductDetailPage({super.key, required this.product});

  static const vkuBlue = Color(0xFF002266);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const priceRed = Color(0xFFB30000);

  // --- HÀM TRỢ GIÚP GIẢI MÃ CHUỖI BASE64 ĐA NĂNG ---
  ImageProvider? _parseBase64Image(String rawBase64) {
    if (rawBase64.trim().isEmpty) return null;
    try {
      String cleanStr = rawBase64.replaceAll('\n', '').replaceAll('\r', '').trim();
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',')[1];
      }
      return MemoryImage(base64Decode(cleanStr));
    } catch (e) {
      debugPrint("Lỗi giải mã ảnh chi tiết: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = (product['image_url'] ?? "").toString().trim();
    ImageProvider? imageProvider;

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        imageProvider = NetworkImage(imageUrl);
      } else {
        imageProvider = _parseBase64Image(imageUrl);
      }
    }

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("CHI TIẾT SẢN PHẨM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: vkuBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Khu vực hiển thị ảnh sản phẩm kích thước lớn
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: imageProvider != null
                  ? Image(image: imageProvider, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported_rounded, size: 80, color: Colors.grey),
            ),

            // Khu vực thông tin chi tiết sản phẩm
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? "Sản phẩm không tên",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: vkuBlue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${product['price'] ?? '0'} đ",
                    style: const TextStyle(fontSize: 18, color: priceRed, fontWeight: FontWeight.w900),
                  ),
                  const Divider(height: 30),
                  const Text("MÔ TẢ SẢN PHẨM:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    product['description'] ?? "Không có mô tả chi tiết.",
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey[800], height: 1.5),
                  ),
                  const Divider(height: 30),

                  // Thông tin người bán
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: sandBg,
                        child: Icon(Icons.person, color: vkuBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['fullname'] ?? "Cư dân VKU", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: vkuBlue)),
                            Text("MSSV: ${product['username'] ?? 'Ẩn danh'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Nút liên hệ mua hàng
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vkuBlue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Chức năng chat với ${product['fullname'] ?? 'người bán'} đang được phát triển!")),
                        );
                      },
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text("LIÊN HỆ NGƯỜI BÁN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}