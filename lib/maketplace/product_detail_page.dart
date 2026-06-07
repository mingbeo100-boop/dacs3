import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final Map product; // Nhận cục data Map truyền từ Grid lưới sang
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // --- HỆ MÀU SMART DORM VKU ---
    const vkuBlue = Color(0xFF072C6C);
    const vkuOrange = Color(0xFFFF8C00);
    const sandBg = Color(0xFFF5E1C5);
    const cardBg = Color(0xFFFFF8F0);

    // ĐỒNG BỘ: Đón đầu link ảnh online trực tiếp từ Firebase Storage
    String imageUrl = product['image_url'] ?? "";

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text(
            "CHI TIẾT SẢN PHẨM",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)
        ),
        backgroundColor: vkuBlue,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PHẦN HÌNH ẢNH TRÀN VIỀN LẤY TỪ STORAGE
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                      color: vkuBlue.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10)
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                child: imageUrl.startsWith('http')
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                )
                    : const Center(
                  child: Icon(Icons.image_not_supported_rounded, size: 80, color: Colors.grey),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. TÊN SẢN PHẨM & GIÁ
                  Text(
                    product['title'] ?? "Không có tên",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: vkuBlue,
                        letterSpacing: 0.5
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: vkuOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: vkuOrange.withOpacity(0.2)),
                    ),
                    child: Text(
                      "${product['price']} VNĐ",
                      style: const TextStyle(
                          fontSize: 22,
                          color: vkuOrange,
                          fontWeight: FontWeight.w900
                      ),
                    ),
                  ),

                  const Divider(height: 50, thickness: 1, color: Colors.white),

                  // 3. THÔNG TIN GIAO DỊCH
                  _buildSectionTitle("THÔNG TIN GIAO DỊCH", vkuBlue, vkuOrange),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // ĐỒNG BỘ: Đọc chính xác fullname bốc từ bảng Firestore sang
                        _buildInfoRow(Icons.account_circle_rounded, "Người bán", product['fullname'] ?? product['username'] ?? "Sinh viên VKU", vkuBlue),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.black12, thickness: 0.5),
                        ),
                        _buildInfoRow(Icons.store_mall_directory_rounded, "Địa điểm nhận hàng", "Minimart ký túc xá (tầng 1)", vkuBlue),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. MÔ TẢ CHI TIẾT
                  _buildSectionTitle("MÔ TẢ CHI TIẾT", vkuBlue, vkuOrange),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardBg.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      product['description'] ?? "Người bán chưa cung cấp mô tả thêm.",
                      style: TextStyle(
                          fontSize: 15,
                          color: vkuBlue.withOpacity(0.8),
                          height: 1.6,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. THANH LIÊN HỆ CỐ ĐỊNH ĐỒNG BỘ MÀU
      bottomSheet: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: vkuBlue.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5)
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 55, width: 55,
              decoration: BoxDecoration(
                color: vkuBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_rounded, color: vkuBlue),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✨ Đã gửi yêu cầu hẹn tại Minimart!", style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: vkuBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vkuOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 5,
                  shadowColor: vkuOrange.withOpacity(0.4),
                ),
                child: const Text(
                  "LIÊN HỆ MUA NGAY",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color blue, Color orange) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: blue, fontWeight: FontWeight.w900, fontSize: 13)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.5))),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}