import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  List<dynamic> roomStats = [];
  bool isLoading = true;

  // Địa chỉ IP Server của ông
  final String apiUrl = "http://192.168.4.21/dacs3/get_device_stats_by_room.php";

  @override
  void initState() {
    super.initState();
    _fetchRoomStats();
  }

  Future<void> _fetchRoomStats() async {
    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            roomStats = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        debugPrint("Lỗi kết nối: $e");
      }
    }
  }

  // LOGIC PHÂN LOẠI ICON & MÀU (Giống ảnh mẫu ông gửi)
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
        'color': Color(0xFFFF5722) // Màu đỏ cam của khóa
      };
    }
    return {'icon': Icons.power_settings_new_rounded, 'color': Colors.blueGrey};
  }

  // Widget hiển thị từng thiết bị bên trong phòng
  Widget _buildDeviceItem(String name, int status) {
    bool isOn = status == 1;
    var style = _getDeviceStyle(name, isOn);
    Color deviceColor = isOn ? style['color'] : Colors.grey;

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
          // Icon rực rỡ theo loại thiết bị
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
                  name,
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
          // Badge ON/OFF
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: vkuOrange))
          : RefreshIndicator(
        onRefresh: _fetchRoomStats,
        color: vkuOrange,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: roomStats.length,
          itemBuilder: (context, index) {
            final room = roomStats[index];
            int active = room['active_count'];
            int total = room['device_count'];

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
                    "Phòng: ${room['room_id']}",
                    style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Đang bật $active/$total thiết bị",
                      style: TextStyle(
                          fontSize: 12,
                          color: active > 0 ? Colors.green.shade700 : Colors.grey,
                          fontWeight: FontWeight.w900
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
                      child: Column(
                        children: (room['all_devices'] as List).map((device) {
                          return _buildDeviceItem(
                              device['device_name'],
                              int.parse(device['status'].toString())
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}