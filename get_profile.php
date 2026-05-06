<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$user_id = $_GET['user_id'] ?? '';

if ($user_id != '') {
    // THÊM ĐẦY ĐỦ CÁC CỘT: phone, cccd, email_contact
    $sql = "SELECT fullname, phone, cccd, room_id, email_contact, avatar_url FROM profiles WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->execute([$user_id]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result) {
        // Trả về room_id để Flutter gán vào roomController
        echo json_encode($result);
    } else {
        echo json_encode([
            "fullname" => "N/A",
            "avatar_url" => "",
            "phone" => "",
            "cccd" => "",
            "room_id" => "",
            "email_contact" => ""
        ]);
    }
}
?>