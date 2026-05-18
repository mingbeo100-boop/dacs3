import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../maketplace/add_product_page.dart';
import '../maketplace/edit_product_page.dart';
import '../maketplace/product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  final String userId;
  final String role;

  const MarketplacePage({super.key, required this.userId, required this.role});

  static List<dynamic>? cachedProducts;

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<dynamic> products = MarketplacePage.cachedProducts ?? [];
  bool isLoading = MarketplacePage.cachedProducts == null;

  static const vkuBlue = Color(0xFF002266);
  static const vkuOrange = Color(0xFFFF8C00);
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

  Future<void> fetchProducts() async {
    if (products.isEmpty) setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse("http://10.60.56.48/dacs3/get_products.php"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> newList = [];

        if (decodedData is List) {
          newList = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          newList = decodedData['data'];
        }

        if (!mounted) return;

        // Chỉ setState nếu dữ liệu thực sự thay đổi để giữ 120 FPS
        if (newList.length != products.length || newList.toString() != products.toString()) {
          setState(() {
            products = newList;
            MarketplacePage.cachedProducts = products;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchProducts,
          color: vkuOrange,
          child: CustomScrollView(
            // Vật lý cuộn 120Hz
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 1500, // Tải trước các card ở dưới 1.5 màn hình
            slivers: [
              _buildSliverAppBar(),

              if (isLoading && products.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: vkuBlue)))
              else
                SliverPadding(
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
          ),
        ),
      ),
      floatingActionButton: isAdmin ? _buildFab() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              "CHỢ SINH VIÊN VKU",
              style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
            ),
            Positioned(
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: vkuBlue, size: 22),
                onPressed: fetchProducts,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedProductItem(dynamic item) {
    String imageUrl = "http://10.60.56.48/dacs3/uploads/${item['image_url']}";

    // RepaintBoundary: Cô lập pixel vẽ, chìa khóa của sự mượt mà
    return RepaintBoundary(
      child: InkWell(
        onTap: () async {
          bool? refresh = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => isAdmin ? EditProductPage(product: item) : ProductDetailPage(product: item)
            ),
          );
          if (refresh == true) fetchProducts();
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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    cacheWidth: 350, // Ép ảnh nhỏ lại trong RAM (Rất quan trọng)
                    filterQuality: FilterQuality.low, // Tăng tốc độ render khi cuộn
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
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
                        Expanded(child: Text(item['fullname'] ?? "Ẩn danh",
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
      onPressed: () async {
        bool? refresh = await Navigator.push(context, MaterialPageRoute(
          builder: (context) => AddProductPage(userId: widget.userId),
        ));
        if (refresh == true) fetchProducts();
      },
      child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
    );
  }
}