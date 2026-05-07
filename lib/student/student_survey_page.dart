import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentSurveyPage extends StatefulWidget {
  final dynamic user;
  const StudentSurveyPage({super.key, required this.user});

  @override
  State<StudentSurveyPage> createState() => _StudentSurveyPageState();
}

class _StudentSurveyPageState extends State<StudentSurveyPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);

  bool isSubmitting = false;

  // Khởi tạo đầy đủ các cột theo bảng SQL của ông để tránh NULL
  Map<String, int> preferences = {
    "sleep_time": 2,     // 1: Sớm, 2: Vừa, 3: Khuya
    "wakeup_time": 2,    // 1: Sớm, 2: Vừa, 3: Muộn
    "study_habit": 2,    // 1: Yên tĩnh, 2: Nhạc, 3: Nhóm
    "tech_stack": 1,     // 1: Web/Mobile, 2: AI/Data, 3: Network
    "cleanliness": 2,    // 1: Kỹ, 2: Vừa, 3: Tự do
    "smoking": 0,        // 0: Không, 1: Có
    "gaming_level": 1,   // 0: Không, 1: Ít, 2: Nhiều
    "music_volume": 1,   // 1: Tai nghe, 2: Vừa, 3: Loa ngoài
    "social_index": 2,   // 1: Hướng nội, 2: Vừa, 3: Hướng ngoại
  };

  Future<void> _submitSurvey() async {
    setState(() => isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.4.21/dacs3/save_preferences.php"),
        body: {
          "user_id": widget.user['id'].toString(),
          "sleep_time": preferences["sleep_time"].toString(),
          "wakeup_time": preferences["wakeup_time"].toString(),
          "study_habit": preferences["study_habit"].toString(),
          "tech_stack": preferences["tech_stack"].toString(),
          "cleanliness": preferences["cleanliness"].toString(),
          "smoking": preferences["smoking"].toString(),
          "gaming_level": preferences["gaming_level"].toString(),
          "music_volume": preferences["music_volume"].toString(),
          "social_index": preferences["social_index"].toString(),
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã cập nhật hồ sơ thói quen!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Lỗi gửi khảo sát: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
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

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // NHÓM 1: GIỜ GIẤC
                _buildSectionHeader("THỜI GIAN BIỂU"),
                _buildChoiceGroup("Bạn thường đi ngủ lúc mấy giờ?", "sleep_time", [
                  {"val": 1, "label": "Ngủ sớm", "icon": Icons.wb_sunny_outlined},
                  {"val": 2, "label": "Điều độ", "icon": Icons.bedtime_outlined},
                  {"val": 3, "label": "Cú đêm", "icon": Icons.nights_stay_outlined},
                ]),
                _buildChoiceGroup("Bạn thường thức dậy lúc nào?", "wakeup_time", [
                  {"val": 1, "label": "Dậy sớm", "icon": Icons.wb_twilight_rounded},
                  {"val": 2, "label": "Bình thường", "icon": Icons.sunny},
                  {"val": 3, "label": "Dậy muộn", "icon": Icons.alarm_off_rounded},
                ]),

                // NHÓM 2: HỌC TẬP & CÔNG NGHỆ (Đặc trưng VKU)
                _buildSectionHeader("HỌC THUẬT & CÔNG NGHỆ"),
                _buildChoiceGroup("Phong cách học tập", "study_habit", [
                  {"val": 1, "label": "Yên tĩnh", "icon": Icons.volume_off},
                  {"val": 2, "label": "Nghe nhạc", "icon": Icons.headset},
                  {"val": 3, "label": "Học nhóm", "icon": Icons.forum},
                ]),
                _buildChoiceGroup("Chuyên ngành quan tâm", "tech_stack", [
                  {"val": 1, "label": "Web/App", "icon": Icons.code},
                  {"val": 2, "label": "AI/Data", "icon": Icons.analytics},
                  {"val": 3, "label": "Network", "icon": Icons.lan},
                ]),

                // NHÓM 3: Ý THỨC CHUNG
                _buildSectionHeader("Ý THỨC & VỆ SINH"),
                _buildChoiceGroup("Mức độ ngăn nắp", "cleanliness", [
                  {"val": 1, "label": "Kỹ tính", "icon": Icons.cleaning_services},
                  {"val": 2, "label": "Gọn gàng", "icon": Icons.grid_view},
                  {"val": 3, "label": "Tự do", "icon": Icons.weekend},
                ]),
                _buildChoiceGroup("Vấn đề hút thuốc", "smoking", [
                  {"val": 0, "label": "Không hút", "icon": Icons.smoke_free},
                  {"val": 1, "label": "Có hút", "icon": Icons.smoking_rooms},
                ]),

                // NHÓM 4: GIẢI TRÍ
                _buildSectionHeader("GIẢI TRÍ & XÃ HỘI"),
                _buildChoiceGroup("Chơi Game", "gaming_level", [
                  {"val": 0, "label": "Không chơi", "icon": Icons.videogame_asset_off},
                  {"val": 1, "label": "Giải trí", "icon": Icons.sports_esports},
                  {"val": 2, "label": "Try-hard", "icon": Icons.bolt},
                ]),
                _buildChoiceGroup("Âm lượng âm nhạc", "music_volume", [
                  {"val": 1, "label": "Tai nghe", "icon": Icons.headphones},
                  {"val": 2, "label": "Vừa đủ", "icon": Icons.volume_down},
                  {"val": 3, "label": "Loa ngoài", "icon": Icons.volume_up},
                ]),
                _buildChoiceGroup("Khả năng giao tiếp", "social_index", [
                  {"val": 1, "label": "Ít nói", "icon": Icons.person_outline},
                  {"val": 2, "label": "Hòa đồng", "icon": Icons.emoji_people},
                  {"val": 3, "label": "Năng nổ", "icon": Icons.celebration},
                ]),

                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS (GIỮ NGUYÊN STYLE SỔ TAY NỘI TRÚ) ---
  Widget _buildSliverAppBar() => SliverAppBar(
    pinned: true, backgroundColor: vkuBlue, elevation: 0,
    leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
    centerTitle: true,
    title: const Text("KHẢO SÁT THÓI QUEN", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
  );

  Widget _buildHeaderBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [vkuBlue, Color(0xFF1A4594)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        const Icon(Icons.auto_awesome_mosaic_rounded, color: vkuOrange, size: 50),
        const SizedBox(height: 15),
        const Text("ĐỊNH HÌNH CÁ TÍNH", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Dữ liệu này là cơ sở để AI sắp xếp bạn vào môi trường lý tưởng nhất.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.5)),
      ]),
    ),
  );

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 30, 0, 15),
    child: Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13)),
    ]),
  );

  Widget _buildChoiceGroup(String title, String key, List<Map<String, dynamic>> options) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(left: 5, bottom: 12), child: Text(title, style: TextStyle(color: vkuBlue.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 11))),
      Row(children: options.map((opt) {
        bool isSelected = preferences[key] == opt['val'];
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => preferences[key] = opt['val']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isSelected ? vkuOrange : cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isSelected ? vkuOrange : Colors.white, width: 2),
              boxShadow: [if (isSelected) BoxShadow(color: vkuOrange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              Icon(opt['icon'], color: isSelected ? Colors.white : vkuBlue, size: 28),
              const SizedBox(height: 10),
              Text(opt['label'], textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : vkuBlue, fontWeight: FontWeight.w900, fontSize: 9)),
            ]),
          ),
        ));
      }).toList()),
      const SizedBox(height: 15),
    ],
  );

  Widget _buildSubmitButton() => Container(
    width: double.infinity, height: 65,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
    child: ElevatedButton(
      onPressed: isSubmitting ? null : _submitSurvey,
      style: ElevatedButton.styleFrom(backgroundColor: vkuBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      child: isSubmitting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : const Text("HOÀN TẤT VÀ LƯU HỒ SƠ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 14)),
    ),
  );
}