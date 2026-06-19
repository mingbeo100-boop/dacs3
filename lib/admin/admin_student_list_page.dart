import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để quản lý cư dân Realtime
import '../student/student_detail_admin_page.dart'; // Giữ duy nhất một dòng import chuẩn trong cùng thư mục admin
import '../widgets/app_avatar.dart'; // ĐÃ KẾT NỐI: Import widget dùng chung xử lý ảnh an toàn

class AdminStudentListPage extends StatefulWidget {
  const AdminStudentListPage({super.key});

  @override
  State<AdminStudentListPage> createState() => _AdminStudentListPageState();
}

class _AdminStudentListPageState extends State<AdminStudentListPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const darkText = Color(0xFF263238);

  String searchQuery = "";
  String statusFilter = "Tất cả";
  String selectedDay = "Tất cả Dãy";
  String selectedTang = "Tất cả Tầng";

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
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    return value == true || value.toString() == "1" || value.toString().toLowerCase() == "true";
  }

  @override
  Widget build(BuildContext context) {
    // STREAM 1: LẮNG NGHE TOÀN BỘ CƯ DÂN CÓ ROLE LÀ STUDENT TRÊN FIRESTORE Realtime
    final Stream<QuerySnapshot> _studentsStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots();

    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _studentsStream,
          builder: (context, studentSnapshot) {
            if (studentSnapshot.hasError) {
              return const Center(child: Text("Lỗi kết nối hệ thống dữ liệu cư dân mây."));
            }
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: vkuOrange));
            }

            // Chuyển đổi dữ liệu thô từ các Document sang List Map
            List<dynamic> allStudents = studentSnapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['student_code'] = data['username'] ?? "SV-VKU";
              return data;
            }).toList();

            // STREAM 2: TẢI REALTIME TOÀN BỘ BẢNG PROFILES VÀO BỘ NHỚ ĐỆM ĐỂ LẤY AVATAR
            return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('profiles').snapshots(),
                builder: (context, profileSnapshot) {
                  Map<String, String> avatarCacheMap = {};
                  if (profileSnapshot.hasData) {
                    for (var doc in profileSnapshot.data!.docs) {
                      var pData = doc.data() as Map<String, dynamic>;
                      String? uId = pData['user_id']?.toString();
                      String? avUrl = pData['avatar_url']?.toString();
                      if (uId != null && avUrl != null) {
                        avatarCacheMap[uId] = avUrl;
                      }
                    }
                  }

                  // STREAM 3: TỐI ƯU SIÊU TỐC - LẮNG NGHE REALTIME TRẠNG THÁI HỌC PHÍ THEO THÁNG/NĂM ĐANG CHỌN
                  return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('room_statuses')
                          .where('month', isEqualTo: filterMonth)
                          .where('year', isEqualTo: filterYear)
                          .snapshots(),
                      builder: (context, statusSnapshot) {
                        // Cấu trúc bộ nhớ đệm trạng thái học phí: { username/MSSV : is_paid_bool }
                        Map<String, bool> statusCacheMap = {};
                        if (statusSnapshot.hasData) {
                          for (var doc in statusSnapshot.data!.docs) {
                            var sData = doc.data() as Map<String, dynamic>;
                            String? mssv = sData['username']?.toString();
                            bool isPaid = sData['is_paid'] == true || sData['is_paid'].toString() == "1";
                            if (mssv != null) {
                              statusCacheMap[mssv] = isPaid;
                            }
                          }
                        }

                        // BỘ LỌC CHI TIẾT XỬ LÝ TRỰC TIẾP TRÊN MẢNG Ở TRẠNG THÁI REALTIME QUA RAM
                        final filteredStudents = allStudents.where((s) {
                          final mssvKey = s['username']?.toString() ?? "";
                          final name = (s['fullname'] ?? "").toString().toLowerCase();
                          final code = (s['student_code'] ?? "").toString().toLowerCase();
                          final query = searchQuery.toLowerCase();
                          bool matchesSearch = name.contains(query) || code.contains(query);

                          // Lấy trạng thái đóng tiền thực tế của tháng này từ bảng room_statuses thông qua Map Cache
                          bool isPaidInMonth = statusCacheMap[mssvKey] ?? false;

                          bool matchesStatus = true;
                          if (statusFilter == "Đã đóng tiền") matchesStatus = isPaidInMonth;
                          if (statusFilter == "Chưa đóng tiền") matchesStatus = !isPaidInMonth;

                          String roomIdFull = (s['room_id'] ?? "").toString();
                          List<String> parts = roomIdFull.split('_');
                          bool matchesDay = (selectedDay == "Tất cả Dãy") || (parts.isNotEmpty && parts[0] == selectedDay);
                          bool matchesTang = (selectedTang == "Tất cả Tầng") || (parts.length > 1 && parts[1].substring(0, 1) == selectedTang);

                          return matchesSearch && matchesStatus && matchesDay && matchesTang;
                        }).toList();

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            _buildSliverHeader(),
                            SliverToBoxAdapter(child: _buildMainStatCard(filteredStudents.length)),
                            SliverToBoxAdapter(child: _buildSectionHeader("BỘ LỌC TÌM KIẾM")),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                                child: Column(
                                  children: [
                                    _buildSearchField(),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        _buildStatusChip("Tất cả"),
                                        const SizedBox(width: 12),
                                        _buildStatusChip("Chưa đóng"),
                                        const SizedBox(width: 12),
                                        _buildStatusChip("Đã đóng"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(child: _buildSectionHeader("DANH SÁCH SINH VIÊN")),

                            filteredStudents.isEmpty
                                ? const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: Text("Không tìm thấy sinh viên nào phù hợp.", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold, fontSize: 13))),
                            )
                                : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(25, 10, 25, 100),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildStudentCard(filteredStudents[index], avatarCacheMap, statusCacheMap),
                                  childCount: filteredStudents.length,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                  );
                }
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        children: [
          Container(width: 6, height: 24, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: vkuBlue, size: 22)
            ),
            const Text("QUẢN LÝ NỘI TRÚ", style: TextStyle(color: vkuBlue, fontSize: 18, fontWeight: FontWeight.w900)),
            const Icon(Icons.group_add_rounded, color: vkuOrange, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatCard(int filteredCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: vkuBlue,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TỔNG SINH VIÊN", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text("$filteredCount sinh viên", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 40, thickness: 1.5),
            Row(
              children: [
                Expanded(child: _buildBigDropdown("Tháng", filterMonth, months, (v) => setState(() => filterMonth = v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildBigDropdown("Năm", filterYear, years, (v) => setState(() => filterYear = v!))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildBigDropdown("Dãy", selectedDay, ["Tất cả Dãy", "1", "2", "3"], (v) => setState(() => selectedDay = v!))),
                const SizedBox(width: 8),
                Expanded(child: _buildBigDropdown("Tầng", selectedTang, ["Tất cả Tầng", "1", "2", "3", "4"], (v) => setState(() => selectedTang = v!))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigDropdown(String title, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: vkuBlue,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.white, size: 20),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: TextField(
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: InputDecoration(
          hintText: "Tìm tên, phòng, mã số...",
          hintStyle: TextStyle(color: vkuBlue.withOpacity(0.3), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: vkuBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    String val = label == "Chưa đóng" ? "Chưa đóng tiền" : (label == "Đã đóng" ? "Đã đóng tiền" : "Tất cả");
    bool isSel = statusFilter == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => statusFilter = val),
        child: Container(
          height: 52,
          decoration: BoxDecoration(color: isSel ? vkuOrange : cardBg, borderRadius: BorderRadius.circular(15), border: isSel ? null : Border.all(color: Colors.white, width: 2)),
          child: Center(child: Text(label, style: TextStyle(color: isSel ? Colors.white : vkuBlue.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 13))),
        ),
      ),
    );
  }

  // --- ĐÃ TỐI ƯU SIÊU TỐC: Nhận cả avatar cache và status cache để vẽ giao diện tức thời bằng RAM ---
  Widget _buildStudentCard(dynamic student, Map<String, String> avatarCache, Map<String, bool> statusCache) {
    String mssv = student['username']?.toString() ?? "";
    String currentUserId = student['user_id']?.toString() ?? student['id']?.toString() ?? mssv;

    // Trích xuất trực tiếp ảnh và trạng thái đóng tiền từ RAM O(1)
    String? cachedAvatarUrl = avatarCache[currentUserId];
    bool isPaidInMonth = statusCache[mssv] ?? false;

    return InkWell(
      onTap: () {
        Map<String, dynamic> studentData = Map<String, dynamic>.from(student);
        studentData['avatar_url'] = cachedAvatarUrl;
        // Đè luôn trạng thái đóng tiền của tháng được chọn vào object truyền đi
        studentData['is_paid'] = isPaidInMonth;

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => StudentDetailAdminPage(student: studentData)
            )
        );
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Row(
          children: [
            AppAvatar(
              avatarUrl: cachedAvatarUrl,
              radius: 30,
              fallbackIconColor: vkuBlue,
              backgroundColor: sandBg,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(student['fullname'] ?? "N/A", style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16)),
                Text("Phòng ${student['room_id'] ?? 'Chưa xếp'} • ${student['student_code']}", style: TextStyle(color: darkText.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
            Icon(isPaidInMonth ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: isPaidInMonth ? Colors.green : Colors.redAccent, size: 28),
          ],
        ),
      ),
    );
  }
}