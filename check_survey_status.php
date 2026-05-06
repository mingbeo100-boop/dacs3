<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

try {
    // Đếm xem trong bảng thói quen đã có dòng nào của user này chưa
    $stmt = $conn->prepare("SELECT COUNT(*) FROM student_preferences WHERE user_id = :id");
    $stmt->execute(['id' => $user_id]);
    $count = $stmt->fetchColumn();

    // Nếu count > 0 nghĩa là đã làm khảo sát rồi
    echo json_encode(["has_survey" => ($count > 0)]);
} catch (PDOException $e) {
    echo json_encode(["has_survey" => false, "error" => $e->getMessage()]);
}
?>