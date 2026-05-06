import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../maketplace/add_product_page.dart';
import '../maketplace/edit_product_page.dart';
import '../maketplace/product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  final String userId;
  final String role;

  const MarketplacePage({
    super.key,
    required this.userId,
    required this.role
  });

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List products = []; // Đây là một List
  bool isLoading = true;

  // --- HỆ MÀU ĐỒNG BỘ VKU SMART DORM ---
  static const vkuBlue = Color(0xFF002266);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const marketAccent = Color(0xFF81A4B1);
  static const priceRed = Color(0xFFB30000);

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // --- HÀM LOAD SẢN PHẨM (ĐÃ FIX LỖI ÉP KIỂU) ---
  Future<void> fetchProducts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse("http://192.168.1.191/dacs3/get_products.php"));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        setState(() {
          // Kiểm tra xem Server trả về List hay Map để gán cho đúng
          if (decodedData is List) {
            products = decodedData;
          } else if (decodedData is Map && decodedData.containsKey('data')) {
            // Trường hợp PHP trả về {"status": "success", "data": [...]}
            products = decodedData['data'];
          } else {
            products = [];
            debugPrint("Dữ liệu không đúng định dạng List: $decodedData");
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint("Lỗi Server: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("Lỗi kết nối Marketplace: $e");
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.191/dacs3/delete_product.php"),
        body: {"id": productId},
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đã xóa bài đăng thành công!"),
            backgroundColor: vkuBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        fetchProducts();
      }
    } catch (e) {
      debugPrint("Lỗi xóa: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("CHỢ SINH VIÊN VKU",
            style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: sandBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: vkuBlue),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: fetchProducts
          )
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        backgroundColor: vkuBlue,
        onPressed: () async {
          bool? refresh = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddProductPage(userId: widget.userId),
          ));
          if (refresh == true) fetchProducts();
        },
        child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
      )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: vkuBlue))
          : products.isEmpty
          ? const Center(child: Text("Chưa có món đồ nào.", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold)))
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          String imageUrl = "http://192.168.1.191/dacs3/uploads/${item['image_url']}";

          return InkWell(
            onTap: () async {
              if (isAdmin) {
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProductPage(product: item)),
                );
                if (refresh == true) fetchProducts();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductDetailPage(product: item)),
                );
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: marketAccent.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5)
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    color: marketAccent.withOpacity(0.1),
                                    child: const Icon(Icons.image_not_supported_rounded, color: marketAccent)
                                ),
                          ),
                        ),
                        if (isAdmin)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _confirmDelete(item),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: priceRed,
                                    shape: BoxShape.circle
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            item['title'] ?? "Sản phẩm",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: vkuBlue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${item['price']} VNĐ",
                          style: const TextStyle(color: priceRed, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_pin_circle_rounded, size: 14, color: marketAccent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item['fullname'] ?? "Ẩn danh",
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Xác nhận xóa?", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold)),
        content: Text("Bạn muốn gỡ '${item['title']}' khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(item['id'].toString());
            },
            style: ElevatedButton.styleFrom(backgroundColor: priceRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}