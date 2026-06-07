    <?php
    include_once 'db_config.php';

    header('Content-Type: application/json; charset=utf-8');

    // Nhận tháng và năm từ Flutter (Flutter đang gửi dạng số: 3, 2026)
    $monthNum = isset($_GET['month']) ? (int)$_GET['month'] : date('n');
    $yearNum = isset($_GET['year']) ? (int)$_GET['year'] : date('Y');

    // Chuyển số tháng thành chuỗi "Tháng 03" để khớp với kiểu VARCHAR(10) trong DB của bạn
    $monthStr = "Tháng " . ($monthNum < 10 ? "0" . $monthNum : $monthNum);
    $yearStr = (string)$yearNum;

    try {
        // SQL nối bảng Profiles và Users để lấy thông tin SV
        // Sau đó LEFT JOIN với Payments để lấy trạng thái đóng tiền theo tháng/năm
        $sql = "SELECT
                    u.id AS user_id,
                    u.username AS student_code,
                    p.fullname,
                    p.room_id,
                    p.avatar_url,
                    IFNULL(pay.status, 0) AS is_paid
                FROM profiles p
                INNER JOIN users u ON p.user_id = u.id
                LEFT JOIN payments pay ON u.id = pay.user_id
                    AND pay.month = :month
                    AND pay.year = :year
                WHERE p.room_id IS NOT NULL AND p.room_id != ''
                ORDER BY p.room_id ASC";

        $stmt = $conn->prepare($sql);
        $stmt->execute([
            ':month' => $monthStr,
            ':year' => $yearStr
        ]);

        $students = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Trả về danh sách sinh viên
        echo json_encode($students, JSON_UNESCAPED_UNICODE);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => $e->getMessage()]);
    }
    ?>