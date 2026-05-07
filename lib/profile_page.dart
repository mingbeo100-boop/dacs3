import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final dynamic user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const vkuBlue = Color(0xFF002266);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);
  static const colorAccent = Color(0xFFD4A373);
  static const colorRed = Color(0xFFB30000);

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController cccdController;
  late TextEditingController roomController;
  late TextEditingController emailController;

  File? _image;
  String? existingAvatarUrl;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 1. Khởi tạo controller từ dữ liệu widget
    nameController = TextEditingController(text: widget.user['fullname']);
    phoneController = TextEditingController(text: widget.user['phone'] ?? "");
    cccdController = TextEditingController(text: widget.user['cccd'] ?? "");
    roomController = TextEditingController(text: widget.user['room_id']?.toString() ?? "");
    emailController = TextEditingController(text: widget.user['email_contact'] ?? "");

    // 2. Gán link ảnh ban đầu
    existingAvatarUrl = widget.user['avatar_url'];

    // 3. Load dữ liệu mới nhất
    _fetchProfileFromSQL();
  }

  Future<void> _fetchProfileFromSQL() async {
    try {
      var url = "http://192.168.4.21/dacs3/get_profile.php?user_id=${widget.user['id']}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          setState(() {
            nameController.text = data['fullname'] ?? nameController.text;
            phoneController.text = data['phone'] ?? phoneController.text;
            cccdController.text = data['cccd'] ?? cccdController.text;
            roomController.text = data['room_id']?.toString() ?? roomController.text;
            emailController.text = data['email_contact'] ?? emailController.text;
            existingAvatarUrl = data['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu: $e");
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _image = File(pickedFile.path); });
    }
  }

  Future<void> _updateProfile() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: vkuBlue))
    );

    try {
      var uri = Uri.parse("http://192.168.4.21/dacs3/update_profile.php");
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = widget.user['id'].toString();
      request.fields['fullname'] = nameController.text;
      request.fields['phone'] = phoneController.text;
      request.fields['cccd'] = cccdController.text;
      request.fields['room_id'] = roomController.text;
      request.fields['email'] = emailController.text;

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', _image!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: vkuBlue, behavior: SnackBarBehavior.floating)
        );
        if (result['success'] == true) {
          // Trả về true để HomePage biết cần load lại dữ liệu
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint("Lỗi Update: $e");
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Xác nhận", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold)),
        content: const Text("Bạn muốn đăng xuất khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
            child: const Text("ĐĂNG XUẤT", style: TextStyle(color: colorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("HỒ SƠ SINH VIÊN", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: sandBg,
        elevation: 0,
        centerTitle: true,
        // QUAN TRỌNG: Xóa nút Back bằng cách set leading là null và chặn tự động thêm
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorAccent.withOpacity(0.5), width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: cardBg,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (existingAvatarUrl != null && existingAvatarUrl!.isNotEmpty)
                          ? NetworkImage(
                          existingAvatarUrl!.contains('http')
                              ? existingAvatarUrl!
                              : "http://192.168.4.21/dacs3/uploads/profiles/$existingAvatarUrl"
                      )
                          : null,
                      child: (_image == null && (existingAvatarUrl == null || existingAvatarUrl!.isEmpty))
                          ? const Icon(Icons.person_rounded, size: 70, color: colorAccent)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 5,
                    child: GestureDetector(
                      onTap: getImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: vkuBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildInputField("Họ và tên", nameController, Icons.badge_outlined),
            _buildInputField("Số điện thoại", phoneController, Icons.phone_android_rounded),
            _buildInputField("Số CCCD", cccdController, Icons.card_membership_rounded),
            _buildInputField("Số phòng", roomController, Icons.meeting_room_outlined),
            _buildInputField("Email liên hệ", emailController, Icons.alternate_email_rounded),
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 15),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton.icon(
        onPressed: _updateProfile,
        icon: const Icon(Icons.save_as_rounded),
        label: const Text("CẬP NHẬT THÔNG TIN", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: vkuBlue, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
          shadowColor: colorRed.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: colorAccent),
          filled: true, fillColor: cardBg,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: colorAccent.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: vkuBlue, width: 2)),
        ),
      ),
    );
  }
}