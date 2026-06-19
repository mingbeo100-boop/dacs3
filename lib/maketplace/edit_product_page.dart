import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore
import 'dart:convert';

class EditProductPage extends StatefulWidget {
  final dynamic product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  static const vkuBlue = Color(0xFF002266);
  static const priceRed = Color(0xFFB30000);
  static const sandBg = Color(0xFFF5E1C5);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.product['title'] ?? "";
    _priceController.text = widget.product['price']?.toString() ?? "";
    _descController.text = widget.product['description'] ?? "";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- LOGIC CẬP NHẬT THÔNG TIN MÓN ĐỒ ---
  Future<void> _updateProduct() async {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) return;
    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('marketplace')
          .doc(widget.product['id'].toString())
          .update({
        'title': _titleController.text.trim(),
        'price': _priceController.text.trim(),
        'description': _descController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã cập nhật sản phẩm thành công!")));
      }
    } catch (e) {
      debugPrint("Lỗi update sản phẩm: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // --- LOGIC XOÁ BÀI ĐĂNG KHỎI CHỢ ---
  Future<void> _deleteProduct() async {
    try {
      await FirebaseFirestore.instance
          .collection('marketplace')
          .doc(widget.product['id'].toString())
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Đã gỡ bỏ sản phẩm khỏi hệ thống chợ!"), backgroundColor: priceRed));
      }
    } catch (e) {
      debugPrint("Lỗi xóa sản phẩm: $e");
    }
  }

  ImageProvider? _parseBase64Image(String rawBase64) {
    if (rawBase64.trim().isEmpty) return null;
    try {
      String cleanStr = rawBase64.replaceAll('\n', '').replaceAll('\r', '').trim();
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',')[1];
      }
      return MemoryImage(base64Decode(cleanStr));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = (widget.product['image_url'] ?? "").toString().trim();
    ImageProvider? imageProvider = imageUrl.startsWith('http') ? NetworkImage(imageUrl) : _parseBase64Image(imageUrl);

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("QUẢN TRỊ MẶT HÀNG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: vkuBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 26),
            onPressed: () {
              // Hiện Dialog xác nhận trước khi xóa bài đăng của sinh viên
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Xác nhận gỡ bài?"),
                  content: const Text("Bạn có chắc chắn muốn xóa vĩnh viễn mặt hàng này khỏi Chợ KTX không?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
                    TextButton(onPressed: () { Navigator.pop(context); _deleteProduct(); }, child: const Text("XÓA BÀI", style: TextStyle(color: priceRed))),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (imageProvider != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image(image: imageProvider, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            _buildInput(controller: _titleController, hint: "Tên sản phẩm..."),
            const SizedBox(height: 15),
            _buildInput(controller: _priceController, hint: "Giá bán...", isNumber: true),
            const SizedBox(height: 15),
            _buildInput(controller: _descController, hint: "Mô tả...", maxLines: 4),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: vkuBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isUpdating ? null : _updateProduct,
                child: _isUpdating ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU CẬP NHẬT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.multiline, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
    );
  }
}