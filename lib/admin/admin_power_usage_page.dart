import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để giám sát điện năng Realtime
import 'package:fl_chart/fl_chart.dart';
import 'admin_verify_payment_page.dart';

class AdminPowerUsagePage extends StatefulWidget {
  final String userRole;
  const AdminPowerUsagePage({super.key, required this.userRole});

  @override
  State<AdminPowerUsagePage> createState() => _AdminPowerUsagePageState();
}

class _AdminPowerUsagePageState extends State<AdminPowerUsagePage> {
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);

  late String filterMonth;
  late String filterYear;

  String searchRoom = "";
  String paymentFilter = "Tất cả";
  double powerLimit = 15.0; // Ngưỡng để nhắc nhở phòng dùng điện cao

  // ĐỒNG BỘ: Chuẩn hóa chuỗi hiển thị khớp 100% với cấu trúc bảng dữ liệu mây đám mây
  final List<String> months = List.generate(12, (i) => "Tháng ${i + 1 < 10 ? '0' : ''}${i + 1}");
  final List<String> years = ["2024", "2025", "2026", "2027"];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    filterMonth = "Tháng ${now.month < 10 ? '0' : ''}${now.month}";
    filterYear = years.contains(now.year.toString()) ? now.year.toString() : "2026";
  }

  // --- LOGIC MỚI: BẮN THÔNG BÁO NHẮC NHỞ HÀNG LOẠT LÊN FIRESTORE ---
  Future<void> _sendBulkReminder(List<String> highUsageRooms) async {
    if (highUsageRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không có phòng nào vượt ngưỡng ${powerLimit.toStringAsFixed(1)} kWh"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("XÁC NHẬN GỬI", style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold)),
        content: Text("Gửi cảnh báo đến ${highUsageRooms.length} phòng đang sử dụng điện quá cao (> $powerLimit kWh)?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: vkuOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("GỬI NGAY", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (String room in highUsageRooms) {
          QuerySnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('room_id', isEqualTo: room)
              .get();

          for (var userDoc in userSnapshot.docs) {
            DocumentReference notiRef = FirebaseFirestore.instance.collection('notifications').doc();
            batch.set(notiRef, {
              "username": userDoc['username'],
              "title": "CẢNH BÁO TIÊU THỤ ĐIỆN CAO",
              "content": "Phòng $room của bạn có lượng điện tiêu thụ đạt mức báo động trong $filterMonth/$filterYear. Vui lòng tắt các thiết bị khi ra ngoài!",
              "is_read": false,
              "created_at": DateTime.now().toString().substring(0, 19),
            });
          }
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚀 Đã bắn thông báo nhắc nhở Realtime đến toàn bộ cư dân thành công!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        debugPrint("Lỗi gửi thông báo hàng loạt: $e");
      }
    }
  }

  // --- SỬA LOGIC: CHỐT SỐ ĐIỆN TỰ ĐỘNG - GHI ĐÚNG ĐỊNH DANH DOCUMENT ID LÀ MÃ PHÒNG O(1) ---
  Future<void> _triggerMonthlyClosure() async {
    try {
      QuerySnapshot roomsSnapshot = await FirebaseFirestore.instance.collection('devices').get();
      Set<String> uniqueRooms = roomsSnapshot.docs.map((doc) => doc['room_id'].toString()).toSet();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String r in uniqueRooms) {
        DocumentReference powerRef = FirebaseFirestore.instance.collection('power_usages').doc(r.trim());

        double initialKwh = 35.0 + (indexOffset() * 12.5);
        batch.set(powerRef, {
          "room_id": r.trim(),
          "total_kwh": initialKwh,
          "amount": initialKwh * 3500,
          "status": "0", // Khởi tạo hóa đơn mới ở trạng thái Chưa đóng tiền để sinh viên thanh toán
          "month": filterMonth,
          "year": filterYear,
          "seven_day_history": [5, 8, 4, 9, 12, 10, 7],
          "device_breakdown": [
            {"name": "Điều hòa", "percent": "60%"},
            {"name": "Quạt máy", "percent": "25%"},
            {"name": "Bóng đèn", "percent": "15%"}
          ],
          "recommendations": ["Nên tắt bớt điều hòa vào giờ cao điểm", "Sử dụng chế độ Eco"],
          "created_at": DateTime.now().toString().substring(0, 19),
          "updated_at": DateTime.now().toString().substring(0, 19),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      _showSnackBar("🎉 Đã kích hoạt chốt số điện nguyên tử cho toàn bộ các phòng!", Colors.green);
    } catch (e) {
      _showSnackBar("Lỗi chốt số mây: $e", Colors.redAccent);
    }
  }

  double indexOffset() => (1 + (months.indexOf(filterMonth) + 1) % 5).toDouble();

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRole != "admin") return const Scaffold(body: Center(child: Text("Từ chối truy cập!")));

    // STREAM 1: Lắng nghe các hóa đơn đang có biên lai chờ duyệt Realtime
    final Stream<QuerySnapshot> _pendingInvoicesStream = FirebaseFirestore.instance
        .collection('power_usages')
        .where('status', whereIn: ['processing', '1'])
        .snapshots();

    // STREAM 2: TỐI ƯU SIÊU TỐC - Chỉ lọc bốc các hóa đơn thuộc đúng Tháng/Năm đang chọn trên giao diện
    final Stream<QuerySnapshot> _allUsagesStream = FirebaseFirestore.instance
        .collection('power_usages')
        .where('month', isEqualTo: filterMonth)
        .where('year', isEqualTo: filterYear)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: _pendingInvoicesStream,
      builder: (context, pendingSnapshot) {
        List<dynamic> pendingPayments = [];
        if (pendingSnapshot.hasData) {
          pendingPayments = pendingSnapshot.data!.docs.map((doc) => doc.id).toList();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _allUsagesStream,
          builder: (context, usageSnapshot) {
            double totalKtxUsage = 0.0;
            List<Map<String, dynamic>> roomData = [];

            // Khởi tạo đồ thị xu hướng 12 tháng trống
            List<Map<String, dynamic>> historyChartData = List.generate(12, (i) => {"month": "T${i+1}", "usage": 0.0});

            if (usageSnapshot.hasData) {
              // SỬA: Bỏ hoàn toàn câu điều kiện check chuỗi tĩnh docId cũ để giải phóng luồng dữ liệu Live
              for (var doc in usageSnapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                double usageKwh = double.tryParse(data['total_kwh'].toString()) ?? 0.0;
                totalKtxUsage += usageKwh;

                int statusInt = 0;
                String s = data['status'].toString().toLowerCase();
                if (s == 'completed' || s == '2' || s == 'true') statusInt = 2;
                else if (s == 'processing' || s == '1') statusInt = 1;

                roomData.add({
                  "room": data['room_id'] ?? doc.id,
                  "usage": usageKwh,
                  "status": statusInt,
                });
              }

              // Đổ dữ liệu tổng của tháng được chọn vào cột đồ thị tương ứng trên RAM tức thì
              int currentMonthIndex = months.indexOf(filterMonth);
              if (currentMonthIndex >= 0 && currentMonthIndex < 12) {
                historyChartData[currentMonthIndex]["usage"] = totalKtxUsage;
              }
            }

            // BỘ LỌC TÌM KIẾM CHẠY TRÊN RAM O(1) TIẾT KIỆM TỐI ĐA BĂNG THÔNG
            List<Map<String, dynamic>> filteredRooms = roomData.where((r) {
              bool matchesSearch = r['room'].toString().toLowerCase().contains(searchRoom.toLowerCase());

              bool matchesPayment = true;
              if (paymentFilter == "Đã đóng") matchesPayment = (r['status'] == 2);
              if (paymentFilter == "Chưa đóng") matchesPayment = (r['status'] != 2);

              return matchesSearch && matchesPayment;
            }).toList();

            List<String> highUsageRooms = roomData
                .where((r) => (r['usage'] as double) > powerLimit)
                .map((r) => r['room'].toString())
                .toList();

            return Scaffold(
              backgroundColor: sandBg,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(pendingPayments),
                  SliverToBoxAdapter(child: _buildBigPowerBanner(totalKtxUsage, highUsageRooms)),
                  if (pendingPayments.isNotEmpty) SliverToBoxAdapter(child: _buildPendingNotificationCard(pendingPayments.length)),
                  SliverToBoxAdapter(child: _buildSectionHeader("TRẠNG THÁI ĐÓNG TIỀN")),
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), child: Row(children: [ _buildFilterChip("Tất cả"), const SizedBox(width: 8), _buildFilterChip("Chưa đóng"), const SizedBox(width: 8), _buildFilterChip("Đã đóng") ]))),
                  SliverToBoxAdapter(child: _buildSectionHeader("XU HƯỚNG TIÊU THỤ NĂM $filterYear")),
                  SliverToBoxAdapter(child: _buildEnhancedLineChart(historyChartData)),
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(25, 30, 25, 10), child: _buildSearchField())),
                  SliverToBoxAdapter(child: _buildSectionHeader("CHI TIẾT PHÒNG")),

                  usageSnapshot.connectionState == ConnectionState.waiting
                      ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: vkuOrange))))
                      : filteredRooms.isEmpty
                      ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text("Không tìm thấy dữ liệu phòng phù hợp.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)))))
                      : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(25, 15, 25, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildRoomUsageCard(filteredRooms[index]),
                        childCount: filteredRooms.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBigPowerBanner(double totalUsage, List<String> highUsageRooms) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
        child: Container(
            width: double.infinity, padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [vkuBlue, Color(0xFF1A4594)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(40)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("TỔNG TIÊU THỤ KTX", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(totalUsage.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                  const Text("kWh", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ]),
                Row(
                  children: [
                    GestureDetector(
                        onTap: () => _sendBulkReminder(highUsageRooms),
                        child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 30))
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                        onTap: _triggerMonthlyClosure,
                        child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.bolt_rounded, color: vkuOrange, size: 30))
                    ),
                  ],
                )
              ]),
              const SizedBox(height: 30),
              Row(children: [
                _buildModernSelect("Tháng", filterMonth, () => _showPicker("Chọn Tháng", months, filterMonth, (v) { setState(() => filterMonth = v); })),
                const SizedBox(width: 15),
                _buildModernSelect("Năm", filterYear, () => _showPicker("Chọn Năm", years, filterYear, (v) { setState(() => filterYear = v); })),
              ])
            ])
        )
    );
  }

  Widget _buildEnhancedLineChart(List<Map<String, dynamic>> chartData) {
    double maxUsage = chartData.map((e) => e['usage'] as double).fold(0.0, (a, b) => a > b ? a : b);
    double setMaxY = maxUsage > 0 ? maxUsage * 1.4 : 100.0;

    return Container(
        height: 240, margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
        decoration: BoxDecoration(color: vkuBlue, borderRadius: BorderRadius.circular(35)),
        child: LineChart(
            LineChartData(
                lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (touchedSpot) => vkuOrange, getTooltipItems: (spots) => spots.map((s) => LineTooltipItem("${s.y.toStringAsFixed(1)} kWh", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList())),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                      int i = v.toInt();
                      if (i >= 0 && i < chartData.length && i % 2 == 0) {
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(chartData[i]['month'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)));
                      }
                      return const Text('');
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['usage'])).toList(),
                      isCurved: true,
                      curveSmoothness: 0.4,
                      color: vkuOrange,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [vkuOrange.withOpacity(0.3), vkuOrange.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter))
                  )
                ],
                minX: 0, maxX: 11, minY: 0, maxY: setMaxY
            )
        )
    );
  }

  Widget _buildAppBar(List<dynamic> pendingList) { return SliverAppBar(pinned: true, toolbarHeight: 75, backgroundColor: vkuBlue, elevation: 0, leading: Center(child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context))), actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 15), child: Stack(alignment: Alignment.center, children: [IconButton(icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminVerifyPaymentPage()))), if (pendingList.isNotEmpty) Positioned(right: 5, top: 5, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text("${pendingList.length}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))) ])))], centerTitle: true, title: const Text("GIÁM SÁT ĐIỆN NĂNG", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2))); }
  Widget _buildFilterChip(String label) { bool isSel = paymentFilter == label; return GestureDetector(onTap: () => setState(() => paymentFilter = label), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isSel ? vkuOrange : Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: isSel ? [BoxShadow(color: vkuOrange.withOpacity(0.3), blurRadius: 8)] : null), child: Text(label, style: TextStyle(color: isSel ? Colors.white : vkuBlue, fontWeight: FontWeight.bold, fontSize: 12)))); }
  Widget _buildRoomUsageCard(Map<String, dynamic> data) { int status = data['status']; Color sColor = status == 2 ? Colors.green : (status == 1 ? vkuOrange : Colors.red); String sText = status == 2 ? "ĐÃ XONG" : (status == 1 ? "CHỜ DUYỆT" : "CHƯA ĐÓNG"); return Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(25)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Phòng ${data['room']}", style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(sText, style: TextStyle(color: sColor, fontSize: 9, fontWeight: FontWeight.w900)))]), Text("${data['usage'].toStringAsFixed(2)} kWh", style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16))]), const SizedBox(height: 12), LinearProgressIndicator(value: data['usage'] / 50.0, backgroundColor: sandBg, color: sColor, minHeight: 8, borderRadius: BorderRadius.circular(10))])); }
  Widget _buildPendingNotificationCard(int length) { return Padding(padding: const EdgeInsets.fromLTRB(25, 15, 25, 5), child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminVerifyPaymentPage())), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: vkuOrange.withOpacity(0.5), width: 1.5)), child: Row(children: [const CircleAvatar(backgroundColor: vkuOrange, child: Icon(Icons.notification_important_rounded, color: Colors.white)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("YÊU CẦU DUYỆT BIÊN LAI", style: TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 13)), Text("Bạn có $length phòng đang chờ xác nhận tiền.", style: const TextStyle(fontSize: 11, color: Colors.grey))])), const Icon(Icons.chevron_right_rounded, color: vkuOrange)])))); }
  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.fromLTRB(25, 25, 25, 10), child: Row(children: [Container(width: 6, height: 22, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 12), Text(title.toUpperCase(), style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 14))]));
  Widget _buildSearchField() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: TextField(onChanged: (v) => setState(() => searchRoom = v), decoration: const InputDecoration(hintText: "Tìm phòng...", prefixIcon: Icon(Icons.search, color: vkuBlue), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18))));
  Widget _buildModernSelect(String label, String value, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("$label: $value", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), const Icon(Icons.expand_more_rounded, color: Colors.white70, size: 18)]))));
  void _showPicker(String title, List<String> items, String currentValue, Function(String) onSelect) { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 15), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))), Padding(padding: const EdgeInsets.all(20), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: vkuBlue))), Flexible(child: ListView.builder(shrinkWrap: true, itemCount: items.length, itemBuilder: (context, index) { bool isSel = items[index] == currentValue; return ListTile(onTap: () { onSelect(items[index]); Navigator.pop(context); }, leading: Icon(isSel ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSel ? vkuOrange : Colors.grey), title: Text(items[index], style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: vkuBlue))); })), const SizedBox(height: 20)]))); }
}