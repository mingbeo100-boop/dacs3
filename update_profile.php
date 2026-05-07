<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$user_id = $_POST['user_id'] ?? '';

if (empty($user_id)) {
    echo json_encode(["success" => false, "message" => "Thiếu ID người dùng"]);
    exit();
}

$updates = [];
$params = [];

// 1. Kiểm tra các trường văn bản (Chỉ thêm nếu có dữ liệu gửi lên)
if (!empty($_POST['fullname'])) {
    $updates[] = "fullname = ?";
    $params[] = $_POST['fullname'];
}
if (!empty($_POST['phone'])) {
    $updates[] = "phone = ?";
    $params[] = $_POST['phone'];
}
if (!empty($_POST['cccd'])) {
    $updates[] = "cccd = ?";
    $params[] = $_POST['cccd'];
}
if (!empty($_POST['room_id'])) {
    $updates[] = "room_id = ?";
    $params[] = $_POST['room_id'];
}
if (!empty($_POST['email'])) {
    $updates[] = "email_contact = ?";
    $params[] = $_POST['email'];
}

// 2. Xử lý Upload ảnh và tạo Full Link IP
if (isset($_FILES['avatar'])) {
    $target_dir = "uploads/profiles/";
    if (!file_exists($target_dir)) { 
        mkdir($target_dir, 0777, true); 
    }
    
    $file_ext = pathinfo($_FILES["avatar"]["name"], PATHINFO_EXTENSION);
    $new_filename = "avatar_" . $user_id . "_" . time() . "." . $file_ext;
    $target_file = $target_dir . $new_filename;
    
    if (move_uploaded_file($_FILES["avatar"]["tmp_name"], $target_file)) {
        // --- ĐÂY LÀ PHẦN QUAN TRỌNG NHẤT NHẬT LONG CẦN ---
        
        $full_url = "http://192.168.4.21/dacs3/" . $target_file;
        
        $updates[] = "avatar_url = ?";
        $params[] = $full_url; 
    }
}

// 3. Thực hiện cập nhật vào Database
if (empty($updates)) {
    echo json_encode(["success" => false, "message" => "Không có thông tin nào thay đổi"]);
    exit();
}

try {
    $sql = "UPDATE profiles SET " . implode(", ", $updates) . " WHERE user_id = ?";
    $params[] = $user_id;

    $stmt = $conn->prepare($sql);
    if ($stmt->execute($params)) {
        echo json_encode(["success" => true, "message" => "Cập nhật thành công!"]);
    } else {
        echo json_encode(["success" => false, "message" => "Lỗi thực thi SQL"]);
    }
} catch (PDOException $e) {
    echo json_encode(["success" => false, "message" => "Lỗi hệ thống: " . $e->getMessage()]);
}
?>