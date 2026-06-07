import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Thêm import Firebase Core
import 'firebase_options.dart'; // 2. Thêm import cấu hình Firebase Options
import 'common/login_page.dart';
import 'common/home_page.dart';

void main() async {
  // 3. Đảm bảo các dịch vụ native của Flutter được nạp đầy đủ trước
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Khởi tạo cổng kết nối trực tiếp đến Firebase Server
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

      // Trang khởi đầu mặc định
      home: const LoginPage(),
    );
  }
}