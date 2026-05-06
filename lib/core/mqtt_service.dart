import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? client;
  Function? onDisconnectedCallback;

  Future<bool> connect(String clientId, Function(String) onMessageReceived, {Function? onDisconnected}) async {
    this.onDisconnectedCallback = onDisconnected;

    // Kết nối qua cổng 1883 tiêu chuẩn
    client = MqttServerClient('broker.hivemq.com', clientId);
    client!.port = 1883;
    client!.keepAlivePeriod = 20;
    client!.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();
    client!.connectionMessage = connMessage;

    client!.onDisconnected = () {
      if (onDisconnectedCallback != null) onDisconnectedCallback!();
    };

    try {
      // BẮT BUỘC phải await ở đây
      await client!.connect();
    } catch (e) {
      print("LỖI MQTT: $e");
      client!.disconnect();
      return false;
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message).trim();
        onMessageReceived(message);
      });
      return true; // Trả về true để UI biết đã xong
    }
    return false;
  }

  void subscribe(String topic) {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      client!.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void publish(String topic, String message) {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }
}