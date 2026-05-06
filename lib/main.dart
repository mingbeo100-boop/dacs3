import 'package:flutter/material.dart';
import 'common/login_page.dart';
import 'common/home_page.dart'; // Nhớ tạo file này nếu chưa có
// import 'register_page.dart'; // Import thêm các trang khác của bạn

void main() {
  runApp(const VKUSmartDormApp());
}

class VKUSmartDormApp extends StatelessWidget {
  const VKUSmartDormApp({super.key});

  // --- HỆ MÀU CHỦ ĐẠO TOÀN APP ---
  static const vkuBlue = Color(0xFF002266);
  static const sandBg = Color(0xFFF5E1C5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VKU Smart Dorm',
      debugShowCheckedModeBanner: false,

      // Cấu hình Theme chung để các trang sau này tự động ăn theo tông màu này
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: vkuBlue,
        scaffoldBackgroundColor: sandBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: vkuBlue,
          primary: vkuBlue,
        ),
        fontFamily: 'Roboto',
      ),

      // 1. Trang sẽ hiện lên đầu tiên khi mở App
      initialRoute: '/login',

      // 2. Danh mục các trang trong App (Cực kỳ quan trọng để Đăng xuất chạy được)
      routes: {
        '/login': (context) => const LoginPage(),
        // '/register': (context) => const RegisterPage(),
        // '/home': (context) => const HomePage(user: {}),
        // Lưu ý: Nếu HomePage của bạn cần truyền biến 'user',
        // chú sẽ hướng dẫn cách truyền data qua Route sau nếu bạn cần.
      },

      // Cách dự phòng nếu bạn chưa quen dùng Named Routes cho các trang có tham số:
      home: const LoginPage(),
    );
  }
}