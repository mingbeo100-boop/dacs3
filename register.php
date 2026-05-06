<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

// 1. Nhận dữ liệu từ Flutter gửi lên
$fullname = $_POST['fullname'] ?? '';
$username = $_POST['username'] ?? ''; // Mã sinh viên
$password = $_POST['password'] ?? '';
$room_input = $_POST['room'] ?? ''; // Tên phòng (VD: 2_422)

if (empty($fullname) || empty($username) || empty($password) || empty($room_input)) {
    echo json_encode(["status" => "error", "message" => "Vui lòng nhập đủ thông tin!"]);
    exit();
}

try {
    $conn->beginTransaction();

    // 2. Kiểm tra mã sinh viên đã tồn tại chưa
    $check = $conn->prepare("SELECT id FROM users WHERE username = ?");
    $check->execute([$username]);
    if ($check->rowCount() > 0) {
        echo json_encode(["status" => "error", "message" => "Mã sinh viên này đã tồn tại!"]);
        $conn->rollBack(); 
        exit();
    }

    // 3. XỬ LÝ BẢNG ROOMS (Để quản lý danh sách phòng)
    $stmtRoom = $conn->prepare("SELECT id FROM rooms WHERE room_number = ?");
    $stmtRoom->execute([$room_input]);
    $roomData = $stmtRoom->fetch(PDO::FETCH_ASSOC);

    if (!$roomData) {
        // Nếu chưa có tên phòng này trong hệ thống -> Tạo mới
        $insRoom = $conn->prepare("INSERT INTO rooms (room_number) VALUES (?)");
        $insRoom->execute([$room_input]);
    }

    // 4. TỰ ĐỘNG TẠO THIẾT BỊ CHO PHÒNG (Nếu phòng chưa có thiết bị)
    $checkDev = $conn->prepare("SELECT id FROM devices WHERE room_id = ?");
    $checkDev->execute([$room_input]);

    if ($checkDev->rowCount() == 0) {
        $devices = [
            ['name' => 'Bóng đèn', 'type' => 'light', 'watt' => 20],
            ['name' => 'Quạt máy', 'type' => 'fan', 'watt' => 65],
            ['name' => 'Điều hòa', 'type' => 'ac', 'watt' => 1200],
            ['name' => 'Khóa cửa', 'type' => 'lock', 'watt' => 10]
        ];

        // SỬA QUAN TRỌNG: Lưu trực tiếp $room_input (chữ) vào cột room_id của bảng devices
        $stmtDev = $conn->prepare("INSERT INTO devices (room_id, device_name, device_type, status, mqtt_topic, watt_usage, total_kwh) VALUES (?, ?, ?, 0, ?, ?, 0)");
        
        foreach ($devices as $d) {
            // Tạo topic MQTT sạch (VD: 2_422 thành 2422)
            $cleanRoom = str_replace('_', '', $room_input);
            $topic = "vku/nhatlong/room$cleanRoom/all";
            
            // Thực thi: Lưu theo tên phòng $room_input
            $stmtDev->execute([$room_input, $d['name'], $d['type'], $topic, $d['watt']]);
        }
    }

    // 5. LƯU VÀO BẢNG USERS (Lưu room_id là chữ 2_422)
    $hashed_password = password_hash($password, PASSWORD_BCRYPT);
    $query = "INSERT INTO users (fullname, username, password, room_id, role) VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($query);
    $stmt->execute([$fullname, $username, $hashed_password, $room_input, 'student']);
    
    $new_user_id = $conn->lastInsertId();

    // 6. TẠO PROFILE ĐỒNG BỘ (Lưu room_id là chữ 2_422)
    $sql_profile = "INSERT INTO profiles (user_id, fullname, room_id) VALUES (?, ?, ?)";
    $stmt_profile = $conn->prepare($sql_profile);
    $stmt_profile->execute([$new_user_id, $fullname, $room_input]);

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Đăng ký thành công!"]);

} catch (PDOException $e) {
    if ($conn->inTransaction()) $conn->rollBack();
    echo json_encode(["status" => "error", "message" => "Lỗi hệ thống: " . $e->getMessage()]);
}
?>