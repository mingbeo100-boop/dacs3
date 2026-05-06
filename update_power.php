<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

// Lấy dữ liệu từ Flutter gửi lên
$device_id = isset($_POST['id']) ? intval($_POST['id']) : 0;
$status_action = isset($_POST['status']) ? $_POST['status'] : ''; // 'on' hoặc 'off'

try {
    if ($status_action == 'on') {
        // 1. BẬT: status = 1, lưu giờ bắt đầu
        $sql = "UPDATE devices SET status = 1, last_on_time = NOW() WHERE id = :id";
        $stmt = $conn->prepare($sql);
        $stmt->execute(['id' => $device_id]);
        
        echo json_encode(["status" => "success", "msg" => "Device is ON"]);
    } 
    else {
        // 2. TẮT: Tính toán và cộng dồn vào cột total_kwh trong bảng devices
        $stmt = $conn->prepare("SELECT status, last_on_time, watt_usage FROM devices WHERE id = :id");
        $stmt->execute(['id' => $device_id]);
        $device = $stmt->fetch(PDO::FETCH_ASSOC);

        $consumedKwh = 0;
        // Chỉ tính khi thiết bị đang ở trạng thái Bật (1)
        if ($device && (int)$device['status'] === 1 && !empty($device['last_on_time'])) {
            $startTime = strtotime($device['last_on_time']);
            $endTime = time();
            $diffSeconds = $endTime - $startTime;
            
            if ($diffSeconds > 0) {
                $diffHours = $diffSeconds / 3600;
                $consumedKwh = ($device['watt_usage'] * $diffHours) / 1000;

                // CẬP NHẬT CHÍNH XÁC VÀO BẢNG DEVICES
                $sqlUpdate = "UPDATE devices 
                              SET status = 0, 
                                  total_kwh = total_kwh + :kwh, 
                                  last_on_time = NULL 
                              WHERE id = :id";
                $upd = $conn->prepare($sqlUpdate);
                $upd->execute([
                    'kwh' => $consumedKwh,
                    'id' => $device_id
                ]);
            }
        }
        echo json_encode([
            "status" => "success", 
            "added_kwh" => round($consumedKwh, 6),
            "msg" => "Device is OFF and saved"
        ]);
    }
} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>