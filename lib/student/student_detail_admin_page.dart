import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Đưa toàn bộ luồng quản lý lên Firestore

class StudentDetailAdminPage extends StatefulWidget {
  final dynamic student; // Bản ghi thông tin sinh viên được truyền từ danh sách Admin sang
  const StudentDetailAdminPage({super.key, required this.student});

  @override
  State<StudentDetailAdminPage> createState() => _StudentDetailAdminPageState();
}

class _StudentDetailAdminPageState extends State<StudentDetailAdminPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const darkText = Color(0xFF263238);

  bool isPaid = false;
  bool isLoading = false;

  late String selectedMonth;
  late String selectedYear;

  final List<String> months = List.generate(12, (i) => "Tháng ${i + 1 < 10 ? '0' : ''}${i + 1}");
  final List<String> years = ["2024", "2025", "2026", "2027"];

  Map<String, bool> blueSundayStatus = {
    "Tuần 01": false,
    "Tuần 02": false,
    "Tuần 03": false,
    "Tuần 04": false,
  };

  // Lấy ra mã định danh sinh viên (username/MSSV) làm khóa liên kết chính
  String get studentMssv => widget.student['username']?.toString() ?? "";

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    selectedMonth = "Tháng ${now.month < 10 ? '0' : ''}${now.month}";
    selectedYear = years.contains(now.year.toString()) ? now.year.toString() : "2026";

    if (studentMssv.isNotEmpty) {
      _fetchStatusFromCloud();
    }
  }

  // --- LOGIC MỚI: BỐC TRẠNG THÁI HỌC PHÍ VÀ ĐIỂM DANH TỪ FIRESTORE ---
  Future<void> _fetchStatusFromCloud() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // Định danh document động theo cấu trúc: MSSV_Thang_Nam
      String docId = "${studentMssv}_${selectedMonth}_$selectedYear";

      DocumentSnapshot statusDoc = await FirebaseFirestore.instance
          .collection('room_statuses')
          .doc(docId)
          .get();

      if (statusDoc.exists) {
        final data = statusDoc.data() as Map<String, dynamic>;
        setState(() {
          isPaid = data['is_paid'] == true || data['is_paid'].toString() == "1";
          blueSundayStatus["Tuần 01"] = data['week1'] == true || data['week1'].toString() == "1";
          blueSundayStatus["Tuần 02"] = data['week2'] == true || data['week2'].toString() == "1";
          blueSundayStatus["Tuần 03"] = data['week3'] == true || data['week3'].toString() == "1";
          blueSundayStatus["Tuần 04"] = data['week4'] == true || data['week4'].toString() == "1";
        });
      } else {
        // Nếu tháng này chưa có bản ghi dữ liệu, reset toàn bộ về trạng thái trống ban đầu
        setState(() {
          isPaid = false;
          blueSundayStatus.updateAll((key, value) => false);
        });
      }
    } catch (e) {
      debugPrint("Lỗi bốc dữ liệu trạng thái cư dân: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGIC MỚI: LƯU TẤT CẢ TRẠNG THÁI CẬP NHẬT LÊN FIRESTORE ---
  Future<void> _saveAllStatus() async {
    if (studentMssv.isEmpty) return;
    setState(() => isLoading = true);
    try {
      String docId = "${studentMssv}_${selectedMonth}_$selectedYear";

      // Sử dụng .set với tính năng merge: true để ghi đè hoặc tạo mới nếu chưa tồn tại
      await FirebaseFirestore.instance
          .collection('room_statuses')
          .doc(docId)
          .set({
        "username": studentMssv,
        "fullname": widget.student['fullname'] ?? "N/A",
        "room_id": widget.student['room_id'] ?? "Chưa rõ",
        "month": selectedMonth,
        "year": selectedYear,
        "is_paid": isPaid,
        "week1": blueSundayStatus["Tuần 01"],
        "week2": blueSundayStatus["Tuần 02"],
        "week3": blueSundayStatus["Tuần 03"],
        "week4": blueSundayStatus["Tuần 04"],
        "updated_at": DateTime.now().toString().substring(0, 19),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã lưu thay đổi tình trạng cư trú lên hệ thống đám mây!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật Firestore: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGIC MỚI: PHÁT THÔNG BÁO NHẮC NHỞ REALTIME SANG ĐIỆN THOẠI SINH VIÊN ---
  Future<void> _sendNotification() async {
    if (studentMssv.isEmpty) return;
    String title = "NHẮC NHỞ TỪ BAN QUẢN LÝ KTX";
    String content = "";

    if (!isPaid) {
      content = "Bạn chưa hoàn tất học phí nội trú $selectedMonth. Vui lòng thanh toán sớm để tránh bị khóa các dịch vụ tiện ích!";
    } else {
      int vangCount = blueSundayStatus.values.where((v) => v == false).length;
      if (vangCount > 0) {
        content = "Hệ thống ghi nhận bạn vắng $vangCount buổi sinh hoạt Chủ nhật Xanh trong tháng này. Hãy chú ý đi đầy đủ hơn nhé!";
      } else {
        content = "Cảm ơn bạn đã hoàn thành xuất sắc các hoạt động và nghĩa vụ nội trú trong $selectedMonth!";
      }
    }

    try {
      setState(() => isLoading = true);

      // Thêm trực tiếp thông báo mới vào bảng 'notifications' để máy sinh viên hứng realtime
      await FirebaseFirestore.instance.collection('notifications').add({
        "username": studentMssv, // Định tuyến thông báo chính xác theo Mã sinh viên
        "title": title,
        "content": content,
        "is_read": false, // Mặc định tin nhắn mới gửi ở trạng thái chưa đọc
        "created_at": DateTime.now().toString().substring(0, 19),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚀 Đã bắn thông báo Realtime thành công: $content"),
            backgroundColor: vkuBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi bắn thông báo nhắc nhở: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đón link URL online lưu trực tiếp từ Firebase mây
    String fullAvatarUrl = widget.student['avatar_url']?.toString() ?? "";

    return Scaffold(
      backgroundColor: sandBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(fullAvatarUrl),
          SliverPadding(
            padding: const EdgeInsets.all(25),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle("THÔNG TIN CƯ TRÚ"),
                _buildCardContainer([
                  _buildProfileRow(Icons.meeting_room_rounded, "Vị trí phòng", "Phòng ${widget.student['room_id'] ?? 'Chưa rõ'}"),
                  const Divider(height: 25, thickness: 0.5),
                  _buildProfileRow(Icons.home_work_rounded, "Khu vực", "Ký túc xá VKU"),
                ]),

                const SizedBox(height: 25),

                _buildSectionTitle("TRẠNG THÁI HỌC PHÍ"),
                _buildCardContainer([
                  Row(
                    children: [
                      Expanded(child: _buildDropdownLabel("Tháng", selectedMonth, months, (v) {
                        if (v != null) { setState(() => selectedMonth = v); _fetchStatusFromCloud(); }
                      })),
                      const SizedBox(width: 15),
                      Expanded(child: _buildDropdownLabel("Năm", selectedYear, years, (v) {
                        if (v != null) {
                          setState(() => selectedYear = v);
                          _fetchStatusFromCloud(); // Đã sửa tên hàm cho đúng chuẩn
                        }
                      })),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaymentToggle(),
                ]),

                const SizedBox(height: 25),

                _buildSectionTitle("HOẠT ĐỘNG XANH (Thứ 7/CN)"),
                _buildCardContainer(blueSundayStatus.keys.map((week) {
                  return CheckboxListTile(
                    secondary: Icon(Icons.eco_rounded, color: blueSundayStatus[week]! ? Colors.green : Colors.grey[400]),
                    title: Text(week, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: vkuBlue)),
                    value: blueSundayStatus[week],
                    activeColor: vkuBlue,
                    onChanged: (val) => setState(() => blueSundayStatus[week] = val!),
                  );
                }).toList()),

                const SizedBox(height: 35),

                _buildActionButton(
                  onPressed: isLoading ? null : _saveAllStatus,
                  icon: Icons.cloud_upload_rounded,
                  label: "LƯU TẤT CẢ THAY ĐỔI",
                  bgColor: vkuBlue,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  onPressed: isLoading ? null : _sendNotification,
                  icon: Icons.notifications_active_rounded,
                  label: "GỬI NHẮC NHỞ NHANH",
                  bgColor: vkuOrange,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String url) {
    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: vkuBlue,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 58, backgroundColor: vkuOrange,
                child: CircleAvatar(
                  radius: 54, backgroundColor: vkuBlue,
                  child: CircleAvatar(
                    radius: 50, backgroundColor: cardBg,
                    backgroundImage: (url.isNotEmpty && url.startsWith('http')) ? NetworkImage(url) : null,
                    child: (url.isEmpty || !url.startsWith('http')) ? const Icon(Icons.person, size: 50, color: vkuBlue) : null,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text((widget.student['fullname'] ?? "N/A").toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              Text(widget.student['username'] ?? "CHƯA CẬP NHẬT",
                  style: const TextStyle(color: vkuOrange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))),
    );
  }

  Widget _buildPaymentToggle() {
    return Container(
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isPaid ? Colors.green : Colors.red, width: 1),
      ),
      child: CheckboxListTile(
        title: Text(isPaid ? "Đã đóng tiền" : "Chưa đóng tiền",
            style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.red)),
        value: isPaid,
        activeColor: Colors.green,
        onChanged: (val) => setState(() => isPaid = val!),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 5),
    child: Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13)),
  );

  Widget _buildCardContainer(List<Widget> children) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25)),
    child: Column(children: children),
  );

  Widget _buildProfileRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: vkuBlue, size: 20),
      const SizedBox(width: 15),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    ],
  );

  Widget _buildDropdownLabel(String label, String value, List<String> items, Function(String?) onChanged) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: vkuBlue, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true, value: value, items: items.map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _buildActionButton({required VoidCallback? onPressed, required IconData icon, required String label, required Color bgColor, bool isLoading = false}) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}