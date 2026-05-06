<?php
include_once 'db_config.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

$method = $_SERVER['REQUEST_METHOD'];

if ($method == "OPTIONS") { exit(); }

try {
    if ($method == 'POST') {
        // --- ADMIN GỬI THÔNG BÁO ---
        $user_id = $_POST['user_id'] ?? null;
        $title = $_POST['title'] ?? '';
        $content = $_POST['content'] ?? '';
        $type = $_POST['type'] ?? 'remind';

        if ($user_id && $content) {
            $stmt = $conn->prepare("INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, ?, 0)");
            if ($stmt->execute([$user_id, $title, $content, $type])) {
                echo json_encode(["status" => "success"]);
            } else {
                echo json_encode(["status" => "error", "message" => "Không thể lưu vào database"]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Thiếu dữ liệu"]);
        }
    } 

    else if ($method == 'GET') {
        // --- SINH VIÊN LẤY DANH SÁCH & ĐẾM TIN CHƯA ĐỌC ---
        $user_id = $_GET['user_id'] ?? null;
        
        if ($user_id) {
            // 1. Lấy danh sách thông báo
            $stmt = $conn->prepare("SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC");
            $stmt->execute([$user_id]);
            $list = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // 2. Đếm số tin chưa đọc (is_read = 0) cho cái chuông
            $stmt_count = $conn->prepare("SELECT COUNT(*) as unread FROM notifications WHERE user_id = ? AND is_read = 0");
            $stmt_count->execute([$user_id]);
            $unread_res = $stmt_count->fetch(PDO::FETCH_ASSOC);

            echo json_encode([
                "status" => "success", 
                "data" => $list,
                "unread_count" => (int)$unread_res['unread']
            ]);
        }
    }

    else if ($method == 'PUT') {
        // --- CẬP NHẬT ĐÃ ĐỌC (Khi sinh viên bấm vào xem) ---
        parse_str(file_get_contents("php://input"), $_PUT);
        $user_id = $_GET['user_id'] ?? $_PUT['user_id'] ?? null;

        if ($user_id) {
            $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
            $stmt->execute([$user_id]);
            echo json_encode(["status" => "success", "message" => "Đã đánh dấu tất cả là đã đọc"]);
        }
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>