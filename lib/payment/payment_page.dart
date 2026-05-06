import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String roomName;
  final int month;
  // QUAN TRỌNG: Thêm invoiceId để PHP biết chính xác dòng nào cần Update
  final String invoiceId;

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

  // --- HÀM GỬI DỮ LIỆU ĐÃ SỬA LỖI ---
  Future<void> _submitPayment() async {
    if (_image == null) {
      _showSnackBar("Vui lòng đính kèm ảnh biên lai!", Colors.red);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // 1. Kiểm tra lại IP máy tính của ông (quan trọng nhất)
      var uri = Uri.parse("http://192.168.1.191/dacs3/upload_receipt.php");
      var request = http.MultipartRequest('POST', uri);

      // 2. Gửi các field khớp với file PHP đã viết
      request.fields['invoice_id'] = widget.invoiceId; // Dùng ID để update chính xác
      request.fields['room_id'] = widget.roomName;
      request.fields['month'] = widget.month.toString();

      // Đính kèm file ảnh
      request.files.add(await http.MultipartFile.fromPath(
          'receipt_image',
          _image!.path
      ));

      // 3. Thực hiện gửi
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Debug để ông xem lỗi trong Console của VS Code
      debugPrint("Server Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          _showSnackBar("Gửi minh chứng thành công! Chờ Admin duyệt.", Colors.green);
          if (mounted) Navigator.pop(context, true); // Trả về true để reload trang chủ
        } else {
          _showSnackBar(result['message'] ?? "Lỗi từ Server", Colors.red);
        }
      } else {
        _showSnackBar("Lỗi kết nối Server: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      debugPrint("Lỗi nghiêm trọng: $e");
      _showSnackBar("Không thể kết nối đến máy chủ!", Colors.red);
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
          Image.network(url, height: 350, fit: BoxFit.contain),
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