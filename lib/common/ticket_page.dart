import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';

class TicketPage extends StatefulWidget {
  final dynamic user;
  const TicketPage({super.key, this.user});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF9800);
  static const vkuOrangeDark = Color(0xFFE65100);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardWhite = Color(0xFFFFFFFF);

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool _isSending = false;
  List<dynamic> _ticketList = [];
  String _selectedTab = "Đang chờ";

  final String serverUrl = "http://192.168.4.21/dacs3";

  @override
  void initState() {
    super.initState();
    if (widget.user != null) _loadTickets();
  }

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) return "";
    try {
      Uri uri = Uri.parse(url);
      return "$serverUrl${uri.path.replaceFirst('/dacs3', '')}";
    } catch (e) { return ""; }
  }

  Future<void> _loadTickets() async {
    try {
      final String url = "$serverUrl/manage_tickets.php?role=${widget.user['role']}&room_id=${widget.user['room_id']}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() => _ticketList = jsonDecode(res.body));
      }
    } catch (e) { debugPrint("Lỗi tải ticket: $e"); }
  }

  // --- SỬA LẠI HÀM NÀY ĐỂ NHẤN LÀ ĂN ---
  Future<void> _updateTicketFull(dynamic id, String status, String note) async {
    setState(() => _isSending = true); // Hiện loading nếu cần
    try {
      final res = await http.post(
        Uri.parse("$serverUrl/update_ticket_status.php"), // GỌI ĐÚNG FILE PHP CỦA ÔNG
        body: {
          "ticket_id": id.toString(),
          "status": status,
          "admin_note": note,
        },
      );

      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        if (responseData['status'] == 'success') {
          Navigator.pop(context); // Đóng BottomSheet ngay
          _loadTickets(); // Refresh danh sách
        }
      }
    } catch (e) {
      debugPrint("Lỗi kết nối Server: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.user?['role'] == 'admin';
    List<dynamic> filteredList = _ticketList.where((t) {
      if (_selectedTab == "Đang chờ") return t['status'] != 'completed';
      return t['status'] == 'completed';
    }).toList();

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [vkuBlue, Color(0xFF0D47A1)]))),
        title: const Text("HỖ TRỢ & SỬA CHỮA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (!isAdmin) _buildInputCard(),
          _buildFilterTab(),
          _buildHeader(isAdmin ? "DANH SÁCH ĐIỀU PHỐI" : "LỊCH SỬ PHẢN HỒI"),
          Expanded(child: _buildVkuList(filteredList, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildFilterTab() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: ["Đang chờ", "Hoàn thành"].map((tab) {
          bool isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: isSelected ? vkuOrange : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(tab, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : vkuBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVkuList(List<dynamic> list, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        String statusText = "";
        Color statusColor = Colors.grey;

        switch (item['status']) {
          case 'processing': statusText = "Đang tiến hành sửa chữa"; statusColor = Colors.blue; break;
          case 'delayed': statusText = "Tạm hoãn - Đang chờ thợ"; statusColor = Colors.orange; break;
          case 'completed': statusText = "Đã hoàn thành sửa chữa"; statusColor = Colors.green; break;
          default: statusText = "Đang chờ quản trị viên duyệt"; statusColor = Colors.orange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            onTap: () => _showTicketDetail(item),
            leading: _buildStatusIcon(item['status']),
            title: Text(isAdmin ? "SV: ${item['fullname'] ?? 'N/A'}" : "Sự cố phòng ${item['room_id']}",
                style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item['content'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11)),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String? status) {
    Color color = Colors.orange;
    IconData icon = Icons.hourglass_empty_rounded;
    if (status == 'processing') { color = Colors.blue; icon = Icons.handyman_rounded; }
    else if (status == 'delayed') { color = Colors.amber; icon = Icons.event_busy_rounded; }
    else if (status == 'completed') { color = Colors.green; icon = Icons.check_circle_rounded; }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _showTicketDetail(dynamic item) {
    String imgUrl = _fixUrl(item['image_url']);
    bool isAdmin = widget.user?['role'] == 'admin';
    String status = item['status'] ?? 'pending';
    _noteController.text = item['admin_note'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: cardWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        padding: EdgeInsets.fromLTRB(25, 15, 25, MediaQuery.of(context).viewInsets.bottom + 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              const Text("CHI TIẾT PHẢN HỒI", style: TextStyle(color: vkuBlue, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              if (imgUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => _showFullImage(imgUrl),
                  child: Container(
                    height: 220, width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(imgUrl, fit: BoxFit.cover)),
                  ),
                ),
              const SizedBox(height: 25),
              const Text("NỘI DUNG:", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 5),
              Text(item['content'] ?? "...", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: vkuBlue)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),

              if (item['admin_note'] != null && item['admin_note'] != "")
                _buildAlertBox(
                  status == 'delayed' ? "THÔNG BÁO TẠM HOÃN" : (status == 'completed' ? "HOÀN THÀNH" : "CẬP NHẬT TIẾN ĐỘ"),
                  item['admin_note'],
                  status == 'delayed' ? Colors.amber : (status == 'completed' ? Colors.green : Colors.blue),
                ),

              const SizedBox(height: 20),

              if (isAdmin && status != 'completed') ...[
                const Text("PHẢN HỒI CHO SINH VIÊN:", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: "VD: Đang chờ thợ, sẽ sửa sớm...",
                    filled: true,
                    fillColor: sandBg.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _buildStatusBtn(item['id'], "processing", "ĐANG SỬA", const Color(0xFF2196F3)),
                    const SizedBox(width: 12),
                    _buildStatusBtn(item['id'], "delayed", "HẸN LẠI", const Color(0xFFFFB300)),
                    const SizedBox(width: 12),
                    _buildStatusBtn(item['id'], "completed", "XONG", const Color(0xFF4CAF50)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBox(String title, String content, Color color) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(22), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.info_outline_rounded, color: color, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11))]),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: Color(0xFF455A64), fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  Widget _buildStatusBtn(id, status, label, color) => Expanded(
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        onPressed: () => _updateTicketFull(id, status, _noteController.text),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
      ),
    ),
  );

  void _showFullImage(String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: PhotoView(imageProvider: NetworkImage(imageUrl)),
    )));
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
      child: Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 10), Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14))]),
    );
  }

  Widget _buildInputCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: TextField(controller: _contentController, maxLines: 2, decoration: const InputDecoration(hintText: "Mô tả sự cố...", border: InputBorder.none))),
        if (_image != null) Padding(padding: const EdgeInsets.only(bottom: 15), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, height: 80, width: 80, fit: BoxFit.cover))),
        Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(gradient: LinearGradient(colors: [vkuOrange, vkuOrangeDark]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))), child: Row(children: [IconButton(icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white), onPressed: () async { final p = await picker.pickImage(source: ImageSource.gallery); if (p != null) setState(() => _image = File(p.path)); }), const Spacer(), ElevatedButton(onPressed: _isSending ? null : _sendTicket, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: vkuOrangeDark), child: const Text("GỬI NGAY"))]))
      ]),
    );
  }

  Future<void> _sendTicket() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      var req = http.MultipartRequest('POST', Uri.parse("$serverUrl/manage_tickets.php"));
      req.fields['user_id'] = widget.user['id'].toString();
      req.fields['room_id'] = widget.user['room_id'].toString();
      req.fields['content'] = _contentController.text;
      if (_image != null) req.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      await req.send();
      _contentController.clear(); setState(() => _image = null); _loadTickets();
    } catch (e) { debugPrint(e.toString()); }
    finally { setState(() => _isSending = false); }
  }
}