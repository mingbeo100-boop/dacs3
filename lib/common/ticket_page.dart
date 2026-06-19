import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để dò bảng dữ liệu
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // BẮT BUỘC: Giải mã chuỗi Base64 đại diện của sinh viên liên kết
import 'package:firebase_storage/firebase_storage.dart';

class TicketPage extends StatefulWidget {
  final dynamic user;
  const TicketPage({super.key, this.user});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardWhite = Color(0xFFFFFFFF);

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool _isSending = false;
  String _selectedTab = "Đang chờ";

  @override
  void dispose() {
    _contentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- LOGIC ADMIN: CẬP NHẬT TRẠNG THÁI SỰ CỐ ---
  Future<void> _updateTicketFull(dynamic id, String status, String note) async {
    Navigator.pop(context); // Đóng nhanh bottom sheet
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(id.toString())
          .update({
        "status": status,
        "admin_note": note,
      });
    } catch (e) {
      debugPrint("Lỗi cập nhật trạng thái sự cố: $e");
    }
  }

  // --- LOGIC SINH VIÊN: GỬI YÊU CẦU SỬA CHỮA MỚI ---
  Future<void> _sendTicket() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      String imageUrl = "";

      if (_image != null) {
        String fileName = "ticket_${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference storageRef = FirebaseStorage.instance.ref().child("tickets/$fileName");

        UploadTask uploadTask = storageRef.putFile(_image!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('tickets').add({
        'username': widget.user['username'].toString(),
        'fullname': widget.user['fullname'] ?? "Sinh viên VKU",
        'room_id': widget.user['room_id'].toString(),
        'content': _contentController.text.trim(),
        'image_url': imageUrl,
        'status': 'pending',
        'admin_note': '',
        'created_at': DateTime.now().toString().substring(0, 19),
      });

      _contentController.clear();
      setState(() {
        _image = null;
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đã gửi yêu cầu hỗ trợ đến Ban quản lý!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: vkuBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.user?['role'] == 'admin';

    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              // PHÂN PHỐI LUỒNG GIAO DIỆN CHUẨN ĐẦU VÀO
              child: isAdmin ? _buildAdminView() : _buildStudentView(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 🚀 LUỒNG GIAO DIỆN 1: DÀNH CHO SINH VIÊN (CHỈ XEM PHÒNG MÌNH + ĐƯỢC GỬI VÉ)
  // =========================================================================
  Widget _buildStudentView() {
    final Stream<QuerySnapshot> studentStream = FirebaseFirestore.instance
        .collection('tickets')
        .where('room_id', isEqualTo: widget.user['room_id'].toString())
        .orderBy('created_at', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: studentStream,
      builder: (context, snapshot) => _buildTicketListStructure(snapshot, isAdminView: false),
    );
  }

  // =========================================================================
  // 🚀 LUỒNG GIAO DIỆN 2: DÀNH CHO ADMIN (XEM TOÀN BỘ KTX - ẨN Ô NHẬP LIỆU)
  // =========================================================================
  Widget _buildAdminView() {
    final Stream<QuerySnapshot> adminStream = FirebaseFirestore.instance
        .collection('tickets')
        .orderBy('created_at', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: adminStream,
      builder: (context, snapshot) => _buildTicketListStructure(snapshot, isAdminView: true),
    );
  }

  // =========================================================================
  // 🛠️ HÀM RENDER CẤU TRÚC DANH SÁCH DÙNG CHUNG (TỐI ƯU HÓA PHÒNG VỆ)
  // =========================================================================
  Widget _buildTicketListStructure(AsyncSnapshot<QuerySnapshot> snapshot, {required bool isAdminView}) {
    if (snapshot.hasError) {
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Đang đồng bộ cấu trúc chỉ mục hoặc lỗi: ${snapshot.error}", style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: vkuOrange));
    }
    if (!snapshot.hasData || snapshot.data == null) {
      return const Center(child: Text("Không có dữ liệu phản hồi."));
    }

    List<dynamic> allTickets = snapshot.data!.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    List<dynamic> filteredList = allTickets.where((t) {
      String s = (t['status'] ?? 'pending').toString().toLowerCase();
      if (_selectedTab == "Đang chờ") return s != 'completed';
      return s == 'completed';
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!isAdminView) SliverToBoxAdapter(child: _buildAdvancedInputCard()),
        SliverToBoxAdapter(child: _buildFilterTab()),
        SliverToBoxAdapter(child: _buildSectionTitle(isAdminView ? "DANH SÁCH ĐIỀU PHỐI" : "LỊCH SỬ PHẢN HỒI")),

        filteredList.isEmpty
            ? const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text("Chưa có ghi nhận sự cố nào ở mục này.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold))),
          ),
        )
            : SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverPadding(
            padding: const EdgeInsets.only(bottom: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEnhancedTicketCard(filteredList[index], isAdminView),
                childCount: filteredList.length,
                addRepaintBoundaries: true, // Tối ưu hóa GPU render phần cứng khi cuộn mượt
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(left: 10, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: vkuBlue, size: 20))),
        const Text("HỖ TRỢ & SỬA CHỮA", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
      ]),
    );
  }

  Widget _buildAdvancedInputCard() {
    return Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("GỬI YÊU CẦU MỚI", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 15),
        TextField(controller: _contentController, maxLines: 3, decoration: InputDecoration(hintText: "Bạn cần hỗ trợ gì tại phòng ${widget.user['room_id']}?", filled: true, fillColor: sandBg.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
        const SizedBox(height: 15),
        Row(children: [
          InkWell(onTap: _pickImage, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: vkuOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(Icons.camera_alt_rounded, color: vkuOrange, size: 18), const SizedBox(width: 8), Text(_image == null ? "Thêm ảnh" : "Đã chọn ảnh", style: const TextStyle(color: vkuOrange, fontWeight: FontWeight.bold, fontSize: 12))]))),
          const Spacer(),
          ElevatedButton(onPressed: _isSending ? null : _sendTicket, style: ElevatedButton.styleFrom(backgroundColor: vkuBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("GỬI YÊU CẦU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
        ]),
        if (_image != null) Padding(padding: const EdgeInsets.only(top: 15), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, height: 100, width: double.infinity, fit: BoxFit.cover))),
      ]),
    );
  }

