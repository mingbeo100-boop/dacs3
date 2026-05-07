import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminVerifyPaymentPage extends StatefulWidget {
  const AdminVerifyPaymentPage({super.key});

  @override
  State<AdminVerifyPaymentPage> createState() => _AdminVerifyPaymentPageState();
}

class _AdminVerifyPaymentPageState extends State<AdminVerifyPaymentPage> {
  final String baseUrl = "http://192.168.4.21/dacs3";
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const darkText = Color(0xFF263238);

  List<dynamic> pendingInvoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingInvoices();
  }

  // --- LOGIC API ---
  Future<void> _fetchPendingInvoices() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_pending_invoices.php"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            pendingInvoices = data['data'] ?? [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Lỗi tải biên lai: $e");
    }
  }

  Future<void> _approveInvoice(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/approve_invoice.php"),
        body: {"invoice_id": id},
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success']) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Đã phê duyệt thanh toán thành công!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(20),
            ),
          );
          _fetchPendingInvoices();
        }
      }
    } catch (e) {
      debugPrint("Lỗi duyệt: $e");
    }
  }

  // --- TIỆN ÍCH ---
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
                child: Image.network(url, fit: BoxFit.contain),
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
            // Header Dialog
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
            // Nội dung
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("MINH CHỨNG CHUYỂN KHOẢN",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: vkuOrange, letterSpacing: 1.2)),
                    const SizedBox(height: 15),

                    // Ảnh biên lai (Click để zoom)
                    GestureDetector(
                      onTap: () => _showFullScreenImage("$baseUrl/uploads/bienlai/${item['evidence_img']}"),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            "$baseUrl/uploads/bienlai/${item['evidence_img']}",
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: vkuOrange)));
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150, width: double.infinity,
                              color: Colors.grey.shade100,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 40),
                                  Text("Không tìm thấy ảnh biên lai", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Box Số tiền nổi bật
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
            // Actions
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
                        _approveInvoice(item['id'].toString());
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

  // --- BUILD CHÍNH ---
  @override
  Widget build(BuildContext context) {
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
      body: RefreshIndicator(
        onRefresh: _fetchPendingInvoices,
        color: vkuOrange,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: vkuOrange))
            : pendingInvoices.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: pendingInvoices.length,
          itemBuilder: (context, index) {
            final item = pendingInvoices[index];
            return _buildInvoiceCard(item);
          },
        ),
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
                    Text("Tháng ${item['billing_month']}/${item['billing_year']}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${_formatMoney(item['amount'])}",
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