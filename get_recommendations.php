<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

try {
    // 1. Lấy thói quen của chính mình
    $stmt = $conn->prepare("SELECT * FROM student_preferences WHERE user_id = :id");
    $stmt->execute(['id' => $user_id]);
    $my = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$my) { echo json_encode([]); exit; }

    $vA = [$my['sleep_time'], $my['wakeup_time'], $my['study_habit'], $my['tech_stack'], $my['cleanliness'], $my['smoking'], $my['gaming_level'], $my['music_volume'], $my['social_index']];

    // 2. QUAN TRỌNG: Lấy thêm cột room_id từ bảng profiles
    // Trong get_recommendations.php, hãy sửa đoạn SELECT như sau:
$stmt = $conn->prepare("SELECT pref.*, prof.fullname, prof.avatar_url, prof.room_id 
                        FROM student_preferences pref
                        JOIN profiles prof ON pref.user_id = prof.user_id 
                        WHERE pref.user_id != :id");
    $stmt->execute(['id' => $user_id]);
    $others = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $results = [];
    foreach ($others as $row) {
        $vB = [$row['sleep_time'], $row['wakeup_time'], $row['study_habit'], $row['tech_stack'], $row['cleanliness'], $row['smoking'], $row['gaming_level'], $row['music_volume'], $row['social_index']];

        $dotProduct = 0; $normA = 0; $normB = 0;
        for ($i = 0; $i < count($vA); $i++) {
            $dotProduct += $vA[$i] * $vB[$i];
            $normA += pow($vA[$i], 2);
            $normB += pow($vB[$i], 2);
        }
        $similarity = $dotProduct / (sqrt(max($normA, 0.0001)) * sqrt(max($normB, 0.0001)));
        
        if ($similarity > 0.5) {
            $results[] = [
                "fullname" => $row['fullname'],
                "avatar" => $row['avatar_url'] ?? "",
                "room_id" => $row['room_id'] ?? "Chưa rõ", // ĐÃ THÊM DÒNG NÀY
                "match_score" => round($similarity * 100, 1)
            ];
        }
    }
    usort($results, fn($a, $b) => $b['match_score'] <=> $a['match_score']);
    echo json_encode($results);
} catch (PDOException $e) { echo json_encode(["error" => $e->getMessage()]); }
?>