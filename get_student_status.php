<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$monthNum = isset($_GET['month']) ? intval($_GET['month']) : 0;
$yearStr = isset($_GET['year']) ? $_GET['year'] : "";

if ($user_id == 0 || $monthNum == 0 || empty($yearStr)) {
    echo json_encode(["is_paid" => 0, "week1" => 0, "week2" => 0, "week3" => 0, "week4" => 0]);
    exit;
}

// Chuẩn hóa tháng về dạng "Tháng 03" hoặc "Tháng 3" tùy theo database của ông đang lưu
$monthSearch = "Tháng " . ($monthNum < 10 ? "0" . $monthNum : $monthNum);
$monthSearchAlt = "Tháng " . $monthNum;

try {
    $sql = "SELECT status as is_paid, week1, week2, week3, week4 
            FROM payments 
            WHERE user_id = :user_id 
            AND (month = :m1 OR month = :m2)
            AND year = :year 
            LIMIT 1";
            
    $stmt = $conn->prepare($sql);
    $stmt->execute([
        'user_id' => $user_id,
        'm1' => $monthSearch,
        'm2' => $monthSearchAlt,
        'year' => $yearStr
    ]);
    
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        echo json_encode([
            "is_paid" => intval($result['is_paid']),
            "week1"   => intval($result['week1']),
            "week2"   => intval($result['week2']),
            "week3"   => intval($result['week3']),
            "week4"   => intval($result['week4']),
        ]);
    } else {
        echo json_encode(["is_paid" => 0, "week1" => 0, "week2" => 0, "week3" => 0, "week4" => 0]);
    }
} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>