<?php
include_once 'db_config.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Nhận danh sách các số phòng (ví dụ: ["101", "202"])
    $rooms = json_decode($_POST['rooms'], true);
    $limit = $_POST['usage_limit'] ?? '15';
    
    if (empty($rooms)) {
        echo json_encode(["status" => "error", "message" => "Danh sách phòng trống"]);
        exit;
    }

    $title = "⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN";
    $content = "Phòng của bạn đã sử dụng quá $limit kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!";

    try {
        // Tìm tất cả sinh viên thuộc các phòng nằm trong danh sách
        $placeholders = implode(',', array_fill(0, count($rooms), '?'));
        // Giả sử cột phòng trong bảng users là room_id hoặc room_number
        $sql = "SELECT id FROM users WHERE room_id IN ($placeholders)";
        $stmt = $conn->prepare($sql);
        $stmt->execute($rooms);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (count($users) > 0) {
            // Chèn thông báo cho từng sinh viên
            $insertSql = "INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, 'warning', 0)";
            $insertStmt = $conn->prepare($insertSql);

            foreach ($users as $user) {
                $insertStmt->execute([$user['id'], $title, $content]);
            }
            echo json_encode(["status" => "success", "count" => count($users)]);
        } else {
            echo json_encode(["status" => "success", "count" => 0, "message" => "Không tìm thấy sinh viên trong các phòng này"]);
        }
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>