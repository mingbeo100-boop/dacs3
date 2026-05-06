import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final Map product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  bool _isLoading = false;
  File? _newImage;
  final picker = ImagePicker();

  // --- HỆ MÀU VÀNG CAM VKU (CHỈ CHỈNH MÀU) ---
  static const Color vkuBlue = Color(0xFF072C6C);
  static const Color vkuOrange = Color(0xFFFF9800);
  static const Color vkuOrangeDark = Color(0xFFE65100);
  static const Color sandBg = Color(0xFFF5E1C5);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product['title']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _descController = TextEditingController(text: widget.product['description']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateData() async {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và giá món đồ!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        // GIỮ NGUYÊN IP VÀ ĐƯỜNG DẪN CỦA ÔNG
        Uri.parse("http://10.0.2.2/dacs3/update_product.php"),
      );

      request.fields['id'] = widget.product['id'].toString();
      request.fields['title'] = _titleController.text.trim();
      request.fields['price'] = _priceController.text.trim();
      request.fields['description'] = _descController.text.trim();

      if (_newImage != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _newImage!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Cập nhật thành công!"),
                backgroundColor: vkuOrangeDark,
                behavior: SnackBarBehavior.floating,
              )
          );
          Navigator.pop(context, true);
        }
      } else {
        throw data['message'] ?? "Lỗi không xác định";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // GIỮ NGUYÊN CÁCH LẤY ẢNH CŨ CỦA ÔNG
    String oldImageUrl = "http://10.0.2.2/dacs3/uploads/${widget.product['image_url']}";

    return Scaffold(
      backgroundColor: sandBg, // Chỉ đổi màu nền
      appBar: AppBar(
        title: const Text("Chỉnh sửa sản phẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: vkuBlue, // Đổi màu AppBar
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Hình ảnh sản phẩm"),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white, // Khung ảnh trắng cho rõ
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: vkuOrange.withOpacity(0.3), width: 1.5),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: _newImage == null
                          ? (widget.product['image_url'] != null && widget.product['image_url'] != ""
                          ? Image.network(
                        oldImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                      )
                          : const Center(child: Icon(Icons.add_a_photo_outlined, size: 50, color: vkuOrange)))
                          : Image.file(_newImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ),
                    Positioned(
                      bottom: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: vkuOrange, // Icon chọn ảnh màu Cam
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_enhance_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildLabel("Tên sản phẩm"),
            _buildTextField(_titleController, "Cập nhật tên mới...", Icons.title_rounded),

            const SizedBox(height: 20),
            _buildLabel("Giá bán mới (VNĐ)"),
            _buildTextField(_priceController, "Nhập giá đã giảm...", Icons.local_offer_outlined, isNumber: true),

            const SizedBox(height: 20),
            _buildLabel("Mô tả tình trạng hiện tại"),
            _buildTextField(_descController, "Sửa lại mô tả...", Icons.edit_note_rounded, maxLines: 4),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vkuOrangeDark, // Nút lưu màu Cam đậm
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: vkuBlue));
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: vkuBlue.withOpacity(0.7)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: vkuOrange),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: vkuOrange.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: vkuOrange, width: 2),
        ),
      ),
    );
  }
}