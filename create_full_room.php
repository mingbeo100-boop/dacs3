<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

// Giả sử ông truyền tên phòng mới lên
$new_room_number = isset($_POST['room_number']) ? $_POST['room_number'] : '';

if (empty($new_room_number)) {
    echo json_encode(["error" => "Vui lòng nhập số phòng"]);
    exit;
}

try {
    $conn->beginTransaction(); // Bắt đầu giao dịch (để tránh lỗi nửa chừng)

    // Bước 1: Tạo phòng mới trong bảng rooms
    $sqlRoom = "INSERT INTO rooms (room_number) VALUES (:num)";
    $stmtRoom = $conn->prepare($sqlRoom);
    $stmtRoom->execute(['num' => $new_room_number]);
    
    // Lấy ID của phòng vừa tạo
    $new_room_id = $conn->lastInsertId();

    // Bước 2: Tự động chèn 4 thiết bị mẫu cho phòng này
    $devices = [
        ['name' => 'Bóng đèn', 'type' => 'light', 'watt' => 20],
        ['name' => 'Quạt máy', 'type' => 'fan', 'watt' => 65],
        ['name' => 'Điều hòa', 'type' => 'ac', 'watt' => 1200],
        ['name' => 'Khóa cửa', 'type' => 'lock', 'watt' => 10]
    ];

    $sqlDevice = "INSERT INTO devices (room_id, device_name, device_type, status, mqtt_topic, watt_usage, total_kwh) 
                  VALUES (:rid, :name, :type, 0, :topic, :watt, 0)";
    $stmtDevice = $conn->prepare($sqlDevice);

    foreach ($devices as $d) {
        $stmtDevice->execute([
            'rid'   => $new_room_id,
            'name'  => $d['name'],
            'type'  => $d['type'],
            'topic' => "vku/nhatlong/room" . str_replace('_', '', $new_room_number) . "/all",
            'watt'  => $d['watt']
        ]);
    }

    $conn->commit(); // Hoàn tất lưu dữ liệu
    echo json_encode(["status" => "success", "msg" => "Đã tạo xong phòng $new_room_number và 4 thiết bị!"]);

} catch (Exception $e) {
    $conn->rollBack(); // Nếu lỗi thì hủy bỏ toàn bộ để tránh rác DB
    echo json_encode(["error" => $e->getMessage()]);
}
?>