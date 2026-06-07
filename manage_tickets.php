<?php
include_once 'db_config.php'; 
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

$method = $_SERVER['REQUEST_METHOD'];
// Long nhớ kiểm tra IP máy tính (ipconfig) và sửa ở đây cho đúng
$server_base = "http:// 172.16.0.226/dacs3/";
$upload_path = "uploads/tickets/"; 

if ($method == 'GET') {
    $role = $_GET['role'] ?? 'student';
    if ($role == 'admin') {
        $sql = "SELECT t.*, u.fullname FROM tickets t LEFT JOIN users u ON t.user_id = u.id ORDER BY t.created_at DESC";
        $stmt = $conn->prepare($sql);
        $stmt->execute();
    } else {
        $room_id = $_GET['room_id'] ?? '';
        $sql = "SELECT * FROM tickets WHERE room_id = ? ORDER BY created_at DESC";
        $stmt = $conn->prepare($sql);
        $stmt->execute([$room_id]);
    }
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} 
else if ($method == 'POST') {
    $room_id = $_POST['room_id'] ?? 'N/A';
    $content = $_POST['content'] ?? '';
    $category = $_POST['category'] ?? 'Khác';
    $user_id = $_POST['user_id'] ?? 0;
    $full_image_url = ""; 

    if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
        if (!file_exists($upload_path)) mkdir($upload_path, 0777, true);
        $ext = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
        $new_name = "tk_" . time() . "." . $ext;
        if (move_uploaded_file($_FILES["image"]["tmp_name"], $upload_path . $new_name)) {
            $full_image_url = $server_base . $upload_path . $new_name;
        }
    }
    $sql = "INSERT INTO tickets (user_id, room_id, category, content, image_url, status) VALUES (?, ?, ?, ?, ?, 'pending')";
    $stmt = $conn->prepare($sql);
    $stmt->execute([$user_id, $room_id, $category, $content, $full_image_url]);
    echo json_encode(["status" => "success"]);
}
?>