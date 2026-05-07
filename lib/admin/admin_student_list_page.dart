  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import '../student/student_detail_admin_page.dart';

  class AdminStudentListPage extends StatefulWidget {
    const AdminStudentListPage({super.key});

    @override
    State<AdminStudentListPage> createState() => _AdminStudentListPageState();
  }

  class _AdminStudentListPageState extends State<AdminStudentListPage> {
    // Hệ màu thương hiệu VKU
    static const vkuBlue = Color(0xFF072C6C);
    static const vkuOrange = Color(0xFFFF8C00);
    static const sandBg = Color(0xFFF5E1C5);
    static const cardBg = Color(0xFFFFF8F0);
    static const darkText = Color(0xFF263238);

    List<dynamic> students = [];
    bool isLoading = true;

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
      _loadAllStudents();
    }

    Future<void> _loadAllStudents() async {
      setState(() => isLoading = true);
      try {
        int monthNum = int.parse(filterMonth.replaceAll(RegExp(r'[^0-9]'), ''));
        // LƯU Ý: Kiểm tra lại IP máy tính chạy XAMPP của ông
        final response = await http.get(Uri.parse(
            "http://192.168.4.21/dacs3/get_all_students.php?month=$monthNum&year=$filterYear"
        ));

        if (response.statusCode == 200) {
          setState(() {
            students = jsonDecode(response.body);
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        debugPrint("Lỗi kết nối server: $e");
        setState(() => isLoading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      // Logic lọc danh sách sinh viên
      List<dynamic> filteredStudents = students.where((s) {
        bool matchesSearch = (s['fullname'] ?? "").toLowerCase().contains(searchQuery.toLowerCase()) ||
            (s['student_code'] ?? "").toLowerCase().contains(searchQuery.toLowerCase());

        bool matchesStatus = true;
        var isPaidVal = s['is_paid'];
        if (statusFilter == "Đã đóng tiền") matchesStatus = (isPaidVal == 1 || isPaidVal == "1");
        if (statusFilter == "Chưa đóng tiền") matchesStatus = (isPaidVal == 0 || isPaidVal == "0" || isPaidVal == null);

        String roomIdFull = (s['room_id'] ?? "").toString();
        List<String> parts = roomIdFull.split('_');
        bool matchesDay = (selectedDay == "Tất cả Dãy") || (parts.isNotEmpty && parts[0] == selectedDay);
        bool matchesTang = (selectedTang == "Tất cả Tầng") || (parts.length > 1 && parts[1].substring(0, 1) == selectedTang);

        return matchesSearch && matchesStatus && matchesDay && matchesTang;
      }).toList();

      return Scaffold(
        backgroundColor: sandBg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header App
              _buildSliverHeader(),

              // 2. Card Thống kê & Dropdowns chọn thời gian/vị trí
              SliverToBoxAdapter(child: _buildMainStatCard(filteredStudents.length)),

              // 3. Tiêu đề Bộ lọc & Thanh tìm kiếm
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

              // 4. Tiêu đề danh sách
              SliverToBoxAdapter(child: _buildSectionHeader("DANH SÁCH SINH VIÊN")),

              // 5. Nội dung danh sách (Loading hoặc List)
              isLoading
                  ? const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: vkuBlue)),
              )
                  : filteredStudents.isEmpty
                  ? const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text("Không tìm thấy sinh viên nào", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold))),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildStudentCard(filteredStudents[index]),
                    childCount: filteredStudents.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- CÁC COMPONENT GIAO DIỆN ---

    Widget _buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
        child: Row(
          children: [
            Container(width: 6, height: 24, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 12),
            Text(title.toUpperCase(), style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
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
                      const Text("TỔNG SINH VIÊN HIỆN TẠI", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("$filteredCount sinh viên", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 40, thickness: 1.5),
              Row(
                children: [
                  Expanded(child: _buildBigDropdown("Tháng", filterMonth, months, (v) { setState(() => filterMonth = v!); _loadAllStudents(); })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBigDropdown("Năm", filterYear, years, (v) { setState(() => filterYear = v!); _loadAllStudents(); })),
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
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true, dropdownColor: vkuBlue,
            icon: const Icon(Icons.expand_more_rounded, color: Colors.white, size: 20),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.contains("Tất cả") ? e : "$title ${e.replaceAll(title, '').trim()}"))).toList(),
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

    Widget _buildStudentCard(dynamic student) {
      bool isPaid = (student['is_paid'] == 1 || student['is_paid'] == "1");

      // --- Xử lý Avatar URL ---
      String? avatarPath = student['avatar_url'];
      String fullAvatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
          ? (avatarPath.startsWith('http') ? avatarPath : "http://192.168.4.21/dacs3/uploads/$avatarPath")
          : "";

      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentDetailAdminPage(student: student))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: vkuBlue.withOpacity(0.1), width: 2)),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: sandBg,
                  backgroundImage: fullAvatarUrl.isNotEmpty ? NetworkImage(fullAvatarUrl) : null,
                  child: fullAvatarUrl.isEmpty ? const Icon(Icons.person, color: vkuBlue, size: 30) : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student['fullname'] ?? "N/A", style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text("Phòng ${student['room_id']} • ${student['student_code']}", style: TextStyle(color: darkText.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
              Icon(isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: isPaid ? Colors.green : Colors.redAccent, size: 28),
            ],
          ),
        ),
      );
    }
  }