import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng Firestore để update/delete
import 'package:firebase_storage/firebase_storage.dart'; // Sử dụng Storage để up ảnh mới
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final Map product; // Nhận cục data của món hàng (đã có trường 'id' document)
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

  // --- HỆ MÀU VÀNG CAM VKU ---
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

  // --- LOGIC MỚI: CẬP NHẬT TRỰC TIẾP LÊN CLOUD FIRESTORE ---
  Future<void> _updateData() async {
    final String title = _titleController.text.trim();
    final String price = _priceController.text.trim();
    final String desc = _descController.text.trim();

    if (title.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và giá món đồ!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mặc định giữ nguyên đường dẫn link ảnh online cũ
      String finalImageUrl = widget.product['image_url'] ?? "";

      // Nếu người dùng chọn ảnh mới, up đè lên Firebase Storage để lấy URL mới
      if (_newImage != null) {
        String fileName = "market_${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference storageRef = FirebaseStorage.instance.ref().child("marketplace/$fileName");

        UploadTask uploadTask = storageRef.putFile(_newImage!);
        TaskSnapshot snapshot = await uploadTask;
        finalImageUrl = await snapshot.ref.getDownloadURL();
      }

      // Tiến hành update trực tiếp document cụ thể dựa trên ID bài đăng
      await FirebaseFirestore.instance
          .collection('marketplace')
          .doc(widget.product['id'].toString())
          .update({
        'title': title,
        'price': price,
        'description': desc,
        'image_url': finalImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Cập nhật thông tin sản phẩm thành công!"),
              backgroundColor: vkuOrangeDark,
              behavior: SnackBarBehavior.floating,
            )
        );
        Navigator.pop(context, true); // Trả về true để lưới chợ tự refresh dữ liệu
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi hệ thống: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- TÍNH NĂNG BỔ SUNG: XOÁ BÀI ĐĂNG TRỰC TIẾP TRÊN FIRESTORE ---
  Future<void> _deleteProduct() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa?", style: TextStyle(fontWeight: FontWeight.bold, color: vkuBlue)),
        content: const Text("Bạn có chắc chắn muốn gỡ mặt hàng thanh lý này khỏi chợ KTX không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Đóng hộp thoại
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance
                    .collection('marketplace')
                    .doc(widget.product['id'].toString())
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("🗑️ Đã gỡ sản phẩm thành công!"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                  );
                  Navigator.pop(context, true); // Quay về trang chợ tổng
                }
              } catch (e) {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("XÓA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đã cấu hình lấy trực tiếp link URL online lưu từ Firebase Storage
    String currentImageUrl = widget.product['image_url'] ?? "";

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("Chỉnh sửa sản phẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: vkuBlue,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Nút xoá bài đăng gán lên góc phải cực kỳ tiện lợi
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
            onPressed: _isLoading ? null : _deleteProduct,
          ),
          const SizedBox(width: 8),
        ],
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: vkuOrange.withOpacity(0.3), width: 1.5),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: _newImage == null
                          ? (currentImageUrl.startsWith('http')
                          ? Image.network(
                        currentImageUrl,
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
                        decoration: const BoxDecoration(
                          color: vkuOrange,
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
                  backgroundColor: vkuOrangeDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      style: const TextStyle(fontWeight: FontWeight.bold, color: vkuBlue),
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