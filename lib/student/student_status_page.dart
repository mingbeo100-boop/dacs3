import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentStatusPage extends StatefulWidget {
  final dynamic user;
  const StudentStatusPage({super.key, required this.user});

  @override
  State<StudentStatusPage> createState() => _StudentStatusPageState();
}

class _StudentStatusPageState extends State<StudentStatusPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);

  bool isLoading = true;
  Map<String, dynamic> statusData = {};

  late String filterMonth;
  late String filterYear;

  final List<String> months = List.generate(12, (i) => "Tháng ${i + 1 < 10 ? '0' : ''}${i + 1}");
  final List<String> years = ["2024", "2025", "2026", "2027"];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    filterMonth = "Tháng ${now.month < 10 ? '0' : ''}${now.month}";
    filterYear = now.year.toString();
    if (!years.contains(filterYear)) filterYear = "2026";

    _loadMyStatus();
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    return value.toString() == "1" || value.toString().toLowerCase() == "true";
  }

  Future<void> _loadMyStatus() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      int monthNum = int.parse(filterMonth.replaceAll(RegExp(r'[^0-9]'), ''));

      final response = await http.get(Uri.parse(
          "http://10.60.56.48/dacs3/get_student_status.php?user_id=${widget.user['id']}&month=$monthNum&year=$filterYear"
      ));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            statusData = jsonDecode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi kết nối: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPaid = _parseBool(statusData['is_paid']);

    return Scaffold(
      backgroundColor: sandBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildMainStatusBanner(isPaid)),

          // --- HỆ KHUYẾN NGHỊ & NHẮC NHỞ ĐÓNG PHÍ ---
          SliverToBoxAdapter(child: _buildSmartRecommendation(isPaid)),

          SliverToBoxAdapter(child: _buildSectionHeader("CHỌN THỜI GIAN TRA CỨU")),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: _buildBigDropdown("Tháng", filterMonth, months, (v) {
                    setState(() => filterMonth = v!);
                    _loadMyStatus();
                  })),
                  const SizedBox(width: 15),
                  Expanded(child: _buildBigDropdown("Năm", filterYear, years, (v) {
                    setState(() => filterYear = v!);
                    _loadMyStatus();
                  })),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildSectionHeader("TÌNH TRẠNG CHUYÊN CẦN")),
          isLoading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: vkuBlue))))
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 1.3,
              ),
              delegate: SliverChildListDelegate([
                _buildWeekCard("Tuần 01", _parseBool(statusData['week1'])),
                _buildWeekCard("Tuần 02", _parseBool(statusData['week2'])),
                _buildWeekCard("Tuần 03", _parseBool(statusData['week3'])),
                _buildWeekCard("Tuần 04", _parseBool(statusData['week4'])),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // --- WIDGET HỆ KHUYẾN NGHỊ THÔNG MINH ---
  Widget _buildSmartRecommendation(bool isPaid) {
    if (isLoading) return const SizedBox();

    List<Widget> recs = [];

    // 1. Nhắc nhở đóng phí (Ưu tiên hàng đầu)
    if (!isPaid) {
      recs.add(_buildRecItem(
          Icons.priority_high_rounded,
          "NHẮC NHỞ HỌC PHÍ",
          "Bạn chưa hoàn thành học phí nội trú $filterMonth. Vui lòng thanh toán sớm để tránh bị khóa dịch vụ.",
          Colors.red
      ));
    }

    // 2. Nhắc nhở chuyên cần
    int vangCount = 0;
    if (!_parseBool(statusData['week1'])) vangCount++;
    if (!_parseBool(statusData['week2'])) vangCount++;
    if (!_parseBool(statusData['week3'])) vangCount++;
    if (!_parseBool(statusData['week4'])) vangCount++;

    if (vangCount >= 3) {
    recs.add(_buildRecItem(
    Icons.report_problem_rounded,
    "CẢNH BÁO CHUYÊN CẦN",
    "Bạn đã vắng mặt $vangCount buổi sinh hoạt. Nguy cơ bị kỷ luật rất cao, hãy chú ý hơn!",
    vkuOrange
    ));
    } else if (vangCount == 0 && isPaid) {
    recs.add(_buildRecItem(
    Icons.stars_rounded,
    "KHEN NGỢI",
    "Tuyệt vời! Bạn đang thực hiện rất tốt các quy định về học phí và chuyên cần.",
    Colors.green
    ));
    }

    if (recs.isEmpty) return const SizedBox();

    return Container(
    margin: const EdgeInsets.fromLTRB(25, 20, 25, 5),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
    ),
    child: Column(children: recs),
    );
  }

  Widget _buildRecItem(IconData icon, String title, String msg, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(msg, style: const TextStyle(color: vkuBlue, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGETS CƠ BẢN GIỮ NGUYÊN ---

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true, backgroundColor: vkuBlue, elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
      centerTitle: true,
      title: const Text("TRA CỨU NỘI TRÚ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Row(
        children: [
          Container(width: 6, height: 22, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildMainStatusBanner(bool isPaid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPaid
                ? [const Color(0xFF1B8F1C), const Color(0xFF28B544)]
                : [const Color(0xFF8E2424), Colors.red],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: (isPaid ? Colors.green : Colors.red).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Icon(isPaid ? Icons.check_circle_rounded : Icons.warning_rounded, color: Colors.white, size: 50),
            const SizedBox(height: 15),
            Text(isPaid ? "ĐÃ HOÀN THÀNH HỌC PHÍ" : "CHƯA THANH TOÁN", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text("$filterMonth / $filterYear", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBigDropdown(String title, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white, width: 2)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: cardBg,
          icon: const Icon(Icons.expand_more_rounded, color: vkuBlue),
          style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.bold, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildWeekCard(String title, bool done) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white, width: 2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 10),
          Icon(done ? Icons.verified_rounded : Icons.cancel_outlined, color: done ? Colors.green : Colors.grey[400], size: 30),
          const SizedBox(height: 10),
          Text(done ? "CÓ MẶT" : "VẮNG", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }
}