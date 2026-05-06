<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if (!empty($username) && !empty($password)) {
    try {
        $query = "SELECT * FROM users WHERE username = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$username]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Kiểm tra user tồn tại và so sánh mật khẩu mã hóa
        if ($user && password_verify($password, $user['password'])) {
            unset($user['password']); // Bảo mật: không gửi pass về Flutter
            echo json_encode([
                "status" => "success",
                "message" => "Đăng nhập thành công!",
                "user" => $user
            ]);
        } else {
            echo json_encode([
                "status" => "error", 
                "message" => "Mã sinh viên hoặc mật khẩu không chính xác!"
            ]);
        }
    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "message" => "Lỗi kết nối: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Vui lòng nhập đầy đủ thông tin!"]);
}
?>