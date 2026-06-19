import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để dò bảng dữ liệu
import 'dart:convert'; // BẮT BUỘC: Giải mã chuỗi Base64 ảnh hàng hóa trực tiếp
import '../maketplace/add_product_page.dart';
import '../maketplace/edit_product_page.dart';
import '../maketplace/product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  final String userId; // Nhận Mã sinh viên (username) luân chuyển từ LoginPage -> HomePage sang
  final String role;

  const MarketplacePage({super.key, required this.userId, required this.role});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  static const vkuBlue = Color(0xFF002266);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const marketAccent = Color(0xFF81A4B1);
  static const priceRed = Color(0xFFB30000);

  bool get isAdmin => widget.role == 'admin';

  @override
  Widget build(BuildContext context) {
    // TẠO LUỒNG LẮNG NGHE DỮ LIỆU CHỢ THỜI GIAN THỰC (REALTIME STREAM)
    final Stream<QuerySnapshot> _productStream = FirebaseFirestore.instance
        .collection('marketplace')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _productStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Lỗi tải dữ liệu chợ sinh viên."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: vkuBlue));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Không có dữ liệu hàng hóa."));
            }

            List<dynamic> products = snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              cacheExtent: 1500,
              slivers: [
                _buildSliverAppBar(),

                products.isEmpty
                    ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "Chợ KTX hiện tại chưa có mặt hàng nào.",
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.all(15),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildOptimizedProductItem(products[index]),
                      childCount: products.length,
                      addRepaintBoundaries: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // MỞ FAB ĐĂNG BÀI: Cho phép tất cả cư dân đăng bán đồ cũ (Sinh viên & Admin đều dùng được)
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Text(
              "CHỢ SINH VIÊN VKU",
              style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIÊU TỐI ƯU LUỒNG HIỂN THỊ: BAO QUÉT ĐA NĂNG CẢ ẢNH MẠNG LẪN ẢNH BASE64 TRÊN CARD ---
  Widget _buildOptimizedProductItem(dynamic item) {
    String imageUrl = (item['image_url'] ?? "").toString().trim();
    ImageProvider? cardImageProvider;

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        // Luồng 1: Nếu là đường link URL mây storage bình thường
        cardImageProvider = NetworkImage(imageUrl);
      } else {
        // Luồng 2: Tự động bắt cặp giải mã chuỗi Base64 ảnh hàng hóa siêu tốc
        try {
          String cleanStr = imageUrl.replaceAll('\n', '').replaceAll('\r', '').trim();
          if (cleanStr.contains(',')) {
            cleanStr = cleanStr.split(',')[1];
          }
          cardImageProvider = MemoryImage(base64Decode(cleanStr));
        } catch (e) {
          debugPrint("Lỗi phân rã Base64 ảnh hàng hóa: $e");
        }
      }
    }

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          // ADMIN vào sẽ mở trang Chỉnh sửa/Xóa (EditProductPage), SINH VIÊN vào mở xem Chi tiết (ProductDetailPage)
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => isAdmin ? EditProductPage(product: item) : ProductDetailPage(product: item)
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: cardImageProvider != null
                      ? Image(
                    image: cardImageProvider,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: marketAccent)),
                  )
                      : Container(
                    color: Colors.grey[200],
                    width: double.infinity,
                    child: const Icon(Icons.image_not_supported_rounded, color: marketAccent),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? "Sản phẩm",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: vkuBlue),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("${item['price']} đ",
                        style: const TextStyle(color: priceRed, fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle_rounded, size: 10, color: marketAccent),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item['fullname'] ?? item['username'] ?? "Sinh viên VKU",
                            style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.w600), maxLines: 1)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: vkuBlue,
      elevation: 8,
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AddProductPage(userId: widget.userId),
        ));
      },
      child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
    );
  }
}