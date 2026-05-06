<?php
include_once 'db_config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $code = $_POST['student_code'];
    $is_paid = $_POST['is_paid'];

    try {
        // Cập nhật bảng profiles dựa trên username (student_code) của bảng users
        $sql = "UPDATE profiles p 
                INNER JOIN users u ON p.user_id = u.id 
                SET p.is_paid = :is_paid 
                WHERE u.username = :code";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute(['is_paid' => $is_paid, 'code' => $code]);

        echo json_encode(["status" => "success"]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => $e->getMessage()]);
    }
}
?>