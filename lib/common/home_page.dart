import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
import 'forum_page.dart';

class HomePage extends StatefulWidget {
  final dynamic user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  int _selectedIndex = 0;

  late PageController _pageController;
  Map<String, dynamic> adminStats = {"devices": "0", "requests": "0", "residents": "0"};
  final Map<String, Map<String, dynamic>> _newsAiCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    currentUser = widget.user;
    displayRoom = currentUser['room_id']?.toString() ?? "Chưa rõ";
    _initData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (!mounted) return;
    await Future.wait([
      _refreshUserData(),
      _loadAllNews(),
      if (currentUser['role'] == 'admin') _loadAdminStats() else _checkPrivateNotifications(),
    ]);
  }

  Map<String, dynamic> _analyzeNotificationAI(String content) {
    if (_newsAiCache.containsKey(content)) return _newsAiCache[content]!;
    String text = content.toLowerCase();
    final Map<String, Map<String, dynamic>> aiBrain = {
      'power': {'tags': ['điện', 'số điện'], 'icon': Icons.bolt_rounded, 'color': Colors.amber.shade700, 'label': 'Điện năng'},
      'money': {'tags': ['tiền', 'phí', 'đóng'], 'icon': Icons.payments_outlined, 'color': Colors.teal.shade600, 'label': 'Tài chính'},
    };
    Map<String, dynamic> result = {'icon': Icons.campaign_rounded, 'color': vkuBlue, 'label': 'Thông báo'};
    for (var entry in aiBrain.values) {
      if (entry['tags'].any((tag) => text.contains(tag))) { result = entry; break; }
    }
    _newsAiCache[content] = result;
    return result;
  }

  // --- API HANDLERS (IP 1.21) ---
  Future<void> _loadAdminStats() async {
    try {
      final res = await http.get(Uri.parse("http://10.60.56.48/dacs3/get_admin_home_stats.php")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() { adminStats = {"devices": (data['devices'] ?? 0).toString(), "requests": (data['requests'] ?? 0).toString(), "residents": (data['residents'] ?? 0).toString()}; });
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> _checkPrivateNotifications() async {
    try {
      final res = await http.get(Uri.parse("http://10.60.56.48/dacs3/manage_notifications.php?user_id=${currentUser['id']}"));
      if (res.statusCode == 200 && mounted) setState(() => unreadCount = jsonDecode(res.body)['unread_count'] ?? 0);
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> _loadAllNews() async {
    try {
      final res = await http.get(Uri.parse("http://10.60.56.48/dacs3/manage_news.php?all=true"));
      if (res.statusCode == 200 && mounted) setState(() { ktxNewsList = jsonDecode(res.body)['news_list'] ?? []; isNewsLoading = false; });
    } catch (e) { if (mounted) setState(() => isNewsLoading = false); }
  }

  Future<void> _refreshUserData() async {
    try {
      final res = await http.get(Uri.parse("http://10.60.56.48/dacs3/get_profile.php?user_id=${currentUser['id']}"));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() { currentUser['fullname'] = data['fullname'] ?? currentUser['fullname']; currentUser['avatar_url'] = data['avatar_url']; displayRoom = (data['room_number'] ?? data['room_id'] ?? "Chưa rõ").toString(); });
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            _buildHomeContent(),
            MarketplacePage(userId: currentUser['id'].toString(), role: currentUser['role']),
            ProfilePage(user: currentUser),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    String roomId = currentUser['room_id']?.toString() ?? displayRoom;
    String userRole = currentUser['role']?.toString() ?? 'student';

    return RefreshIndicator(
      onRefresh: _initData,
      color: vkuOrange,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 1000,
        slivers: [
          _buildSliverHeader(userRole, currentUser['id'].toString()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: RepaintBoundary(
                child: _buildFeatureCard(
                  title: userRole == 'admin' ? "QUẢN LÝ NỘI TRÚ" : "SỔ TAY NỘI TRÚ",
                  subtitle: userRole == 'admin' ? "Hệ thống Admin VKU" : "Phòng hiện tại: $displayRoom",
                  icon: userRole == 'admin' ? Icons.admin_panel_settings_rounded : Icons.assignment_ind_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => userRole == 'admin' ? const AdminStudentListPage() : StudentStatusPage(user: currentUser))),
                ),
              ),
            ),
          ),

          // --- LƯỚI 4 Ô DỊCH VỤ CÂN ĐỐI ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            sliver: SliverGrid.count(
              crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 1.05,
              children: [
                _buildServiceCard("Diễn đàn", Icons.groups_rounded, Colors.purple.shade700, ForumPage(user: currentUser)),
                _buildServiceCard("Thiết bị", Icons.sensors_rounded, Colors.red.shade700, VirtualDevicePage(roomId: roomId, roomName: roomId)),
                _buildServiceCard("Điện năng", Icons.bolt_rounded, Colors.amber.shade700, userRole == 'admin' ? AdminPowerUsagePage(userRole: userRole) : StudentPowerUsagePage(user: currentUser)),
                _buildServiceCard("Hỗ trợ", Icons.support_agent_rounded, Colors.brown.shade600, TicketPage(user: currentUser)),
              ],
            ),
          ),

          if (userRole == 'admin')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 15, 25, 5),
                child: Row(children: [
                  _buildStatCard(adminStats['devices'].toString(), "Thiết bị", Icons.auto_graph_rounded, vkuOrange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDeviceSummaryPage()))),
                  const SizedBox(width: 12),
                  _buildStatCard(adminStats['requests'].toString(), "Hỏng hóc", Icons.build_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (context) => TicketPage(user: currentUser)))),
                  const SizedBox(width: 12),
                  _buildStatCard(adminStats['residents'].toString(), "Cư dân", Icons.people_alt_rounded, vkuBlue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminStudentListPage()))),
                ]),
              ),
            ),
          _buildNewsTitleSection(),
          if (isNewsLoading)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: vkuOrange)))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildNewsCardAI(ktxNewsList[index], userRole),
                childCount: ktxNewsList.length,
                addRepaintBoundaries: true,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- WIDGETS TỐI ƯU ---

  Widget _buildSliverHeader(String role, String userId) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
        child: Row(children: [
          GestureDetector(
            onTap: () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: cardBg,
              backgroundImage: (currentUser['avatar_url'] != null && currentUser['avatar_url'] != "") ? NetworkImage(currentUser['avatar_url']) : null,
              child: (currentUser['avatar_url'] == null || currentUser['avatar_url'] == "") ? const Icon(Icons.person_rounded, color: vkuBlue, size: 28) : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(role == 'admin' ? "Quản trị viên," : "Thành viên VKU,", style: const TextStyle(color: vkuBlue, fontSize: 12, fontWeight: FontWeight.w500)),
            Text(currentUser['fullname'], style: const TextStyle(color: vkuBlue, fontSize: 17, fontWeight: FontWeight.w900)),
          ])),
          _buildTopIconButton(role == 'admin' ? Icons.notifications_active_rounded : Icons.notifications_active_outlined, () {
            if (role == 'admin') { _showNotificationDialog(); }
            else { Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage(userId: userId))); }
          }),
        ]),
      ),
    );
  }

  Widget _buildFeatureCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: vkuBlue,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
        ]),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, dynamic target) {
    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (target is int) {
            _pageController.animateToPage(target, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => target));
          }
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14))
          ]),
        ),
      ),
    );
  }

  Widget _buildNewsCardAI(dynamic news, String role) {
    final ai = _analyzeNotificationAI(news['content'] ?? "");
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (ai['color'] as Color).withOpacity(0.1), shape: BoxShape.circle), child: Icon(ai['icon'], color: ai['color'], size: 20)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ai['label'], style: TextStyle(color: ai['color'], fontWeight: FontWeight.w900, fontSize: 12)),
            if (role == 'admin') IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18), onPressed: () => _confirmDeleteNews(news['id'])),
          ]),
          const SizedBox(height: 5),
          Text(news['content'], style: TextStyle(color: darkText.withOpacity(0.7), fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
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
      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? vkuOrange.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? vkuOrange : vkuBlue, size: 26),
            const SizedBox(height: 4),
            if (isSelected)
              Text(label, style: const TextStyle(color: vkuOrange, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, VoidCallback onTap) => Container(decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(15)), child: IconButton(onPressed: onTap, icon: Icon(icon, color: vkuBlue, size: 22)));
  Widget _buildStatCard(String v, String l, IconData i, Color c, VoidCallback t) => Expanded(child: InkWell(onTap: t, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(i, color: c, size: 20), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(l, style: const TextStyle(fontSize: 8))]))));
  Widget _buildNewsTitleSection() => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(25, 20, 25, 10), child: Row(children: [Container(width: 5, height: 18, color: vkuOrange), const SizedBox(width: 10), const Text("TIN TỨC KTX", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))])));
  void _confirmDeleteNews(dynamic id) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Xóa tin tức?"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")), TextButton(onPressed: () async { await http.delete(Uri.parse("http://10.60.56.48/dacs3/manage_news.php?id=$id")); Navigator.pop(context); _loadAllNews(); }, child: const Text("XÓA", style: TextStyle(color: Colors.red)))])); }
  void _showNotificationDialog() { TextEditingController ctrl = TextEditingController(); showDialog(context: context, builder: (context) => AlertDialog(title: const Text("PHÁT TIN MỚI"), content: TextField(controller: ctrl, maxLines: 3), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")), ElevatedButton(onPressed: () async { if(ctrl.text.isEmpty) return; await http.post(Uri.parse("http://10.60.56.48/dacs3/manage_news.php"), body: {"content": ctrl.text}); Navigator.pop(context); _loadAllNews(); }, child: const Text("GỬI"))])); }
}