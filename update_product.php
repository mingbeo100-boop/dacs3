<?php
include_once 'db_config.php'; 
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

$method = $_SERVER['REQUEST_METHOD'];
// Cấu hình giống với file manage_tickets để đồng bộ hệ thống
$server_base = "http:// 172.16.0.226/dacs3/";
$upload_path = "uploads/marketplace/"; 

if ($method == 'POST') {
    $id = $_POST['id'] ?? '';
    $title = $_POST['title'] ?? '';
    $description = $_POST['description'] ?? '';
    $price = $_POST['price'] ?? '';
    $full_image_url = null;

    if (empty($id) || empty($title) || empty($price)) {
        echo json_encode(["status" => "error", "message" => "Thiếu thông tin bắt buộc (ID, Tiêu đề, Giá)"]);
        exit;
    }

    try {
        // 1. Xử lý upload ảnh mới (nếu có)
        if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
            if (!file_exists($upload_path)) {
                mkdir($upload_path, 0777, true);
            }

            $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
            $new_image_name = "item_" . time() . "_" . uniqid() . '.' . $file_extension;
            $destination = $upload_path . $new_image_name;

            if (move_uploaded_file($_FILES["image"]["tmp_name"], $destination)) {
                // Tạo full link để lưu vào database
                $full_image_url = $server_base . $upload_path . $new_image_name;
            } else {
                echo json_encode(["status" => "error", "message" => "Không thể lưu file ảnh vào server"]);
                exit;
            }
        }

        // 2. Xây dựng câu lệnh SQL cập nhật
        if ($full_image_url) {
            // Trường hợp có ảnh mới -> Cập nhật cả link ảnh
            $query = "UPDATE marketplace SET title = :title, description = :desc, price = :price, image_url = :img WHERE id = :id";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':img', $full_image_url);
        } else {
            // Trường hợp KHÔNG có ảnh mới -> Giữ nguyên ảnh cũ
            $query = "UPDATE marketplace SET title = :title, description = :desc, price = :price WHERE id = :id";
            $stmt = $conn->prepare($query);
        }

        // Gán các biến chung
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':desc', $description);
        $stmt->bindParam(':price', $price);
        $stmt->bindParam(':id', $id);

        if ($stmt->execute()) {
            echo json_encode([
                "status" => "success", 
                "message" => "Cập nhật sản phẩm thành công!",
                "new_url" => $full_image_url // Trả về link mới để Flutter update UI nếu cần
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Không thể cập nhật database"]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Lỗi Database: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Yêu cầu phương thức POST"]);
}
?>