import 'package:flutter/material.dart';
import 'dart:convert'; // Hỗ trợ giải mã Base64

class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Color fallbackIconColor;
  final Color backgroundColor;

  const AppAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 25, // Bán kính mặc định
    this.fallbackIconColor = const Color(0xFFD4A373), // Màu icon mặc định
    this.backgroundColor = const Color(0xFFFFF8F0), // Màu nền mặc định (cardBg)
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarProvider;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:image')) {
        try {
          // Làm sạch chuỗi Base64 rác
          String cleanUrl = avatarUrl!.replaceAll('\n', '').replaceAll('\r', '').trim();
          if (cleanUrl.contains(',')) {
            String base64Str = cleanUrl.split(',')[1];
            avatarProvider = MemoryImage(base64Decode(base64Str));
          } else {
            avatarProvider = MemoryImage(base64Decode(cleanUrl));
          }
        } catch (e) {
          debugPrint("Lỗi giải mã Base64 tại AppAvatar dùng chung: $e");
          avatarProvider = null; // Bọc lỗi chống đen màn hình tuyệt đối
        }
      } else if (avatarUrl!.startsWith('http')) {
        avatarProvider = NetworkImage(avatarUrl!);
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: avatarProvider,
      child: avatarProvider == null
          ? Icon(Icons.person_rounded, size: radius * 1.1, color: fallbackIconColor)
          : null,
    );
  }
}