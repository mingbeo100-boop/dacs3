import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để giám sát thiết bị Realtime

class AdminDeviceSummaryPage extends StatefulWidget {
  const AdminDeviceSummaryPage({super.key});

  @override
  State<AdminDeviceSummaryPage> createState() => _AdminDeviceSummaryPageState();
}

class _AdminDeviceSummaryPageState extends State<AdminDeviceSummaryPage> {
  // Hệ màu VKU chuẩn
  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);

  // LOGIC PHÂN LOẠI ICON & MÀU (Giữ nguyên cấu trúc phong cách của bạn)
  Map<String, dynamic> _getDeviceStyle(String name, bool isOn) {
    String n = name.toLowerCase();
    if (n.contains('đèn') || n.contains('light')) {
      return {'icon': Icons.lightbulb_rounded, 'color': Colors.amber};
    } else if (n.contains('quạt') || n.contains('fan')) {
      return {'icon': Icons.cyclone_rounded, 'color': Colors.greenAccent.shade700};
    } else if (n.contains('điều hòa') || n.contains('ac') || n.contains('air')) {
      return {'icon': Icons.ac_unit_rounded, 'color': Colors.cyan};
    } else if (n.contains('khóa') || n.contains('lock')) {
      return {
        'icon': isOn ? Icons.lock_open_rounded : Icons.lock_rounded,
        'color': const Color(0xFFFF5722)
      };
    }
    return {'icon': Icons.power_settings_new_rounded, 'color': Colors.blueGrey};
  }

  // Widget hiển thị từng thiết bị bên trong phòng
  Widget _buildDeviceItem(String name, bool isOn) {
    var style = _getDeviceStyle(name, isOn);
    Color deviceColor = isOn ? style['color'] : Colors.grey;

    // Chuẩn hóa tên hiển thị tiếng Việt cho Admin dễ nhìn
    String displayName = name;
    if (name.toLowerCase() == 'light') displayName = "Bóng đèn";
    if (name.toLowerCase() == 'fan') displayName = "Quạt máy";
    if (name.toLowerCase() == 'ac') displayName = "Điều hòa";
    if (name.toLowerCase() == 'lock') displayName = "Khóa cửa";

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: isOn ? deviceColor.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOn ? deviceColor.withOpacity(0.4) : Colors.grey.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: deviceColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(style['icon'], color: deviceColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: isOn ? vkuBlue : Colors.grey.shade600,
                    fontWeight: isOn ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOn ? "ĐANG HOẠT ĐỘNG" : "ĐANG TẮT",
                  style: TextStyle(
                    color: isOn ? deviceColor : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOn ? deviceColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isOn ? "ON" : "OFF",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // THIẾT LẬP LUỒNG STREAM REALTIME LẮNG NGHE TOÀN BỘ THIẾT BỊ TRONG HỆ THỐNG
    final Stream<QuerySnapshot> _devicesStream = FirebaseFirestore.instance
        .collection('devices')
        .snapshots();

    return Scaffold(
      backgroundColor: sandBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [vkuBlue, Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("TỔNG QUAN THIẾT BỊ PHÒNG",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _devicesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Lỗi tải dữ liệu thiết bị mây."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: vkuOrange));
          }

          // --- THUẬT TOÁN GOM NHÓM THEO PHÒNG (GROUP BY ROOM_ID) TRỰC TIẾP TỪ FIRESTORE ---
          Map<String, List<Map<String, dynamic>>> groupedRooms = {};

          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> deviceData = doc.data() as Map<String, dynamic>;
            String roomId = deviceData['room_id']?.toString() ?? "Chưa rõ";

            // Xác định trạng thái ON/OFF chuỗi hoặc bool linh hoạt
            String s = deviceData['status'].toString().toLowerCase();
            bool isOn = (s == "1" || s == "on" || s == "true");

            Map<String, dynamic> cleanDevice = {
              'name': deviceData['device_type']?.toString() ?? 'Thiết bị',
              'is_on': isOn
            };

            if (!groupedRooms.containsKey(roomId)) {
              groupedRooms[roomId] = [];
            }
            groupedRooms[roomId]!.add(cleanDevice);
          }

          // Chuyển Map gom nhóm sang dạng List để đẩy vào ListView.builder hiển thị giao diện
          List<String> sortedRoomIds = groupedRooms.keys.toList()..sort();

          if (sortedRoomIds.isEmpty) {
            return const Center(
              child: Text("Hệ thống IoT hiện tại chưa cấu hình thiết bị nào.",
                  style: TextStyle(color: vkuBlue, fontWeight: FontWeight.bold, fontSize: 13)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: sortedRoomIds.length,
            itemBuilder: (context, index) {
              final String roomId = sortedRoomIds[index];
              final List<Map<String, dynamic>> allDevices = groupedRooms[roomId]!;

              // Tính toán nhanh số lượng thiết bị đang bật trong phòng để render subtitle badge
              int activeCount = allDevices.where((d) => d['is_on'] == true).length;
              int totalCount = allDevices.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: vkuOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.meeting_room_rounded, color: vkuOrange, size: 28),
                        ),
                        title: Text(
                          "Phòng: $roomId",
                          style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Đang bật $activeCount/$totalCount thiết bị",
                            style: TextStyle(
                                fontSize: 12,
                                color: activeCount > 0 ? Colors.green.shade700 : Colors.grey,
                                fontWeight: FontWeight.w900
                            ),
                          ),
                        ),
                        children: [
                    Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
                    child: Column(
                        children:allDevices.map((device) {
                return _buildDeviceItem(
                device['name'],
                device['is_on']
                );
                }).toList(),
              ),
              ),
              ],
              ),
              ),
              );
            },
          );
        },
      ),
    );
  }
}