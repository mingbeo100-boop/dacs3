import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để dò bảng dữ liệu
import 'home_page.dart';
// import 'register_page.dart'; // Mở ra nếu bạn có file này

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  // --- HỆ MÀU ĐỒNG BỘ (LÌ & SANG) ---
  static const vkuBlue = Color(0xFF002266);      // Xanh dương đậm chủ đạo
  static const sandBg = Color(0xFFF5E1C5);       // Nền màu Cát (Sand)
  static const cardBg = Color(0xFFFFF8F0);       // Màu kem nhạt cho ô input
  static const colorAccent = Color(0xFFD4A373);  // Màu nâu gỗ Pastel làm điểm nhấn

  // --- LOGIC ĐĂNG NHẬP: TRUY VẤN THẲNG VÀO BẢNG FIRESTORE ---
  void _handleLogin() async {
    final String username = _userController.text.trim(); // Ví dụ: 24ITB103
    final String password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ thông tin!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tìm kiếm trong collection 'users' dòng có username và password trùng khớp
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      // Nếu tìm thấy tài khoản hợp lệ trong bảng
      if (querySnapshot.docs.isNotEmpty) {
        var document = querySnapshot.docs.first;
        Map<String, dynamic> userData = document.data() as Map<String, dynamic>;
        userData['id'] = document.id; // Lưu lại Document ID làm định danh

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Chào mừng ${userData['fullname']} quay trở lại!"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorAccent,
            ),
          );

          // Chuyển trực tiếp dữ liệu sinh viên bốc được từ bảng sang HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(user: userData)),
          );
        }
      } else {
        // Nếu không có tài khoản nào trùng khớp cả username và password
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Mã sinh viên hoặc mật khẩu không chính xác!"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi kết nối database: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                // Logo VKU tròn có bóng đổ nhẹ
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                  ),
                  child: Image.asset('assets/logo_vku.png', width: 70, height: 70, errorBuilder: (context, error, stackTrace) {
                    // Dự phòng nếu chưa có file ảnh logo trong thư mục assets
                    return const Icon(Icons.school, size: 70, color: vkuBlue);
                  }),
                ),
                const SizedBox(height: 20),
                const Text(
                  "VKU SMART DORM",
                  style: TextStyle(color: vkuBlue, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 40),

                // Form nhập liệu màu Sand đậm bo góc
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: sandBg.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colorAccent.withOpacity(0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(controller: _userController, label: "Mã sinh viên", icon: Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildTextField(controller: _passController, label: "Mật khẩu", icon: Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 30),

                      _isLoading
                          ? const CircularProgressIndicator(color: vkuBlue)
                          : LoginButton(onTap: _handleLogin, title: "ĐĂNG NHẬP"),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Dòng link điều hướng sang trang Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản?", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w500)),
                    TextButton(
                      onPressed: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                      },
                      child: const Text(
                        "Đăng ký ngay",
                        style: TextStyle(color: Color(0xFFB30000), fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 18),
                      ),
                    ),
                  ],
                ),
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
        labelStyle: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: colorAccent),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: vkuBlue),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        )
            : null,
        filled: true,
        fillColor: cardBg,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: colorAccent.withOpacity(0.4), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: vkuBlue, width: 2)),
      ),
    );
  }
}

// --- WIDGET NÚT BẤM CÓ HIỆU ỨNG CO GIÃN CHUYÊN NGHIỆP ---
class LoginButton extends StatefulWidget {
  final VoidCallback onTap;
  final String title;
  const LoginButton({super.key, required this.onTap, required this.title});

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
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
            boxShadow: [BoxShadow(color: const Color(0xFF002266).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
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