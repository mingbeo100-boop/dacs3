import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import '../core/mqtt_service.dart';

class VirtualDevicePage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final dynamic user;
  const VirtualDevicePage({super.key, required this.roomId, required this.roomName, this.user});

  @override
  State<VirtualDevicePage> createState() => _VirtualDevicePageState();
}

class _VirtualDevicePageState extends State<VirtualDevicePage> with TickerProviderStateMixin {
  final MqttService _mqtt = MqttService();

  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardBg = Color(0xFFFFF8F0);

  static const lightActive = Color(0xFFFFD700);
  static const fanActive = Color(0xFF00FF41);
  static const acActive = Color(0xFF00E5FF);
  static const lockActive = Color(0xFFFF3D00);

  // Trạng thái thiết bị
  bool isLightOn = false, isFanOn = false, isAcOn = false, isLockOpen = false;
  double temperature = 26.5, humidity = 60.0;
  String lastMessage = "Hệ thống sẵn sàng";
  String connectionStatus = "Đang kết nối...";

  String get roomTopic => "vku/nhatlong/room${widget.roomName.replaceAll('_', '')}/all";

  Timer? _powerCounter;
  double _sessionKwh = 0.0;
  late AnimationController _fanController, _glowController, _effectController;

  @override
  void initState() {
    super.initState();
    _fanController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _glowController = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
    _effectController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();

    // Chạy song song cả 2 luồng để nhanh nhất
    Future.wait([
      _syncDevicesFromDB(),
      _setupMqtt(),
    ]);
  }

