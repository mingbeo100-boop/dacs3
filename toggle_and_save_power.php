<?php
include_once 'db_config.php';
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

// Thiết lập múi giờ Việt Nam để tính toán thời gian chính xác
date_default_timezone_set('Asia/Ho_Chi_Minh'); 

// Nhận dữ liệu định danh theo Tên Phòng và Loại thiết bị thay vì ID số
$room_name = $_POST['room_id'] ?? '';    // Ví dụ: "2_421"
$device_type = $_POST['device_type'] ?? ''; // Ví dụ: "light", "fan", "ac", "lock"
$status_action = $_POST['status'] ?? ''; // 'on' hoặc 'off'

try {
    if (empty($room_name) || empty($device_type)) {
        echo json_encode(["status" => "error", "message" => "Thiếu thông tin phòng hoặc loại thiết bị!"]);
        exit();
    }

    if ($status_action == 'on') {
        // 1. BẬT: Tìm thiết bị thuộc phòng đó + đúng loại đó để lưu giờ bắt đầu
        // Dùng NOW() trực tiếp trong SQL để đảm bảo đồng bộ giờ DB
        $sql = "UPDATE devices SET status = 1, last_on_time = NOW() 
                WHERE room_id = :rid AND device_type = :dtype";
        $stmt = $conn->prepare($sql);
        $stmt->execute(['rid' => $room_name, 'dtype' => $device_type]);
        
        echo json_encode(["status" => "success", "msg" => "Đã bật $device_type tại phòng $room_name"]);
    } 
    else {
        // 2. TẮT: Tìm đúng thiết bị của phòng đó để tính tiền
        $stmt = $conn->prepare("SELECT id, status, last_on_time, watt_usage 
                                FROM devices 
                                WHERE room_id = :rid AND device_type = :dtype");
        $stmt->execute(['rid' => $room_name, 'dtype' => $device_type]);
        $device = $stmt->fetch(PDO::FETCH_ASSOC);

        $consumedKwh = 0;
        if ($device && !empty($device['last_on_time'])) {
            $startTime = strtotime($device['last_on_time']);
            $endTime = time(); // Giờ hiện tại của Server
            $diffSeconds = $endTime - $startTime;
            
            if ($diffSeconds > 0) {
                $diffHours = $diffSeconds / 3600;
                $consumedKwh = ($device['watt_usage'] * $diffHours) / 1000;
            }
        }

        // CHỐT SỐ: Cập nhật trạng thái về 0 và cộng dồn điện năng vào đúng ID vừa tìm được
        if ($device) {
            $sqlUpdate = "UPDATE devices 
                          SET status = 0, 
                              total_kwh = total_kwh + :kwh, 
                              last_on_time = NULL 
                          WHERE id = :id";
            $upd = $conn->prepare($sqlUpdate);
            $upd->execute([
                'kwh' => $consumedKwh, 
                'id' => $device['id']
            ]);

            echo json_encode([
                "status" => "success", 
                "added_kwh" => round($consumedKwh, 8),
                "room" => $room_name
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Không tìm thấy thiết bị để tắt!"]);
        }
    }
} catch (PDOException $e) {
    echo json_encode(["error" => "Lỗi hệ thống: " . $e->getMessage()]);
}
?>