import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để update trạng thái hóa đơn
import 'package:firebase_storage/firebase_storage.dart'; // Sử dụng Storage để lưu trữ ảnh biên lai online

class PaymentPage extends StatefulWidget {
  final double amount;
  final String roomName;
  final int month;
  final String invoiceId; // ID của document hóa đơn tiền điện nằm trong collection 'power_usages'

  const PaymentPage({
    super.key,
    required this.amount,
    required this.roomName,
    required this.month,
    required this.invoiceId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);

  File? _image;
  final picker = ImagePicker();
  bool isSubmitting = false;

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // --- LOGIC MỚI: TẢI BIÊN LAI LÊN STORAGE VÀ CẬP NHẬT TRẠNG THÁI HOÁ ĐƠN LÊN FIRESTORE ---
  Future<void> _submitPayment() async {
    if (_image == null) {
      _showSnackBar("Vui lòng đính kèm ảnh biên lai!", Colors.red);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      String receiptUrl = "";

      // 1. Tải ảnh biên lai lên Firebase Storage
      String fileName = "receipt_${widget.invoiceId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("receipts/$fileName");

      UploadTask uploadTask = storageRef.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      receiptUrl = await snapshot.ref.getDownloadURL(); // Lấy đường dẫn link ảnh online từ Google Server

      // 2. Cập nhật trực tiếp vào document hoá đơn cụ thể trong collection 'power_usages' (hoặc collection quản lý hóa đơn của bạn)
      await FirebaseFirestore.instance
          .collection('power_usages')
          .doc(widget.invoiceId)
          .update({
        "receipt_image": receiptUrl,     // Lưu link ảnh minh chứng để Admin vào kiểm tra
        "status": "processing",           // Chuyển trạng thái sang Đang xử lý / Chờ duyệt (processing)
        "submitted_at": DateTime.now().toString().substring(0, 19), // Ghi lại thời gian nộp minh chứng
      });

      _showSnackBar("Gửi minh chứng chuyển khoản thành công! Chờ Admin duyệt.", Colors.green);

      if (mounted) {
        Navigator.pop(context, true); // Trả về true để màn hình trước tự động reload trạng thái
      }

    } catch (e) {
      debugPrint("Lỗi thanh toán đám mây: $e");
      _showSnackBar("Lỗi hệ thống: Không thể gửi minh chứng!", Colors.red);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    String description = "PHONG ${widget.roomName} T${widget.month} DIEN";
    String qrUrl = "https://img.vietqr.io/image/VPBank-0796727753-compact2.png?amount=${widget.amount.toInt()}&addInfo=$description&accountName=TRAN NHAT LONG";

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        backgroundColor: vkuBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text("XÁC NHẬN THANH TOÁN", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildQRCard(qrUrl, description),
            const SizedBox(height: 25),
            _buildImagePicker(),
            const SizedBox(height: 30),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCard(String url, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          const Text("QUÉT MÃ ĐỂ CHUYỂN KHOẢN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          Image.network(url, height: 350, fit: BoxFit.contain, errorBuilder: (c, e, s) => Container(height: 350, color: Colors.grey[100], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey))),
          const Divider(height: 30),
          Text("${_formatPrice(widget.amount)} VNĐ", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: vkuBlue)),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: getImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("  TẢI BIÊN LAI TẠI ĐÂY:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: vkuBlue)),
          const SizedBox(height: 8),
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: vkuBlue.withOpacity(0.1))),
            child: _image != null
                ? ClipRRect(borderRadius: BorderRadius.circular(19), child: Image.file(_image!, fit: BoxFit.cover))
                : const Icon(Icons.add_a_photo_rounded, size: 40, color: vkuOrange),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: vkuBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: isSubmitting ? null : _submitPayment,
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("XÁC NHẬN ĐÃ CHUYỂN TIỀN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}