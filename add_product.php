<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

// Lấy dữ liệu từ POST
$user_id = $_POST['user_id'] ?? '';
$title = $_POST['title'] ?? '';
$description = $_POST['description'] ?? '';
$price = $_POST['price'] ?? '';
$image_name = ""; // Mặc định để trống nếu không có ảnh

if(!empty($user_id) && !empty($title) && !empty($price)) {
    try {
        // --- BƯỚC 1: XỬ LÝ UPLOAD FILE ẢNH ---
        if (isset($_FILES['image'])) {
            $target_dir = "uploads/";
            
            // Tạo thư mục 'uploads' nếu chưa có
            if (!file_exists($target_dir)) {
                mkdir($target_dir, 0777, true);
            }

            // Tạo tên file duy nhất bằng time() để tránh trùng lặp
            $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
            $image_name = time() . '_' . uniqid() . '.' . $file_extension;
            $target_file = $target_dir . $image_name;

            // Di chuyển file từ thư mục tạm sang thư mục uploads
            move_uploaded_file($_FILES["image"]["tmp_name"], $target_file);
        }

        // --- BƯỚC 2: LƯU VÀO DATABASE ---
        // Lưu ý: Chú dùng biến $image_name cho cột image_url
        $query = "INSERT INTO marketplace (user_id, title, description, price, status, image_url) 
                  VALUES (:uid, :title, :desc, :price, 'available', :img)";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':uid', $user_id);
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':desc', $description);
        $stmt->bindParam(':price', $price);
        $stmt->bindParam(':img', $image_name); // Lưu tên file ảnh vào đây

        if($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Đã đăng bài kèm ảnh thành công!"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Lỗi lưu dữ liệu"]);
        }
    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Vui lòng nhập đủ Title và Price"]);
}
?>