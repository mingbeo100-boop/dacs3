import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để duyệt hóa đơn Realtime

class AdminVerifyPaymentPage extends StatefulWidget {
  const AdminVerifyPaymentPage({super.key});

  @override
  State<AdminVerifyPaymentPage> createState() => _AdminVerifyPaymentPageState();
}

class _AdminVerifyPaymentPageState extends State<AdminVerifyPaymentPage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const darkText = Color(0xFF263238);

  // --- LOGIC MỚI: PHÊ DUYỆT THANH TOÁN TRỰC TIẾP TRÊN CLOUD FIRESTORE ---
  Future<void> _approveInvoice(String docId, String roomId) async {
    try {
      // 1. Cập nhật trạng thái hóa đơn điện thành 'completed' (Đã đóng tiền)
      await FirebaseFirestore.instance
          .collection('power_usages')
          .doc(docId)
          .update({
        "status": "completed",
        "approved_at": DateTime.now().toString().substring(0, 19),
      });

      // 2. TỰ ĐỘNG CẬP NHẬT TRẠNG THÁI 'is_paid = true' CHO TẤT CẢ SINH VIÊN THUỘC PHÒNG ĐÓ
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('room_id', isEqualTo: roomId)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in usersSnapshot.docs) {
        batch.update(doc.reference, {"is_paid": true});
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Đã phê duyệt thanh toán & cập nhật trạng thái phòng thành công!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
    } catch (e) {
      debugPrint("Lỗi duyệt hóa đơn trên đám mây: $e");
    }
  }

  // --- TIỆN ÍCH GIỮ NGUYÊN ---
  String _formatMoney(dynamic amount) {
    double value = double.tryParse(amount.toString()) ?? 0;
    return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.9),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: url.startsWith('http')
                    ? Image.network(url, fit: BoxFit.contain)
                    : const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            top: 40, right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 35),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- GIAO DIỆN CHI TIẾT ĐỐI SOÁT ---
  void _showDetailDialog(dynamic item) {
    String receiptUrl = item['receipt_image'] ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: vkuBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text("ĐỐI SOÁT PHÒNG ${item['room_id']}",
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("MINH CHỨNG CHUYỂN KHOẢN ONLINE",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: vkuOrange, letterSpacing: 1.2)),
                    const SizedBox(height: 15),

                    // Đọc link URL online lưu trực tiếp từ Firebase Storage
                    GestureDetector(
                      onTap: () => _showFullScreenImage(receiptUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: receiptUrl.startsWith('http')
                              ? Image.network(
                            receiptUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: vkuOrange)));
                            },
                            errorBuilder: (context, error, stackTrace) => _imageErrorWidget(),
                          )
                              : _imageErrorWidget(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("SỐ TIỀN KHỚP:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkText)),
                          Text("${_formatMoney(item['amount'])} VNĐ",
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.green.withOpacity(0.3),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _approveInvoice(item['id'].toString(), item['room_id'].toString());
                      },
                      child: const Text("XÁC NHẬN KHỚP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageErrorWidget() {
    return Container(
      height: 200, width: double.infinity,
      color: Colors.grey.shade100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 40),
          Text("Không tìm thấy ảnh biên lai mây", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // --- BUILD CHÍNH LẮNG NGHE REALTIME ---
  @override
  Widget build(BuildContext context) {
    // STREAM LẮNG NGHE REALTIME CÁC HÓA ĐƠN ĐANG CHỜ DUYỆT (STATUS = PROCESSING)
    final Stream<QuerySnapshot> _pendingStream = FirebaseFirestore.instance
        .collection('power_usages')
        .where('status', isEqualTo: 'processing')
        .snapshots();

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        title: const Text("PHÊ DUYỆT THANH TOÁN",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: vkuBlue,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _pendingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Lỗi tải dữ liệu biên lai đám mây."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: vkuOrange));
          }

          // Phân tách dữ liệu tài liệu Firestore sang List Map
          List<dynamic> pendingInvoices = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Lưu document ID để thực hiện lệnh update
            return data;
          }).toList();

          return pendingInvoices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: pendingInvoices.length,
            itemBuilder: (context, index) {
              return _buildInvoiceCard(pendingInvoices[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, size: 80, color: vkuBlue.withOpacity(0.1)),
              const SizedBox(height: 15),
              const Text("Tuyệt vời! Không có biên lai chờ duyệt",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(item),
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: vkuOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.receipt_long_rounded, color: vkuOrange, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phòng ${item['room_id']}",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 15)),
                    Text(item['created_at'] != null ? "Ngày chốt: ${item['created_at'].toString().substring(0, 10)}" : "Hóa đơn KTX",
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatMoney(item['amount']),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: vkuOrange, fontSize: 15)),
                  const Text("VNĐ", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}