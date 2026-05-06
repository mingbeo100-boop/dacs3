<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$product_id = $_POST['id'] ?? '';

if(!empty($product_id)) {
    try {
        // Lấy tên ảnh trước khi xóa để dọn dẹp thư mục uploads
        $query_img = "SELECT image_url FROM marketplace WHERE id = :id";
        $stmt_img = $conn->prepare($query_img);
        $stmt_img->execute([':id' => $product_id]);
        $row = $stmt_img->fetch(PDO::FETCH_ASSOC);

        // Thực hiện xóa trong DB
        $query = "DELETE FROM marketplace WHERE id = :id";
        $stmt = $conn->prepare($query);
        
        if($stmt->execute([':id' => $product_id])) {
            // Nếu xóa DB xong, xóa luôn file ảnh vật lý trong thư mục uploads cho nhẹ máy
            if(!empty($row['image_url'])) {
                @unlink("uploads/" . $row['image_url']);
            }
            echo json_encode(["status" => "success", "message" => "Đã xóa sản phẩm!"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Không thể xóa"]);
        }
    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>