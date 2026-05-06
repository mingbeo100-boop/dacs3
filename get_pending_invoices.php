<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

try {
    // Sử dụng GROUP BY i.id để đảm bảo mỗi hóa đơn (id duy nhất) chỉ hiện 1 lần
    // Cho dù phòng đó có 4-5 sinh viên thì Admin cũng chỉ thấy 1 dòng báo cáo để duyệt
    $sql = "SELECT i.*, u.fullname 
            FROM invoices i 
            LEFT JOIN users u ON i.room_id = u.room_id 
            WHERE i.status = 1 
            GROUP BY i.id 
            ORDER BY i.created_at ASC";
            
    $stmt = $conn->prepare($sql);
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "success" => true, 
        "count" => count($data),
        "data" => $data
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "success" => false, 
        "message" => "Lỗi truy vấn: " . $e->getMessage()
    ]);
}
?>