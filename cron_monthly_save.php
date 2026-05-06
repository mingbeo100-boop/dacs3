<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Asia/Ho_Chi_Minh');

// Thiết lập thông số chốt
$month = date('m');      // Tháng hiện tại (Ví dụ: 04)
$year = date('Y');       // Năm hiện tại (2026)
$price_per_kwh = 3500;   // Đơn giá điện (3.500 VNĐ/kWh)

try {
    // 1. Lấy danh sách tổng điện năng tiêu thụ của từng phòng từ bảng devices
    // Giả sử bảng devices của ông có cột room_id và total_kwh
    $sql_devices = "SELECT room_id, SUM(total_kwh) as consumption FROM devices GROUP BY room_id";
    $stmt_devices = $conn->query($sql_devices);
    $rooms = $stmt_devices->fetchAll(PDO::FETCH_ASSOC);

    if (empty($rooms)) {
        echo json_encode(["success" => false, "message" => "Không có dữ liệu thiết bị để chốt số."]);
        exit;
    }

    $count = 0;
    foreach ($rooms as $room) {
        $room_id = $room['room_id'];
        $consumption = (double)$room['consumption'];
        $amount = round($consumption * $price_per_kwh); // Tính thành tiền

        // 2. Kiểm tra xem hóa đơn phòng này trong tháng này đã tồn tại chưa
        $sql_check = "SELECT id FROM invoices WHERE room_id = :room AND billing_month = :m AND billing_year = :y";
        $stmt_check = $conn->prepare($sql_check);
        $stmt_check->execute([
            'room' => $room_id,
            'm' => (int)$month,
            'y' => (int)$year
        ]);

        if ($stmt_check->rowCount() == 0) {
            // 3. Nếu chưa có -> Tiến hành tạo hóa đơn mới (status = 0: Chưa đóng)
            $sql_ins = "INSERT INTO invoices (room_id, consumption, amount, billing_month, billing_year, status, created_at) 
                        VALUES (:room, :cons, :amt, :m, :y, 0, NOW())";
            $stmt_ins = $conn->prepare($sql_ins);
            $stmt_ins->execute([
                'room' => $room_id,
                'cons' => $consumption,
                'amt'  => $amount,
                'm'    => (int)$month,
                'y'    => (int)$year
            ]);
            $count++;
        }
    }

    echo json_encode([
        "success" => true,
        "message" => "Đã chốt số điện tháng $month/$year thành công cho $count phòng!",
        "details" => "Đơn giá áp dụng: $price_per_kwh VNĐ/kWh"
    ]);

} catch (PDOException $e) {
    echo json_encode(["success" => false, "message" => "Lỗi hệ thống: " . $e->getMessage()]);
}
?>