import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationResultPage extends StatefulWidget {
  final dynamic user;
  const RecommendationResultPage({super.key, required this.user});

  @override
  State<RecommendationResultPage> createState() => _RecommendationResultPageState();
}

class _RecommendationResultPageState extends State<RecommendationResultPage> {
  // --- HỆ MÀU SMART DORM ---
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);

  List<dynamic> recommendations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  // --- LẤY DỮ LIỆU TỪ BACKEND ---
  Future<void> _fetchRecommendations() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          "http://192.168.1.191/dacs3/get_recommendations.php?user_id=${widget.user['id']}"
      ));
      if (response.statusCode == 200) {
        setState(() {
          recommendations = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi gợi ý: $e");
      setState(() => isLoading = false);
    }
  }

  // --- HÀM HIỂN THỊ BẢNG THÔNG TIN NHỎ (DIALOG) - ĐÃ CẬP NHẬT GIAO DIỆN ---
  void _showStudentDetail(dynamic data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: EdgeInsets.zero, // Làm sạch Padding mặc định
        content: Column(
          mainAxisSize: MainAxisSize.min, // Bo gọn theo nội dung
          children: [
            // 1. HEADER DIALOG MỚI: CHỮ NẰM TRÊN NỀN XANH
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: vkuBlue, // Nền xanh VKU
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Bo góc trên
              ),
              width: double.infinity,
              child: const Column(
                children: [
                  Icon(Icons.person_pin_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "THÔNG TIN SINH VIÊN",
                    style: TextStyle(
                      color: Colors.white, // Chữ trắng nổi bật
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // 2. PHẦN NỘI DUNG THÔNG TIN
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  // Dòng 1: Họ tên
                  _buildDetailRow(Icons.badge_outlined, "Họ tên:", data['fullname'] ?? "N/A"),
                  const Divider(height: 30, thickness: 1), // Vạch phân chia gọn gàng

                  // Dòng 2: PHÒNG HIỆN TẠI (Nhớ sửa PHP để lấy được cái này nhé Long)
                  _buildDetailRow(Icons.meeting_room_outlined, "Phòng ở:", data['room_id'] ?? "Chưa rõ"),
                  const Divider(height: 30, thickness: 1),

                  // Dòng 3: Độ tương đồng
                  _buildDetailRow(Icons.favorite_outline_rounded, "Tương đồng:", "${data['match_score']}%"),

                  const SizedBox(height: 30),

                  // Nút XÁC NHẬN bo góc
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: vkuOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          shadowColor: vkuOrange.withOpacity(0.3)
                      ),
                      child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget phụ để tạo dòng thông tin gọn gàng
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: vkuOrange, size: 22),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildHeaderBanner()),

          isLoading
              ? const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: vkuOrange))))
              : recommendations.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMatchCard(recommendations[index]),
                childCount: recommendations.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true, backgroundColor: vkuBlue, elevation: 0,
      leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)
      ),
      centerTitle: true,
      title: const Text("KẾT QUẢ GỢI Ý", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
    );
  }

  Widget _buildHeaderBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [vkuBlue, Color(0xFF1A4594)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: const Column(children: [
          Icon(Icons.hub_rounded, color: vkuOrange, size: 45),
          SizedBox(height: 12),
          Text("ĐỘ TƯƠNG ĐỒNG LỐI SỐNG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          SizedBox(height: 5),
          Text("AI phân tích thói quen của bạn và các sinh viên khác tại VKU.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _buildMatchCard(dynamic data) {
    double score = double.tryParse(data['match_score'].toString()) ?? 0.0;
    String avatarUrl = data['avatar']?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        onTap: () => _showStudentDetail(data), // NHẤN ĐỂ HIỆN BẢNG THÔNG TIN MỚI
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: vkuBlue.withOpacity(0.1),
                backgroundImage: (avatarUrl.isNotEmpty && avatarUrl.startsWith("http"))
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl.isEmpty || !avatarUrl.startsWith("http"))
                    ? const Icon(Icons.person_rounded, color: vkuBlue, size: 30)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['fullname'] ?? "Ẩn danh", style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(data['student_code'] ?? "SV-VKU", style: TextStyle(color: vkuBlue.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text("${score.toInt()}%", style: const TextStyle(color: vkuOrange, fontWeight: FontWeight.w900, fontSize: 18)),
                  const Text("PHÙ HỢP", style: TextStyle(color: vkuOrange, fontWeight: FontWeight.bold, fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(children: [
        Icon(Icons.sentiment_dissatisfied_rounded, size: 80, color: vkuBlue.withOpacity(0.2)),
        const SizedBox(height: 20),
        const Text("CHƯA CÓ KẾT QUẢ", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 10),
        const Text("AI chưa tìm thấy sinh viên có thói quen tương đồng. Hãy thử cập nhật lại khảo sát nhé!",
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}