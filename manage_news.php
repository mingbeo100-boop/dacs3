    <?php
    // Tắt hiển thị lỗi trực tiếp để tránh làm hỏng chuỗi JSON trả về
    error_reporting(0);
    ini_set('display_errors', 0);

    include_once 'db_config.php';

    // Header chuẩn cho Flutter kết nối
    header("Access-Control-Allow-Origin: *");
    header("Content-Type: application/json; charset=utf-8");
    header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

    $method = $_SERVER['REQUEST_METHOD'];

    // Xử lý request nháp (Preflight) của Flutter/Mobile
    if ($method == "OPTIONS") {
        http_response_code(200);
        exit;
    }

    try {
        if ($method == 'GET') {
        // Nếu có tham số all=true thì lấy 5 tin mới nhất
        if (isset($_GET['all'])) {
            $stmt = $conn->query("SELECT id, content FROM dormitory_news ORDER BY id DESC LIMIT 5");
            $news_list = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "success", "news_list" => $news_list]);
        } else {
            // Mặc định lấy 1 tin (để tương thích ngược)
            $stmt = $conn->query("SELECT id, content FROM dormitory_news ORDER BY id DESC LIMIT 1");
            $news = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "success", "id" => $news['id'] ?? null, "content" => $news['content'] ?? ""]);
        }
        exit;
    }

        else if ($method == 'POST') {
            // Đọc dữ liệu từ Body (JSON) hoặc Form-data
            $json_data = json_decode(file_get_contents("php://input"), true);
            $content = $json_data['content'] ?? $_POST['content'] ?? '';

            if (!empty($content)) {
                $stmt = $conn->prepare("INSERT INTO dormitory_news (content) VALUES (?)");
                $stmt->execute([$content]);
                echo json_encode(["status" => "success"]);
            } else {
                echo json_encode(["status" => "error", "message" => "Nội dung trống"]);
            }
            exit;
        }

        else if ($method == 'DELETE') {
            // Lấy ID từ URL hoặc Body
            $json_data = json_decode(file_get_contents("php://input"), true);
            $id = $_GET['id'] ?? $json_data['id'] ?? null;

            if ($id) {
                $stmt = $conn->prepare("DELETE FROM dormitory_news WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(["status" => "success"]);
            } else {
                echo json_encode(["status" => "error", "message" => "Thiếu ID"]);
            }
            exit;
        }
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        exit;
    }
    ?>