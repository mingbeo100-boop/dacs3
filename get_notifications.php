<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$user_id = $_GET['user_id'] ?? '';

if ($user_id != '') {
    try {
        // Lấy thông báo gửi cho cá nhân user này HOẶC gửi cho tất cả (user_id IS NULL)
        $sql = "SELECT * FROM notifications 
                WHERE user_id = ? OR user_id     IS NULL 
                ORDER BY created_at DESC LIMIT 20";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute([$user_id]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "success" => true,
            "data" => $rows
        ]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}
?>