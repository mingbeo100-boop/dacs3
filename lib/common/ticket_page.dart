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
  // --- HỆ MÀU VKU CHUẨN ---
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF9800);
  static const vkuOrangeDark = Color(0xFFE65100);
  static const sandBg = Color(0xFFF5E1C5);

  final TextEditingController _contentController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool _isSending = false;
  List<dynamic> _ticketList = [];

  // QUAN TRỌNG: Kiểm tra đúng IP máy tính của ông
  final String serverUrl = "http://192.168.1.191/dacs3";

  @override
  void initState() {
    super.initState();
    if (widget.user != null) _loadTickets();
  }

  // Hàm bổ trợ: Tự động sửa lại IP trong URL để tránh lỗi màn hình đen khi đổi mạng
  String _fixUrl(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) return "";
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      return "$serverUrl${path.replaceFirst('/dacs3', '')}";
    } catch (e) { return ""; }
  }

  Future<void> _loadTickets() async {
    try {
      final String url = "$serverUrl/manage_tickets.php?room_id=${widget.user['room_id']}&role=${widget.user['role']}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() => _ticketList = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("Lỗi tải ticket: $e");
    }
  }

  Map<String, dynamic> _analyzeTicketAI(String content) {
    String text = content.toLowerCase();
    if (text.contains('điện') || text.contains('ổ cắm') || text.contains('bóng đèn')) {
      return {'type': 'ĐIỆN NĂNG', 'icon': Icons.bolt_rounded, 'color': Colors.amber.shade900};
    } else if (text.contains('nước') || text.contains('vòi') || text.contains('tắc')) {
      return {'type': 'NGUỒN NƯỚC', 'icon': Icons.opacity_rounded, 'color': Colors.blue.shade800};
    }
    return {'type': 'KỸ THUẬT', 'icon': Icons.build_circle_rounded, 'color': vkuOrangeDark};
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.user?['role'] == 'admin';
    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [vkuBlue, Color(0xFF0D47A1)]),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        title: const Text("HỖ TRỢ & BÁO CÁO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (!isAdmin) _buildInputCard(),
          _buildHeader(isAdmin ? "DANH SÁCH YÊU CẦU" : "LỊCH SỬ BÁO CÁO"),
          Expanded(child: _buildVkuList()),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _contentController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: "Mô tả sự cố...", border: InputBorder.none),
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, height: 80, width: 80, fit: BoxFit.cover)),
                  Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => _image = null), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white))))
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [vkuOrange, vkuOrangeDark]), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25))),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white), onPressed: () async {
                  final p = await picker.pickImage(source: ImageSource.gallery);
                  if (p != null) setState(() => _image = File(p.path));
                }),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendTicket,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: vkuOrangeDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSending ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("GỬI NGAY", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVkuList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _ticketList.length,
      itemBuilder: (context, index) {
        final item = _ticketList[index];
        bool isAdmin = widget.user?['role'] == 'admin';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
          child: ListTile(
            onTap: () => _showTicketDetail(item),
            leading: const CircleAvatar(backgroundColor: sandBg, child: Icon(Icons.build_circle_rounded, color: vkuOrange)),
            title: Text(isAdmin ? "SV: ${item['fullname'] ?? 'Ẩn danh'}" : "Phòng: ${item['room_id']}",
                style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(item['content'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showTicketDetail(dynamic item) {
    String imgUrl = _fixUrl(item['image_url']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: vkuBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Text("CHI TIẾT PHẢN HỒI",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imgUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullImage(imgUrl),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.contain, // Giữ nguyên tỉ lệ ảnh như hình mẫu của ông
                          loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text("NỘI DUNG:", style: TextStyle(fontWeight: FontWeight.bold, color: vkuBlue, fontSize: 12)),
                const SizedBox(height: 4),
                Text(item['content'] ?? "...", style: const TextStyle(fontSize: 14)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(thickness: 1),
                ),
                const Text("NGƯỜI GỬI:", style: TextStyle(fontWeight: FontWeight.bold, color: vkuBlue, fontSize: 12)),
                const SizedBox(height: 4),
                Text(item['fullname'] ?? "Ẩn danh", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vkuOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("ĐÓNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: PhotoView(imageProvider: NetworkImage(imageUrl)),
    )));
  }

  Future<void> _sendTicket() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      var req = http.MultipartRequest('POST', Uri.parse("$serverUrl/manage_tickets.php"));
      req.fields['user_id'] = widget.user['id'].toString();
      req.fields['room_id'] = widget.user['room_id'].toString();
      req.fields['content'] = _contentController.text;
      req.fields['category'] = _analyzeTicketAI(_contentController.text)['type'];
      if (_image != null) req.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      var res = await req.send();
      if (res.statusCode == 200) {
        _contentController.clear();
        setState(() => _image = null);
        _loadTickets();
      }
    } catch (e) {
      debugPrint("Lỗi gửi ticket: $e");
    } finally { setState(() => _isSending = false); }
  }
}