  Widget _buildFilterTab() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15), padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(children: ["Đang chờ", "Hoàn thành"].map((tab) {
        bool isSelected = _selectedTab == tab;
        return Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = tab), child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? vkuBlue : Colors.transparent, borderRadius: BorderRadius.circular(15)), child: Text(tab, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : vkuBlue, fontWeight: FontWeight.bold, fontSize: 13)))));
      }).toList()),
    );
  }

  // --- SIÊU TỐI ƯU CỐT LÕI: TOÁN TỬ CHẶN ĐỨNG CHUỖI RỖNG CHỐNG SẬP MÀN HÌNH ĐỎ ĐỘT NGỘT ---
  Widget _buildEnhancedTicketCard(dynamic item, bool isAdmin) {
    Color statusColor; IconData statusIcon;
    switch (item['status'].toString().toLowerCase()) {
      case 'processing': statusColor = Colors.blue; statusIcon = Icons.settings_suggest_rounded; break;
      case 'delayed': statusColor = Colors.orange; statusIcon = Icons.watch_later_rounded; break;
      case 'completed': statusColor = Colors.green; statusIcon = Icons.check_circle_rounded; break;
      default: statusColor = Colors.orange; statusIcon = Icons.hourglass_top_rounded;
    }

    String studentId = (item['username'] ?? "").toString().trim();

    // ⚡ TUYỆT CHIÊU PHÒNG VỆ: Nếu phát hiện bản ghi rác thiếu username, ngắt luồng bốc profile và render card an toàn
    if (studentId.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(25)),
        child: ListTile(
          onTap: () => _showTicketDetail(item),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(statusIcon, color: statusColor, size: 20)),
          title: Text("Sự cố phòng ${item['room_id'] ?? 'Chưa rõ'}", style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14)),
          subtitle: Text(item['content'] ?? "Không có nội dung mô tả.", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('profiles').doc(studentId).snapshots(),
          builder: (context, profileSnapshot) {
            String displayTitle = isAdmin ? "Sinh viên: ${item['fullname'] ?? "Ẩn danh"}" : "Sự cố phòng ${item['room_id']}";
            ImageProvider? cardAvatarProvider;

            if (profileSnapshot.hasData && profileSnapshot.data != null && profileSnapshot.data!.exists) {
              final Object? rawProfile = profileSnapshot.data!.data();
              if (rawProfile is Map<String, dynamic>) {
                if (isAdmin && rawProfile['fullname'] != null) {
                  displayTitle = rawProfile['fullname'].toString();
                }

                String? rawAvatar = rawProfile['avatar_url']?.toString();
                if (rawAvatar != null && rawAvatar.isNotEmpty) {
                  if (rawAvatar.startsWith('data:image')) {
                    try {
                      String cleanStr = rawAvatar.replaceAll('\n', '').replaceAll('\r', '').trim();
                      if (cleanStr.contains(',')) {
                        cardAvatarProvider = MemoryImage(base64Decode(cleanStr.split(',')[1]));
                      } else {
                        cardAvatarProvider = MemoryImage(base64Decode(cleanStr));
                      }
                    } catch (e) {
                      debugPrint("Lỗi giải mã ảnh trên thẻ: $e");
                    }
                  } else if (rawAvatar.startsWith('http')) {
                    cardAvatarProvider = NetworkImage(rawAvatar);
                  }
                }
              }
            }

            return ListTile(
              onTap: () => _showTicketDetail(item),
              leading: cardAvatarProvider != null
                  ? CircleAvatar(radius: 20, backgroundImage: cardAvatarProvider)
                  : Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(statusIcon, color: statusColor, size: 20)),
              title: Text(displayTitle, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14)),
              subtitle: Text("Phòng ${item['room_id'] ?? 'N/A'} ➔ ${item['content'] ?? ''}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
            );
          }
      ),
    );
  }

  void _showTicketDetail(dynamic item) {
    String imgUrl = (item['image_url'] != null && item['image_url'].toString().isNotEmpty) ? item['image_url'].toString() : "";
    bool isAdmin = widget.user?['role'] == 'admin';
    String status = item['status'] ?? 'pending';
    _noteController.text = item['admin_note'] ?? "";

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        padding: EdgeInsets.fromLTRB(25, 15, 25, MediaQuery.of(context).viewInsets.bottom + 25),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text("CHI TIẾT PHẢN HỒI", style: TextStyle(color: vkuBlue, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            if (imgUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(imgUrl, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 100, color: Colors.grey[100], child: const Icon(Icons.broken_image)))),
            const SizedBox(height: 15),
            const Text("NỘI DUNG:", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 10)),
            Text(item['content'] ?? "...", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: vkuBlue)),
            const Divider(height: 30),
            if (item['admin_note'] != null && item['admin_note'] != "") _buildAlertBox("PHẢN HỒI TỪ BAN QUẢN LÝ", item['admin_note'], Colors.blue),
            const SizedBox(height: 20),
            if (isAdmin && status != 'completed') ...[
              const Text("CẬP NHẬT TRẠNG THÁI:", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 10),
              TextField(controller: _noteController, decoration: InputDecoration(hintText: "Ghi chú cho sinh viên...", filled: true, fillColor: sandBg.withOpacity(0.3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              Row(children: [
                _buildStatusBtn(item['id'], "processing", "ĐANG SỬA", Colors.blue),
                const SizedBox(width: 10),
                _buildStatusBtn(item['id'], "delayed", "HẸN LẠI", Colors.amber),
                const SizedBox(width: 10),
                _buildStatusBtn(item['id'], "completed", "XONG", Colors.green),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildAlertBox(String title, String content, Color color) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        const SizedBox(height: 5),
        Text(content, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStatusBtn(id, status, label, color) => Expanded(
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
      onPressed: () => _updateTicketFull(id, status, _noteController.text),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(25, 10, 25, 15), child: Row(children: [Container(width: 5, height: 18, color: vkuOrange), const SizedBox(width: 12), Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13))]));
  }

  Future<void> _pickImage() async {
    final p = await picker.pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _image = File(p.path));
  }
}