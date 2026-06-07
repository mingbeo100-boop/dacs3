import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để quét bảng kết quả gợi ý

class RecommendationResultPage extends StatefulWidget {
  final dynamic user; // Nhận toàn bộ thông tin tài khoản đang đăng nhập từ HomePage sang
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
    _fetchRecommendationsFromCloud();
  }

  // --- LOGIC MỚI: QUÉT TRỰC TIẾP KẾT QUẢ GỢI Ý TỪ CLOUD FIRESTORE ---
  Future<void> _fetchRecommendationsFromCloud() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Bốc mã sinh viên (username) của tài khoản đang đăng nhập để làm điều kiện lọc
      String currentMssv = widget.user['username'].toString().trim();

      // Truy vấn vào collection 'recommendations' tìm các bản ghi so khớp dành cho sinh viên này
      // Xếp những người có độ tương đồng (match_score) cao nhất lên đầu
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('recommendations')
          .where('user_host', isEqualTo: currentMssv)
          .orderBy('match_score', descending: true)
          .get()
          .timeout(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          recommendations = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi bốc dữ liệu AI gợi ý từ Firestore: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- HÀM HIỂN THỊ BẢNG THÔNG TIN NHỎ (DIALOG) GIỮ NGUYÊN ---
  void _showStudentDetail(dynamic data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: vkuBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              width: double.infinity,
              child: const Column(
                children: [
                  Icon(Icons.person_pin_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "THÔNG TIN SINH VIÊN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  _buildDetailRow(Icons.badge_outlined, "Họ tên:", data['fullname'] ?? "N/A"),
                  const Divider(height: 30, thickness: 1),
                  _buildDetailRow(Icons.meeting_room_outlined, "Phòng ở:", data['room_id'] ?? "Chưa rõ"),
                  const Divider(height: 30, thickness: 1),
                  _buildDetailRow(Icons.favorite_outline_rounded, "Tương đồng:", "${data['match_score']}%"),
                  const SizedBox(height: 30),
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
        onTap: () => _showStudentDetail(data),
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