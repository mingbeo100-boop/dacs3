<?php
// Cho phép Flutter truy cập (CORS)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once 'db_config.php';

try {
    // Truy vấn lấy dữ liệu sản phẩm kèm tên người đăng
    // Chú dùng alias 'm' cho marketplace và 'u' cho users để code gọn hơn
    $query = "SELECT 
                m.id, 
                m.user_id, 
                m.title, 
                m.description, 
                m.price, 
                m.status, 
                m.image_url, 
                u.fullname 
              FROM marketplace m 
              JOIN users u ON m.user_id = u.id 
              ORDER BY m.id DESC"; // Sắp xếp ID mới nhất lên đầu
              
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    // Lấy tất cả dữ liệu
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Kiểm tra nếu không có sản phẩm nào thì trả về mảng rỗng [] thay vì null
    if (!$products) {
        echo json_encode([]);
    } else {
        // Trả về danh sách sản phẩm
        echo json_encode($products);
    }

} catch (PDOException $e) {
    // Trả về lỗi 500 nếu DB có vấn đề
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => "Lỗi kết nối cơ sở dữ liệu: " . $e->getMessage()
    ]);
}
?>