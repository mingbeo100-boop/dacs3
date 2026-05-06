<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

// Nhận các thông tin từ Flutter gửi lên
$room_id = $_POST['room_id'] ?? '';
$month = $_POST['month'] ?? ''; // Tháng của hóa đơn (Ví dụ: 03 hoặc 3)
$year = date('Y'); // Năm hiện tại

if (isset($_FILES['receipt_image'])) {
    // 1. CHỈNH ĐƯỜNG DẪN VÀO THƯ MỤC BIENLAI (Như ông đã tạo)
    $target_dir = "uploads/bienlai/"; 
    if (!file_exists($target_dir)) {
        mkdir($target_dir, 0777, true);
    }

    $ext = pathinfo($_FILES["receipt_image"]["name"], PATHINFO_EXTENSION);
    $file_name = "bl_" . $room_id . "_T" . $month . "_" . time() . "." . $ext;
    $target_file = $target_dir . $file_name;

    if (move_uploaded_file($_FILES["receipt_image"]["tmp_name"], $target_file)) {
        
        // 2. CẬP NHẬT DATABASE (Bước cực kỳ quan trọng)
        // Tìm đúng dòng hóa đơn của phòng đó, tháng đó để cập nhật ảnh và trạng thái
        try {
            $sql = "UPDATE invoices SET 
                        status = 1, 
                        evidence_img = :img 
                    WHERE room_id = :room 
                    AND billing_month = :m 
                    AND billing_year = :y 
                    AND (status = 0 OR status = 1)"; // Chỉ cập nhật nếu đang nợ hoặc đã gửi trước đó

            $stmt = $conn->prepare($sql);
            $stmt->execute([
                'img' => $file_name,
                'room' => $room_id,
                'm' => $month,
                'y' => $year
            ]);

            if ($stmt->rowCount() > 0) {
                echo json_encode([
                    "success" => true,
                    "message" => "Gửi biên lai thành công!",
                    "file" => $file_name
                ]);
            } else {
                // Nếu rowCount = 0 có nghĩa là không tìm thấy dòng hóa đơn nào khớp (chưa chốt số)
                echo json_encode([
                    "success" => false, 
                    "message" => "Lỗi: Không tìm thấy hóa đơn tháng $month cho phòng $room_id để đóng tiền."
                ]);
            }

        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => "Lỗi DB: " . $e->getMessage()]);
        }

    } else {
        echo json_encode(["success" => false, "message" => "Không thể lưu file vào folder"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Thiếu dữ liệu ảnh"]);
}
?>