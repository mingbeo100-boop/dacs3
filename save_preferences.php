<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

// Nhận toàn bộ dữ liệu từ Flutter gửi lên
$user_id       = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$sleep_time    = isset($_POST['sleep_time']) ? intval($_POST['sleep_time']) : 2;
$wakeup_time   = isset($_POST['wakeup_time']) ? intval($_POST['wakeup_time']) : 2;
$study_habit   = isset($_POST['study_habit']) ? intval($_POST['study_habit']) : 2;
$tech_stack    = isset($_POST['tech_stack']) ? intval($_POST['tech_stack']) : 1;
$cleanliness   = isset($_POST['cleanliness']) ? intval($_POST['cleanliness']) : 2;
$smoking       = isset($_POST['smoking']) ? intval($_POST['smoking']) : 0;
$gaming_level  = isset($_POST['gaming_level']) ? intval($_POST['gaming_level']) : 1;
$music_volume  = isset($_POST['music_volume']) ? intval($_POST['music_volume']) : 1;
$social_index  = isset($_POST['social_index']) ? intval($_POST['social_index']) : 2;

if ($user_id == 0) {
    echo json_encode(["status" => "error", "message" => "Không tìm thấy ID người dùng"]);
    exit;
}

try {
    // Sử dụng câu lệnh INSERT ... ON DUPLICATE KEY UPDATE 
    // Giúp tự động cập nhật nếu đã có dữ liệu, hoặc tạo mới nếu chưa có
    $sql = "INSERT INTO student_preferences (
                user_id, sleep_time, wakeup_time, study_habit, tech_stack, 
                cleanliness, smoking, gaming_level, music_volume, social_index, last_updated
            ) 
            VALUES (
                :id, :sleep, :wakeup, :study, :tech, 
                :clean, :smoke, :game, :music, :social, NOW()
            )
            ON DUPLICATE KEY UPDATE 
                sleep_time   = :sleep,
                wakeup_time  = :wakeup,
                study_habit  = :study,
                tech_stack   = :tech,
                cleanliness  = :clean,
                smoking      = :smoke,
                gaming_level = :game,
                music_volume = :music,
                social_index = :social,
                last_updated = NOW()";

    $stmt = $conn->prepare($sql);
    $stmt->execute([
        'id'     => $user_id,
        'sleep'  => $sleep_time,
        'wakeup' => $wakeup_time,
        'study'  => $study_habit,
        'tech'   => $tech_stack,
        'clean'  => $cleanliness,
        'smoke'  => $smoking,
        'game'   => $gaming_level,
        'music'  => $music_volume,
        'social' => $social_index
    ]);

    echo json_encode([
        "status" => "success", 
        "message" => "Hồ sơ thói quen đã được lưu thành công!"
    ]);

} catch (PDOException $e) {
    // Trả về lỗi chi tiết nếu câu lệnh SQL gặp vấn đề
    echo json_encode([
        "status" => "error", 
        "message" => "Lỗi cơ sở dữ liệu: " . $e->getMessage()
    ]);
}
?>