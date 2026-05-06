import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _roomController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;

  // --- HỆ MÀU ĐỒNG BỘ (LÌ & SANG) ---
  static const vkuBlue = Color(0xFF002266);      // Xanh dương đậm
  static const sandBg = Color(0xFFF5E1C5);       // Nền màu Cát (Sand)
  static const cardBg = Color(0xFFFFF8F0);       // Màu kem nhạt cho ô input
  static const colorAccent = Color(0xFFD4A373);  // Nâu gỗ Pastel từ trang Home

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _roomController.text.isEmpty ||
        _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng điền đầy đủ các thông tin!"),
          backgroundColor: colorAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // CẬP NHẬT IP CỦA NHẬT LONG: 192.168.1.14
      final response = await http.post(
        Uri.parse("http://192.168.1.191/dacs3/register.php"),
        body: {
          "fullname": _nameController.text.trim(),
          "username": _usernameController.text.trim(),
          "room": _roomController.text.trim(),
          "password": _passController.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Đăng ký thành công! Mời bạn đăng nhập."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể kết nối đến máy chủ 192.168.1.191!")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: vkuBlue), // Icon quay lại màu xanh đậm
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB347), sandBg, sandBg],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo VKU với nền Kem
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                  ),
                  child: Image.asset('assets/logo_vku.png', width: 65, height: 65),
                ),
                const SizedBox(height: 20),
                const Text(
                  "TẠO TÀI KHOẢN MỚI",
                  style: TextStyle(color: vkuBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 30),

                // Form nhập liệu màu Sand
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: sandBg.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colorAccent.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(controller: _nameController, label: "Họ và tên", icon: Icons.badge_outlined),
                      const SizedBox(height: 15),
                      _buildTextField(controller: _usernameController, label: "Mã sinh viên", icon: Icons.account_circle_outlined),
                      const SizedBox(height: 15),
                      _buildTextField(controller: _roomController, label: "Số phòng (VD: 2_302)", icon: Icons.meeting_room_outlined),
                      const SizedBox(height: 15),
                      _buildTextField(controller: _passController, label: "Mật khẩu", icon: Icons.lock_open_rounded, isPassword: true),
                      const SizedBox(height: 30),

                      _isLoading
                          ? const CircularProgressIndicator(color: vkuBlue)
                          : RegisterButton(onTap: _register, title: "ĐĂNG KÝ NGAY"),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Đã có tài khoản? Đăng nhập ngay",
                    style: TextStyle(color: vkuBlue, fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w600, fontSize: 13),
        prefixIcon: Icon(icon, color: colorAccent),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: vkuBlue),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        )
            : null,
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: colorAccent.withOpacity(0.4), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: vkuBlue, width: 2)),
      ),
    );
  }
}

// --- WIDGET NÚT BẤM (ĐỒNG BỘ LOGIN) ---
class RegisterButton extends StatefulWidget {
  final VoidCallback onTap;
  final String title;
  const RegisterButton({super.key, required this.onTap, required this.title});

  @override
  State<RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<RegisterButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150), reverseDuration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut, reverseCurve: Curves.elasticOut),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF002266),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFF002266).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}