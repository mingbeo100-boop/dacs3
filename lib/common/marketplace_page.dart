import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Đồng bộ duy nhất qua Firestore
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
    // Sắp xếp các món đồ mới đăng lên trên đầu tiên dựa vào created_at
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

            // Chuyển đổi toàn bộ tài liệu bốc từ bảng Firestore sang danh sách List để lặp vòng lặp
            List<dynamic> products = snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Lưu lại ID bài đăng hàng hóa để phục vụ chỉnh sửa hoặc xoá bài
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
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: isAdmin ? _buildFab() : null,
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

  Widget _buildOptimizedProductItem(dynamic item) {
    String imageUrl = item['image_url'] ?? "";

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          // Nếu là admin thì đẩy thẳng qua trang cấu hình Sửa/Xoá, nếu là sinh viên thì xem Chi tiết mặt hàng
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
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    cacheWidth: 350,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
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
                        // ĐỒNG BỘ: Hiển thị Họ tên người đăng hoặc Mã sinh viên nếu trống trường dữ liệu
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
          // Truyền Mã sinh viên (username) vào form AddProductPage để lưu cấu trúc dòng chuẩn xác
          builder: (context) => AddProductPage(userId: widget.userId),
        ));
      },
      child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
    );
  }
}