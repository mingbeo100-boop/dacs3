import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore (Spark Plan Miễn phí)
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // BẮT BUỘC: Thư viện mã hóa và giải mã chuỗi Base64
import 'common/login_page.dart';

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
  bool isUpdating = false;

  String get currentUserId => widget.user['user_id']?.toString() ?? widget.user['id']?.toString() ?? widget.user['username']?.toString() ?? "";

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['fullname']);
    phoneController = TextEditingController(text: widget.user['phone'] ?? "");
    cccdController = TextEditingController(text: widget.user['cccd'] ?? "");
    roomController = TextEditingController(text: widget.user['room_id']?.toString() ?? "");
    emailController = TextEditingController(text: widget.user['email_contact'] ?? widget.user['email'] ?? "");

    existingAvatarUrl = widget.user['avatar_url'];

    if (currentUserId.isNotEmpty) {
      _fetchProfileFromCloud();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cccdController.dispose();
    roomController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // --- SỬA LOGIC: TRUY VẤN ĐỘNG THEO FIELD USER_ID TRONG BẢNG PROFILES ---
  Future<void> _fetchProfileFromCloud() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('user_id', isEqualTo: currentUserId)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['fullname'] ?? nameController.text;
          phoneController.text = data['phone'] ?? phoneController.text;
          cccdController.text = data['cccd'] ?? cccdController.text;
          roomController.text = data['room_id']?.toString() ?? roomController.text;
          emailController.text = data['email_contact'] ?? data['email'] ?? emailController.text;
          existingAvatarUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải hồ sơ sinh viên từ profiles: $e");
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() { _image = File(pickedFile.path); });
    }
  }

  // --- SỬA LOGIC LUỒNG: TRIỆT TIÊU LỆNH POP SAI LÀM SẬP MÀN HÌNH ĐEN ---
  Future<void> _updateProfile() async {
    if (currentUserId.isEmpty) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: vkuBlue))
    );

    try {
      String finalAvatarUrl = existingAvatarUrl ?? "";

      if (_image != null) {
        List<int> imageBytes = await _image!.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        finalAvatarUrl = "data:image/jpeg;base64,${base64Image.replaceAll('\n', '').replaceAll('\r', '').trim()}";
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('user_id', isEqualTo: currentUserId)
          .get();

      final Map<String, dynamic> profileData = {
        "user_id": currentUserId,
        "fullname": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "cccd": cccdController.text.trim(),
        "room_id": roomController.text.trim(),
        "email_contact": emailController.text.trim(),
        "avatar_url": finalAvatarUrl,
      };

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(docId)
            .update(profileData);
      } else {
        await FirebaseFirestore.instance
            .collection('profiles')
            .add(profileData);
      }

      if (!mounted) return;
      Navigator.pop(context); // CHỈ POP DUY NHẤT 1 LẦN: Tắt vòng xoay tròn Loading dữ liệu ngầm

      // Tự động đồng bộ ảnh mới cập nhật ngược lại cache UI hiện tại mà không cần load lại app
      setState(() {
        existingAvatarUrl = finalAvatarUrl;
        _image = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✨ Đã cập nhật thông tin cá nhân lên bảng Profiles thành công!"), backgroundColor: vkuBlue, behavior: SnackBarBehavior.floating)
      );

      // KHÔNG sử dụng lệnh Navigator.pop(context, true) ở đây nữa để né sụp đổ luồng PageView của trang Home

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tắt vòng xoay tròn Loading khi dính lỗi

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi cập nhật: $e"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
      );
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
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("ĐĂNG XUẤT", style: TextStyle(color: colorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarProvider;
    if (_image != null) {
      avatarProvider = FileImage(_image!);
    } else if (existingAvatarUrl != null && existingAvatarUrl!.isNotEmpty) {
      if (existingAvatarUrl!.startsWith('data:image')) {
        try {
          String cleanUrl = existingAvatarUrl!.replaceAll('\n', '').replaceAll('\r', '').trim();
          if (cleanUrl.contains(',')) {
            String base64Str = cleanUrl.split(',')[1];
            avatarProvider = MemoryImage(base64Decode(base64Str));
          } else {
            avatarProvider = MemoryImage(base64Decode(cleanUrl));
          }
        } catch (e) {
          debugPrint("Lỗi giải mã Base64 trong UI: $e");
          avatarProvider = null;
        }
      } else if (existingAvatarUrl!.startsWith('http')) {
        avatarProvider = NetworkImage(existingAvatarUrl!);
      }
    }

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("HỒ SƠ SINH VIÊN", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: sandBg,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
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
            _buildInputField("Số phòng ở ký túc xá", roomController, Icons.meeting_room_outlined),
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
        label: const Text("ĐĂNG XUẤT TÀI KHOẢN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
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