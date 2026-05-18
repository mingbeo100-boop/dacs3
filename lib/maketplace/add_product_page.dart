import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  final String userId;
  const AddProductPage({super.key, required this.userId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // --- HỆ MÀU ĐỒNG BỘ VKU & SAND ---
  static const vkuBlue = Color(0xFF072C6C);     // Xanh dương đậm VKU
  static const vkuOrange = Color(0xFFFF8C00);   // Cam đặc trưng làm điểm nhấn
  static const sandBg = Color(0xFFF5E1C5);      // Nền màu Cát đậm
  static const cardBg = Color(0xFFFFF8F0);      // Màu kem nhạt cho ô nhập
  static const darkText = Color(0xFF263238);    // Xám đen

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _submitData() async {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và giá món đồ!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Nhớ kiểm tra lại IP của bạn nhé
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.60.56.48/dacs3/add_product.php"),
      );

      request.fields['user_id'] = widget.userId;
      request.fields['title'] = _titleController.text.trim();
      request.fields['price'] = _priceController.text.trim();
      request.fields['description'] = _descController.text.trim();

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("✨ Đã đăng tin thành công!"),
                backgroundColor: vkuBlue,
                behavior: SnackBarBehavior.floating
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw data['message'] ?? "Lỗi server";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg, // Nền cát đồng bộ
      appBar: AppBar(
        title: const Text("ĐĂNG TIN BÁN ĐỒ",
            style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: vkuBlue),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Hình ảnh sản phẩm"),

            // --- KHUNG CHỌN ẢNH TÔNG SAND/BLUE ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: vkuBlue.withOpacity(0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: _image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: vkuBlue.withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo_rounded, size: 40, color: vkuBlue),
                    ),
                    const SizedBox(height: 12),
                    const Text("Thêm ảnh món đồ của bạn",
                        style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w600)),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_image!, fit: BoxFit.cover),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _image = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- CÁC Ô NHẬP LIỆU MÀU KEM ---
            _buildLabel("Tên món đồ"),
            _buildTextField(_titleController, "Ví dụ: Áo khoác VKU mới 99%", Icons.shopping_bag_outlined),

            const SizedBox(height: 20),
            _buildLabel("Giá bán (VNĐ)"),
            _buildTextField(_priceController, "Ví dụ: 150000", Icons.payments_outlined, isNumber: true),

            const SizedBox(height: 20),
            _buildLabel("Mô tả chi tiết"),
            _buildTextField(_descController, "Nhập lý do bán, tình trạng món đồ...", Icons.edit_note_rounded, maxLines: 4),

            const SizedBox(height: 35),

            // --- NÚT ĐĂNG TIN MÀU XANH VKU ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vkuBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: vkuBlue.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "ĐĂNG BÀI NGAY",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: vkuBlue)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: darkText, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: vkuBlue.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: vkuOrange, size: 24),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: vkuBlue.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: vkuOrange, width: 2),
        ),
      ),
    );
  }
}