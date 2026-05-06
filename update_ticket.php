<?php
include_once 'db_config.php'; 
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $_POST['id'] ?? null;
    $action = $_POST['action'] ?? null;

    if (!$id || !$action) {
        echo json_encode(["status" => "error", "message" => "Thiếu ID hoặc hành động"]);
        exit;
    }

    try {
        if ($action == 'delete') {
            // Bước 1: Lấy link ảnh
            $stmtImg = $conn->prepare("SELECT image_url FROM tickets WHERE id = ?");
            $stmtImg->execute([$id]);
            $ticket = $stmtImg->fetch(PDO::FETCH_ASSOC);

            if ($ticket && !empty($ticket['image_url'])) {
                $fileName = basename($ticket['image_url']); 
                $filePath = "uploads/tickets/" . $fileName;

                // Bước 2: Xóa file vật lý
                if (file_exists($filePath)) {
                    unlink($filePath);
                }
            }

            // Bước 3: Xóa bản ghi
            $stmt = $conn->prepare("DELETE FROM tickets WHERE id = ?");
            $stmt->execute([$id]);
            $message = "Xóa thành công";

        } else {
            // Cập nhật trạng thái
            $stmt = $conn->prepare("UPDATE tickets SET status = ? WHERE id = ?");
            $stmt->execute([$action, $id]);
            $message = "Cập nhật thành công";
        }
        
        // Trả về thêm ID để Flutter biết chính xác dòng nào vừa bị tác động
        echo json_encode([
            "status" => "success", 
            "message" => $message,
            "id" => $id,
            "action" => $action
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>