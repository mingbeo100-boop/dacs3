import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để lắng nghe chỉ số điện realtime
import 'package:fl_chart/fl_chart.dart';
import '../payment/payment_page.dart';

class StudentPowerUsagePage extends StatefulWidget {
  final dynamic user;
  const StudentPowerUsagePage({super.key, required this.user});

  @override
  State<StudentPowerUsagePage> createState() => _StudentPowerUsagePageState();
}

class _StudentPowerUsagePageState extends State<StudentPowerUsagePage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);

  String roomName = "N/A";

  @override
  void initState() {
    super.initState();
    roomName = widget.user['room_id']?.toString() ?? "N/A";
  }

  @override
  Widget build(BuildContext context) {
    // TẠO LUỒNG LẮNG NGHE DỮ LIỆU ĐIỆN THỜI GIAN THỰC (REALTIME STREAM)
    // Quét trong bảng 'power_usages' lấy ra hóa đơn điện mới nhất thuộc phòng này
    final Stream<QuerySnapshot> _powerStream = FirebaseFirestore.instance
        .collection('power_usages')
        .where('room_id', isEqualTo: roomName.trim())
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots();

    return Scaffold(
      backgroundColor: sandBg,
      body: StreamBuilder<QuerySnapshot>(
        stream: _powerStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu điện: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: vkuOrange));
          }

          // Khởi tạo các biến cục bộ hứng data rỗng dự phòng nếu database chưa cấu hình tháng này
          double totalKwh = 0.0;
          double displayAmount = 0.0;
          String invoiceId = "";
          int paymentStatus = 0; // 0: Chưa đóng, 1: Chờ duyệt, 2: Đã đóng
          List<dynamic> devices = [];
          List<dynamic> recommendations = [];
          List<FlSpot> chartSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 0.0));

          // Nếu tìm thấy hóa đơn điện của phòng trên Firestore
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            var doc = snapshot.data!.docs.first;
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            invoiceId = doc.id;

            totalKwh = double.tryParse(data['total_kwh'].toString()) ?? 0.0;
            displayAmount = double.tryParse(data['amount'].toString()) ?? 0.0;
            devices = data['device_breakdown'] ?? [];
            recommendations = data['recommendations'] ?? [];

            // Xử lý map trạng thái thanh toán linh hoạt chuỗi/số
            String statusStr = data['status'].toString().toLowerCase();
            if (statusStr == "completed" || statusStr == "2" || statusStr == "true") paymentStatus = 2;
            else if (statusStr == "processing" || statusStr == "1") paymentStatus = 1;
            else paymentStatus = 0;

            // Đọc mảng lịch sử 7 ngày để vẽ đồ thị xu hướng
            List<dynamic> history = data['seven_day_history'] ?? [0,0,0,0,0,0,0];
            chartSpots.clear();
            for (int i = 0; i < history.length; i++) {
              chartSpots.add(FlSpot(i.toDouble(), double.tryParse(history[i].toString()) ?? 0.0));
            }
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainUsageCard(displayAmount, totalKwh, paymentStatus, invoiceId),
                      _buildRecommendationBox(recommendations),
                      const SizedBox(height: 30),
                      _buildSectionTitle("XU HƯỚNG TIÊU THỤ (7 NGÀY)"),
                      _buildLineChart(chartSpots),
                      const SizedBox(height: 30),
                      _buildSectionTitle("PHÂN TÍCH THIẾT BỊ"),
                      _buildDeviceBreakdown(devices),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: vkuBlue,
      centerTitle: true,
      elevation: 0,
      expandedHeight: 80,
      title: Text("ĐIỆN NĂNG PHÒNG $roomName",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMainUsageCard(double cost, double totalKwh, int paymentStatus, String invoiceId) {
    String btnText = paymentStatus == 2 ? "ĐÃ THANH TOÁN" : (paymentStatus == 1 ? "ĐANG CHỜ DUYỆT..." : "THANH TOÁN NGAY");
    Color btnColor = paymentStatus == 2 ? Colors.green : (paymentStatus == 1 ? Colors.grey : vkuOrange);

    return Container(
      padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: vkuBlue, borderRadius: BorderRadius.circular(35)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Điện năng tháng này", style: TextStyle(color: Colors.white70, fontSize: 12)), Icon(paymentStatus == 2 ? Icons.check_circle : Icons.bolt, color: vkuOrange)]),
        const SizedBox(height: 15),
        Row(children: [Text(totalKwh.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900)), const Text(" kWh", style: TextStyle(color: Colors.white70))]),
        const Divider(color: Colors.white24, height: 30),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Thành tiền:", style: TextStyle(color: Colors.white70)), Text("${cost.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} VNĐ", style: TextStyle(color: btnColor, fontSize: 22, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 25),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
          onPressed: paymentStatus != 0 ? null : () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PaymentPage(
                        amount: cost,
                        roomName: roomName,
                        month: DateTime.now().month,
                        invoiceId: invoiceId
                    )
                )
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: btnColor, disabledBackgroundColor: btnColor.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: Text(btnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        )),
      ]),
    );
  }

  Widget _buildRecommendationBox(List<dynamic> recommendations) {
    if (recommendations.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 25), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: vkuOrange.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.tips_and_updates_rounded, color: vkuOrange, size: 20), SizedBox(width: 10), Text("GỢI Ý TIẾT KIỆM AI", style: TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 12))]),
          const SizedBox(height: 12),
          ...recommendations.map((msg) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [const Text("• ", style: TextStyle(color: vkuOrange, fontWeight: FontWeight.bold)), Expanded(child: Text(msg.toString(), style: const TextStyle(fontSize: 13, color: vkuBlue, fontWeight: FontWeight.w500)))]),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(t, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 12)));

  Widget _buildLineChart(List<FlSpot> spots) => Container(
      height: 180, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25)),
      child: LineChart(
          LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: vkuOrange,
                    barWidth: 4,
                    dotData: const FlDotData(show: false)
                )
              ]
          )
      )
  );

  Widget _buildDeviceBreakdown(List<dynamic> devices) => Column(children: devices.map((d) {
    String name = d['name']?.toString() ?? "Thiết bị";
    String n = name.toLowerCase();
    IconData icon = n.contains("điều hòa") ? Icons.ac_unit : (n.contains("quạt") ? Icons.cyclone : (n.contains("đèn") ? Icons.lightbulb : Icons.bolt));
    Color color = n.contains("điều hòa") ? Colors.blue : (n.contains("quạt") ? Colors.green : (n.contains("đèn") ? Colors.amber : Colors.red));
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22)), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 15), Text(name, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.bold)), const Spacer(), Text(d['percent']?.toString() ?? "0%", style: TextStyle(color: color, fontWeight: FontWeight.w900))]));
  }).toList());
}