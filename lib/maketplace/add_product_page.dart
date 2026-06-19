import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // BẮT BUỘC: Mã hóa ảnh sang chuỗi Base64 trực tiếp

class AddProductPage extends StatefulWidget {
  final String userId; // Nhận Mã sinh viên từ trang Marketplace truyền sang
  const AddProductPage({super.key, required this.userId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const vkuBlue = Color(0xFF002266);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- HÀM TRỢ GIÚP: CHUYỂN FILE ẢNH SANG CHUỖI BASE64 GỌN SẠCH ---
  Future<String> _convertFileToBase64(File file) async {
    try {
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return "data:image/jpeg;base64,$base64String"; // Thêm header cấu trúc chuẩn
    } catch (e) {
      debugPrint("Lỗi mã hóa ảnh: $e");
      return "";
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Nén 50% tránh quá tải dung lượng document
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final price = _priceController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || price.isEmpty || desc.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đủ thông tin và chọn ảnh sản phẩm!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Tiến hành băm file ảnh (tủ lạnh, kệ giày...) thành chuỗi Base64 trực tiếp trên RAM
      String base64Image = await _convertFileToBase64(_imageFile!);

      // 2. Đẩy thẳng trọn gói bộ bản ghi lên Firestore
      await FirebaseFirestore.instance.collection('marketplace').add({
        'title': title,
        'price': price,
        'description': desc,
        'image_url': base64Image, // Lưu chuỗi Base64 cực dài thay vì tên file rác cũ
        'username': widget.userId.trim(),
        'fullname': 'Cư dân VKU', // Tự động gán tên hiển thị mặc định
        'status': 'available',
        'created_at': DateTime.now().toString().substring(0, 19),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Đã đăng bán sản phẩm thành công lên chợ KTX!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi hệ thống mây: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("ĐĂNG BÁN MÓN ĐỒ CŨ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: vkuBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: vkuOrange.withOpacity(0.5))),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: vkuOrange), SizedBox(height: 10), Text("Bấm vào để chọn ảnh món đồ")]),
              ),
            ),
            const SizedBox(height: 20),
            _buildInput(controller: _titleController, hint: "Tên sản phẩm (Ví dụ: Tủ lạnh mini)..."),
            const SizedBox(height: 15),
            _buildInput(controller: _priceController, hint: "Giá bán (đ)...", isNumber: true),
            const SizedBox(height: 15),
            _buildInput(controller: _descController, hint: "Mô tả tình trạng món đồ...", maxLines: 4),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: vkuBlue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("ĐĂNG BÁN NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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