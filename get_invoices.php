<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$room_id = $_POST['room_id'] ?? 'unknown';
$month = $_POST['month'] ?? date('m');

if (isset($_FILES['receipt_image'])) {
    // 1. ĐỊNH HƯỚNG VÀO THƯ MỤC BIENLAI
    $target_dir = "uploads/bienlai/"; 
    
    if (!file_exists($target_dir)) {
        mkdir($target_dir, 0777, true);
    }

    // 2. TẠO TÊN FILE PHÂN BIỆT (Ví dụ: bl_2_421_T04_171350.jpg)
    $ext = pathinfo($_FILES["receipt_image"]["name"], PATHINFO_EXTENSION);
    $file_name = "bl_" . $room_id . "_T" . $month . "_" . time() . "." . $ext;
    $target_file = $target_dir . $file_name;

    if (move_uploaded_file($_FILES["receipt_image"]["tmp_name"], $target_file)) {
        // 3. LƯU TÊN FILE VÀO DATABASE
        // Giả sử ông cập nhật vào bảng invoices cho hóa đơn mới nhất của phòng đó
        $sql = "UPDATE invoices SET 
                    evidence_img = :img, 
                    status = 1 
                WHERE room_id = :room_id AND billing_month = :month AND status = 0 
                LIMIT 1";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute([
            'img' => $file_name,
            'room_id' => $room_id,
            'month' => $month
        ]);

        echo json_encode([
            "success" => true, 
            "message" => "Biên lai đã được lưu vào folder bienlai",
            "file_path" => $file_name
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Lỗi di chuyển file"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Không tìm thấy dữ liệu ảnh"]);
}
?>