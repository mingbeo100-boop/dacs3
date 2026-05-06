<?php
include_once 'db_config.php';

header('Content-Type: application/json; charset=utf-8');

// Nhận dữ liệu POST từ Flutter
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';
$month   = isset($_POST['month']) ? $_POST['month'] : ''; 
$year    = isset($_POST['year']) ? $_POST['year'] : '';
$status  = isset($_POST['status']) ? $_POST['status'] : '0';
$w1      = isset($_POST['week1']) ? $_POST['week1'] : '0';
$w2      = isset($_POST['week2']) ? $_POST['week2'] : '0';
$w3      = isset($_POST['week3']) ? $_POST['week3'] : '0';
$w4      = isset($_POST['week4']) ? $_POST['week4'] : '0';

if(empty($user_id) || empty($month)) {
    echo json_encode(["error" => "Thiếu dữ liệu đầu vào"]);
    exit;
}

try {
    // Câu lệnh này sẽ kiểm tra: 
    // Nếu sinh viên đó trong tháng đó chưa có dòng nào thì INSERT (Thêm mới)
    // Nếu đã có rồi (trùng user_id, month, year) thì UPDATE (Cập nhật đè lên)
    $sql = "INSERT INTO payments (user_id, month, year, status, week1, week2, week3, week4) 
            VALUES (:uid, :m, :y, :s, :w1, :w2, :w3, :w4)
            ON DUPLICATE KEY UPDATE 
            status = :s, week1 = :w1, week2 = :w2, week3 = :w3, week4 = :w4";
            
    $stmt = $conn->prepare($sql);
    $stmt->execute([
        ':uid' => $user_id,
        ':m'   => $month,
        ':y'   => $year,
        ':s'   => $status,
        ':w1'  => $w1,
        ':w2'  => $w2,
        ':w3'  => $w3,
        ':w4'  => $w4
    ]);

    echo json_encode(["success" => true, "message" => "Đã lưu dữ liệu thành công"]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Lỗi SQL: " . $e->getMessage()]);
}
?>