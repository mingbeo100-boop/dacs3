import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import các trang chức năng đúng cấu trúc folder
import '../admin/admin_power_usage_page.dart';
import '../student/student_power_usage_page.dart';
import 'marketplace_page.dart';
import 'ticket_page.dart';
import 'virtual_device_page.dart';
import '../profile_page.dart';
import '../admin/admin_student_list_page.dart';
import '../student/student_status_page.dart';
import '../student/notification_page.dart';
import '../admin/admin_device_summary_page.dart';

class HomePage extends StatefulWidget {
  final dynamic user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Hệ màu đặc trưng VKU
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const darkText = Color(0xFF263238);

  late dynamic currentUser;
  String displayRoom = "Đang tải...";
  List<dynamic> ktxNewsList = [];
  bool isNewsLoading = true;
  int unreadCount = 0;

  // Quản lý trạng thái chuyển trang (Cố định BottomNav)
  int _selectedIndex = 0;
  // BIẾN LƯU THÔNG KÊ THỰC TẾ
  Map<String, dynamic> adminStats = {"devices": "0", "requests": "0", "residents": "0"};

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    displayRoom = currentUser['room_id']?.toString() ?? "Chưa rõ";
    _initData();
  }

  // --- LOGIC DỮ LIỆU ---
  Future<void> _initData() async {
    await _refreshUserData();
    await _loadAllNews();
    if (currentUser['role'] == 'admin') {
      await _loadAdminStats(); // Cập nhật số thực tế tại đây
    } else {
      await _checkPrivateNotifications();
    }
  }

  // SỬA CHỨC NĂNG: Gọi API thực tế
  Future<void> _loadAdminStats() async {
    try {
      // 1. Kiểm tra kỹ IP: Nếu chạy máy ảo Android thì dùng 10.0.2.2
      // Nếu chạy máy thật thì dùng IP 192.168.4.21 (đảm bảo máy tính và điện thoại cùng Wifi)
      final res = await http.get(Uri.parse("http://192.168.4.21/dacs3/get_admin_home_stats.php"))
          .timeout(const Duration(seconds: 5)); // Thêm timeout để tránh treo

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          // Gán giá trị và ép kiểu về String để hiển thị
          adminStats = {
            "devices": (data['devices'] ?? 0).toString(),
            "requests": (data['requests'] ?? 0).toString(),
            "residents": (data['residents'] ?? 0).toString(),
          };
        });
        print("Dữ liệu Admin Stats mới: $adminStats");
      }
    } catch (e) {
      print("Lỗi kết nối stats: $e");
    }
  }

  Future<void> _checkPrivateNotifications() async {
    if (currentUser['role'] == 'admin') return;
    try {
      final res = await http.get(Uri.parse("http://192.168.4.21/dacs3/manage_notifications.php?user_id=${currentUser['id']}"));
      if (res.statusCode == 200) setState(() => unreadCount = jsonDecode(res.body)['unread_count'] ?? 0);
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> _loadAllNews() async {
    if (!mounted) return;
    setState(() => isNewsLoading = true);
    try {
      final res = await http.get(Uri.parse("http://192.168.4.21/dacs3/manage_news.php?all=true"));
      if (res.statusCode == 200) setState(() { ktxNewsList = jsonDecode(res.body)['news_list'] ?? []; isNewsLoading = false; });
    } catch (e) { if (mounted) setState(() => isNewsLoading = false); }
  }

  Map<String, dynamic> _analyzeNotificationAI(String content) {
    String text = content.toLowerCase();
    final Map<String, Map<String, dynamic>> aiBrain = {
      'power': {'tags': ['điện', 'bolt', 'sét'], 'icon': Icons.bolt_rounded, 'color': Colors.amber.shade700, 'label': 'Điện năng'},
      'eco': {'tags': ['cây', 'xanh', 'môi trường'], 'icon': Icons.park_rounded, 'color': Colors.green.shade600, 'label': 'Môi trường'},
      'package': {'tags': ['bưu kiện', 'ship', 'hàng'], 'icon': Icons.inventory_2_outlined, 'color': vkuOrange, 'label': 'Bưu kiện'},
      'money': {'tags': ['tiền', 'phí', 'đóng'], 'icon': Icons.payments_outlined, 'color': Colors.teal.shade600, 'label': 'Tài chính'},
      'fix': {'tags': ['sửa', 'hỏng', 'bảo trì'], 'icon': Icons.build_circle_outlined, 'color': Colors.brown.shade600, 'label': 'Kỹ thuật'}
    };
    String bestMatch = 'default'; int maxScore = 0;
    aiBrain.forEach((key, value) {
      int currentScore = 0;
      for (var tag in value['tags']) { if (text.contains(tag)) currentScore++; }
      if (currentScore > maxScore) { maxScore = currentScore; bestMatch = key; }
    });
    return (bestMatch == 'default' || maxScore == 0) ? {'icon': Icons.campaign_rounded, 'color': vkuBlue, 'label': 'Thông báo'} : aiBrain[bestMatch]!;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      MarketplacePage(userId: currentUser['id'].toString(), role: currentUser['role']),
      ProfilePage(user: currentUser),
    ];

    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    String roomId = currentUser['room_id']?.toString() ?? displayRoom;
    String userId = currentUser['id']?.toString() ?? '0';
    String userRole = currentUser['role']?.toString() ?? 'student';

    return RefreshIndicator(
      onRefresh: _initData,
      color: vkuOrange,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(userRole, userId),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: _buildFeatureCard(
                title: userRole == 'admin' ? "QUẢN LÝ NỘI TRÚ" : "SỔ TAY NỘI TRÚ",
                subtitle: userRole == 'admin' ? "Hệ thống Admin VKU" : "Phòng hiện tại: $displayRoom",
                icon: userRole == 'admin' ? Icons.admin_panel_settings_rounded : Icons.assignment_ind_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => userRole == 'admin' ? const AdminStudentListPage() : StudentStatusPage(user: currentUser)
                )),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            sliver: SliverGrid.count(
              crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 1.05,
              children: [
                _buildServiceCard(context, "Thiết bị", Icons.sensors_rounded, Colors.red.shade700, VirtualDevicePage(roomId: roomId, roomName: roomId)),
                _buildServiceCard(context, "Điện năng", Icons.bolt_rounded, Colors.amber.shade700, userRole == 'admin' ? AdminPowerUsagePage(userRole: userRole) : StudentPowerUsagePage(user: currentUser)),
                _buildServiceCard(context, "Chợ KTX", Icons.local_mall_rounded, Colors.green.shade700, MarketplacePage(userId: userId, role: userRole)),
                _buildServiceCard(context, "Hỗ trợ", Icons.support_agent_rounded, Colors.brown.shade600, TicketPage(user: currentUser)),
              ],
            ),
          ),

          // --- 3 Ô THỐNG KÊ (DÙNG adminStats THỰC TẾ) ---
          if (userRole == 'admin')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 15, 25, 5),
                child: Row(
                  children: [
                    _buildStatCard(adminStats['devices'].toString(), "Thiết bị", Icons.auto_graph_rounded, vkuOrange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDeviceSummaryPage()))),
                    const SizedBox(width: 12),
                    _buildStatCard(adminStats['requests'].toString(), "Hỏng hóc", Icons.build_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (context) => TicketPage(user: currentUser)))),
                    const SizedBox(width: 12),
                    _buildStatCard(adminStats['residents'].toString(), "Cư dân", Icons.people_alt_rounded, vkuBlue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminStudentListPage()))),
                  ],
                ),
              ),
            ),

          _buildNewsTitleSection(),

          if (isNewsLoading)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: vkuOrange)))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) => _buildNewsCardAI(ktxNewsList[index], userRole), childCount: ktxNewsList.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, "Trang chủ"),
          _buildNavItem(1, Icons.local_mall_outlined, "Chợ KTX"),
          _buildNavItem(2, Icons.person_outline_rounded, "Hồ sơ"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? vkuOrange : vkuBlue, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? vkuOrange : vkuBlue, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((_) { _initData(); }),
        borderRadius: BorderRadius.circular(28),
        child: Container(
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 15))
            ])
        )
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(25), child: Container(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.05), blurRadius: 10)]), child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 8), Text(value, style: const TextStyle(color: vkuBlue, fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.bold))]))));
  }

  Widget _buildSliverHeader(String role, String userId) {
    return SliverToBoxAdapter(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Row(children: [
              GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: CircleAvatar(radius: 25, backgroundColor: cardBg, backgroundImage: (currentUser['avatar_url'] != null && currentUser['avatar_url'] != "") ? NetworkImage(currentUser['avatar_url']) : null, child: (currentUser['avatar_url'] == null || currentUser['avatar_url'] == "") ? const Icon(Icons.person_rounded, color: vkuBlue, size: 28) : null)
              ),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(role == 'admin' ? "Quản trị viên," : "Thành viên VKU,", style: const TextStyle(color: vkuBlue, fontSize: 13, fontWeight: FontWeight.w500)), Text(currentUser['fullname'], style: const TextStyle(color: vkuBlue, fontSize: 18, fontWeight: FontWeight.w900))])),
              Stack(clipBehavior: Clip.none, children: [_buildTopIconButton(role == 'admin' ? Icons.notifications_active_rounded : Icons.notifications_active_outlined, onTap: () { if (role == 'admin') { _showNotificationDialog(); } else { Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage(userId: userId))).then((_) => _checkPrivateNotifications()); } }), if (role != 'admin' && unreadCount > 0) Positioned(right: -2, top: -2, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), constraints: const BoxConstraints(minWidth: 20, minHeight: 20), child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center)))]),
            ])
        )
    );
  }

  Widget _buildNewsCardAI(dynamic news, String role) { final ai = _analyzeNotificationAI(news['content'] ?? ""); return Container(margin: const EdgeInsets.fromLTRB(25, 0, 25, 15), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (ai['color'] as Color).withOpacity(0.1), shape: BoxShape.circle), child: Icon(ai['icon'], color: ai['color'], size: 22)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(ai['label'], style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13)), if (role == 'admin') IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18), onPressed: () => _confirmDeleteNews(news['id']))]), const Text("Vừa cập nhật", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(news['content'], style: TextStyle(color: darkText.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500, height: 1.5))]))])); }
  Widget _buildNewsTitleSection() => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(25, 25, 25, 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 5, height: 20, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 12), const Text("TIN TỨC KTX", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 15))]), TextButton(onPressed: () {}, child: const Text("Tất cả", style: TextStyle(color: vkuOrange, fontWeight: FontWeight.bold, fontSize: 13)))])));
  void _confirmDeleteNews(dynamic newsId) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Xóa tin tức?"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")), TextButton(onPressed: () async { await http.delete(Uri.parse("http://192.168.4.21/dacs3/manage_news.php?id=$newsId")); Navigator.pop(context); _loadAllNews(); }, child: const Text("XÓA", style: TextStyle(color: Colors.red)))])); }
  void _showNotificationDialog() { TextEditingController newsController = TextEditingController(); showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), title: const Text("PHÁT TIN KTX MỚI", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900)), content: TextField(controller: newsController, maxLines: 4, decoration: InputDecoration(hintText: "Nhập nội dung...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vkuOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (newsController.text.trim().isEmpty) return; await http.post(Uri.parse("http://192.168.4.21/dacs3/manage_news.php"), body: {"content": newsController.text.trim()}); Navigator.pop(context); _loadAllNews(); }, child: const Text("GỬI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))], )); }
  Future<void> _refreshUserData() async { try { final res = await http.get(Uri.parse("http://192.168.4.21/dacs3/get_profile.php?user_id=${currentUser['id']}")); if (res.statusCode == 200) { final data = jsonDecode(res.body); setState(() { currentUser['fullname'] = data['fullname'] ?? currentUser['fullname']; currentUser['avatar_url'] = data['avatar_url']; displayRoom = (data['room_number'] ?? data['room_id'] ?? "Chưa rõ").toString(); }); } } catch (e) { debugPrint(e.toString()); } }
  Widget _buildTopIconButton(IconData icon, {VoidCallback? onTap}) { return Container(decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(15)), child: IconButton(onPressed: onTap, icon: Icon(icon, color: vkuBlue, size: 24))); }
  Widget _buildFeatureCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(28), child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: vkuBlue, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white, size: 26)), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)), Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)])), const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16)]))); }
}