  // --- ĐỒNG BỘ DỮ LIỆU TỪ DB (CHẠY 1 LẦN KHI VÀO) ---
  Future<void> _syncDevicesFromDB() async {
    try {
      final response = await http.get(Uri.parse("http://10.60.56.48/dacs3/get_devices.php?room_id=${widget.roomId}"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        List<dynamic> deviceList = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          for (var d in deviceList) {
            String s = d['status'].toString().toLowerCase();
            bool isOn = (s == "1" || s == "on" || s == "true");
            String type = d['device_type'].toString().toLowerCase();

            if (type == 'light') isLightOn = isOn;
            if (type == 'fan') {
              isFanOn = isOn;
              isOn ? _fanController.repeat() : _fanController.stop();
            }
            if (type == 'ac') isAcOn = isOn;
            if (type == 'lock') isLockOpen = isOn;
          }
          _managePowerTimer();
        });
      }
    } catch (e) { debugPrint("Lỗi sync DB: $e"); }
  }

  // --- KẾT NỐI MQTT SIÊU TỐC ---
  Future<void> _setupMqtt() async {
    String clientId = "NL_${widget.roomName}_${math.Random().nextInt(1000)}";
    try {
      await _mqtt.connect(clientId, (message) {
        if (!mounted) return;
        _processIncomingMqtt(message);
      });
      _mqtt.subscribe(roomTopic);
      if (mounted) setState(() => connectionStatus = "Trực Tuyến");
    } catch (e) {
      if (mounted) setState(() => connectionStatus = "Ngoại Tuyến");
    }
  }

  void _processIncomingMqtt(String message) {
    setState(() {
      lastMessage = "Nhận: $message";
      if (message == "LIGHT_ON") isLightOn = true;
      else if (message == "LIGHT_OFF") isLightOn = false;
      else if (message == "FAN_ON") { isFanOn = true; _fanController.repeat(); }
      else if (message == "FAN_OFF") { isFanOn = false; _fanController.stop(); }
      else if (message == "AC_ON") isAcOn = true;
      else if (message == "AC_OFF") isAcOn = false;
      else if (message == "LOCK_OPEN") isLockOpen = true;
      else if (message == "LOCK_CLOSE") isLockOpen = false;
      _managePowerTimer();
    });
  }

  // --- HÀM TOGGLE CẢI TIẾN: PHẢN HỒI TỨC THÌ ---
  void _handleToggle(String deviceType, String cmd, bool currentStatus) {
    // 1. Optimistic UI: Đổi trạng thái ngay trên màn hình (0ms)
    setState(() {
      if (cmd == "LIGHT") isLightOn = !currentStatus;
      if (cmd == "FAN") {
        isFanOn = !currentStatus;
        isFanOn ? _fanController.repeat() : _fanController.stop();
      }
      if (cmd == "AC") isAcOn = !currentStatus;
      if (cmd == "LOCK") isLockOpen = !currentStatus;
      lastMessage = "Đang gửi lệnh $cmd...";
    });

    // 2. Xử lý lệnh MQTT và DB ngầm (Background)
    String action = currentStatus ? "OFF" : "ON";
    String mqttCmd = (cmd == "LOCK") ? (currentStatus ? "LOCK_CLOSE" : "LOCK_OPEN") : "${cmd}_$action";

    // Gửi MQTT ngay
    _mqtt.publish(roomTopic, mqttCmd);

    // Gửi DB (Không dùng await để không chặn UI)
    http.post(
        Uri.parse("http://10.60.56.48/dacs3/toggle_and_save_power.php"),
        body: {
          "room_id": widget.roomName,
          "device_type": deviceType,
          "status": currentStatus ? "off" : "on"
        }
    ).catchError((e) => debugPrint("Lỗi lưu DB: $e"));

    _managePowerTimer();
  }

  void _managePowerTimer() {
    bool anyOn = isLightOn || isFanOn || isAcOn;
    if (anyOn) {
      if (_powerCounter == null || !_powerCounter!.isActive) {
        _powerCounter = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              double consumption = 0;
              if (isLightOn) consumption += 20;
              if (isFanOn) consumption += 65;
              if (isAcOn) consumption += 1200;
              _sessionKwh += consumption / 3600 / 1000;
            });
          }
        });
      }
    } else { _powerCounter?.cancel(); _powerCounter = null; }
  }

  @override
  void dispose() {
    _fanController.dispose();
    _glowController.dispose();
    _effectController.dispose();
    _powerCounter?.cancel();
    super.dispose();
  }

  // --- GIAO DIỆN (GIỮ NGUYÊN STYLE VKU CỦA ÔNG) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildConnectionStatusChip()),
          SliverToBoxAdapter(child: _buildDashboardBanner()),
          SliverToBoxAdapter(child: _buildSectionHeader("ĐIỀU KHIỂN THIẾT BỊ")),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            sliver: SliverGrid.count(
              crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20,
              children: [
                _buildDeviceCard("Bóng đèn", Icons.lightbulb_rounded, isLightOn, lightActive, "LIGHT", "light"),
                _buildDeviceCard("Quạt máy", Icons.cyclone, isFanOn, fanActive, "FAN", "fan"),
                _buildDeviceCard("Điều hòa", Icons.ac_unit_rounded, isAcOn, acActive, "AC", "ac"),
                _buildDeviceCard("Khóa cửa", isLockOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded, isLockOpen, lockActive, "LOCK", "lock"),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildSectionHeader("NHẬT KÝ HỆ THỐNG")),
          SliverToBoxAdapter(child: _buildMonitorBox()),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true, backgroundColor: vkuBlue, elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
      centerTitle: true,
      title: Text("PHÒNG ${widget.roomName}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }

  Widget _buildConnectionStatusChip() {
    bool isOnline = connectionStatus.contains("Tuyến");
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Center(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.5 * _glowController.value), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : Colors.orange),
                const SizedBox(width: 10),
                Text(connectionStatus.toUpperCase(), style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [vkuBlue, Color(0xFF1A4594)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12))],
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("TIÊU THỤ TRONG PHÒNG", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 5),
              Text(_sessionKwh.toStringAsFixed(5), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const Text("kWh (Live)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.bolt_rounded, color: vkuOrange, size: 35)),
          ]),
          const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _dashItem(Icons.thermostat, "$temperature°", "Nhiệt độ"),
            Container(width: 1, height: 30, color: Colors.white12),
            _dashItem(Icons.water_drop, "$humidity%", "Độ ẩm"),
          ]),
        ]),
      ),
    );
  }

  Widget _dashItem(IconData i, String v, String l) => Column(children: [
    Icon(i, color: vkuOrange, size: 22),
    const SizedBox(height: 5),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(l, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
    child: Row(children: [
      Container(width: 6, height: 20, decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10))),
      const SizedBox(width: 12),
      Text(title.toUpperCase(), style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
    ]),
  );

  Widget _buildDeviceCard(String name, IconData icon, bool isOn, Color activeColor, String cmd, String deviceType) {
    return InkWell(
      onTap: () => _handleToggle(deviceType, cmd, isOn),
      borderRadius: BorderRadius.circular(35),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isOn ? Colors.white : cardBg,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: isOn ? activeColor : Colors.white, width: 2),
          boxShadow: [
            if (isOn) BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(children: [
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildAnimatedIcon(name, icon, isOn, activeColor),
            const SizedBox(height: 10),
            Text(name, style: TextStyle(fontWeight: FontWeight.w900, color: isOn ? vkuBlue : Colors.grey.shade400, fontSize: 13)),
            const SizedBox(height: 2),
            Text(isOn ? "ON" : "OFF", style: TextStyle(color: isOn ? activeColor : Colors.grey.shade300, fontSize: 8, fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildAnimatedIcon(String name, IconData icon, bool isOn, Color color) {
    if (isOn) {
      Widget iconWidget = Icon(icon, size: 40, color: color);
      if (name == "Quạt máy") return RotationTransition(turns: _fanController, child: iconWidget);
      return iconWidget;
    }
    return Icon(icon, size: 38, color: Colors.grey.shade200);
  }

  Widget _buildMonitorBox() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 25), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(25)),
    child: Text(">_ $lastMessage", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10)),
  );
}