<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

// Nhận room_id gửi từ Flutter (Bây giờ là chuỗi tên phòng: "2_302", "2_421"...)
// Dùng $_GET vì Flutter của ông đang gọi lệnh http.get
$room_name = isset($_GET['room_id']) ? $_GET['room_id'] : '';

try {
    if (empty($room_name)) {
        echo json_encode(["error" => "Thiếu tên phòng!"], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // Câu lệnh SQL: Tìm tất cả thiết bị thuộc về cái Tên Phòng đó
    // Vì ông đã sửa cột room_id trong bảng devices thành VARCHAR rồi nên so sánh trực tiếp
    $sql = "SELECT id, device_name, device_type, status, mqtt_topic, watt_usage, total_kwh, last_on_time 
            FROM devices 
            WHERE room_id = :rn";
            
    $stmt = $conn->prepare($sql);
    $stmt->execute(['rn' => $room_name]);
    $devices = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Nếu tìm thấy thiết bị, trả về mảng danh sách
    if ($devices) {
        echo json_encode($devices, JSON_UNESCAPED_UNICODE);
    } else {
        // Nếu phòng mới toanh chưa có thiết bị trong bảng devices
        // Trả về mảng rỗng [] để Flutter không bị crash khi map dữ liệu
        echo json_encode([], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    // Trả về lỗi Database nếu có (ví dụ: gõ sai tên cột)
    echo json_encode(["error" => "Lỗi DB: " . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>