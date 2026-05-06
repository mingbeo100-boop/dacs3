<?php
include_once 'db_config.php';
header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Asia/Ho_Chi_Minh');

// Nhận tháng năm từ Flutter (ví dụ: month=03&year=2026)
$month = $_GET['month'] ?? date('m');
$year = $_GET['year'] ?? date('Y');

$currentMonth = date('m');
$currentYear = date('Y');

try {
    // 1. LẤY DỮ LIỆU BIỂU ĐỒ 12 THÁNG (Chuẩn hóa trục X từ 1-12)
    $chartData = array_fill(1, 12, 0.0);
    $sqlH = "SELECT month, SUM(usage_kwh) as total FROM power_usage_history WHERE year = :y GROUP BY month";
    $stmtH = $conn->prepare($sqlH);
    $stmtH->execute(['y' => $year]);
    while($rowH = $stmtH->fetch(PDO::FETCH_ASSOC)) {
        $chartData[(int)$rowH['month']] = (double)$rowH['total'];
    }
    
    // Nếu là năm hiện tại, cộng thêm dữ liệu tháng hiện tại vào biểu đồ
    if ($year == $currentYear) {
        $sqlCurrent = "SELECT SUM(total_kwh) as current_total FROM devices";
        $resC = $conn->query($sqlCurrent)->fetch();
        $chartData[(int)$currentMonth] = (double)($resC['current_total'] ?? 0);
    }

    $historyChart = [];
    foreach ($chartData as $m => $u) {
        $historyChart[] = [
            "month" => "T" . str_pad($m, 2, '0', STR_PAD_LEFT), 
            "usage" => round($u, 2)
        ];
    }

    // 2. LẤY CHI TIẾT PHÒNG KÈM TRẠNG THÁI ĐÓNG TIỀN (STATUS)
    if ($month == $currentMonth && $year == $currentYear) {
        // Tháng hiện tại: Lấy điện từ 'devices' và trạng thái từ 'invoices'
        $sqlR = "SELECT 
                    d.room_id as room, 
                    SUM(d.total_kwh) as usage_kwh, 
                    COUNT(d.id) as device_count,
                    COALESCE(i.status, 0) as status
                 FROM devices d
                 LEFT JOIN invoices i ON d.room_id = i.room_id 
                    AND i.billing_month = :m AND i.billing_year = :y
                 GROUP BY d.room_id";
        $stmtR = $conn->prepare($sqlR);
        $stmtR->execute(['m' => (int)$month, 'y' => (int)$year]);
    } else {
        // Tháng cũ: Lấy điện từ 'history' và trạng thái từ 'invoices'
        $sqlR = "SELECT 
                    h.room_id as room, 
                    h.usage_kwh, 
                    0 as device_count,
                    COALESCE(i.status, 0) as status
                 FROM power_usage_history h
                 LEFT JOIN invoices i ON h.room_id = i.room_id 
                    AND i.billing_month = h.month AND i.billing_year = h.year
                 WHERE h.month = :m AND h.year = :y";
        $stmtR = $conn->prepare($sqlR);
        $stmtR->execute(['m' => (int)$month, 'y' => (int)$year]);
    }
    
    $rooms = $stmtR->fetchAll(PDO::FETCH_ASSOC);

    // 3. TÍNH TỔNG CHO BANNER
    $total = 0;
    foreach($rooms as $r) { $total += (double)$r['usage_kwh']; }

    echo json_encode([
        "status" => "success",
        "total_ktx" => round($total, 1),
        "data" => $rooms,
        "history_chart" => $historyChart
    ]);

} catch (PDOException $e) { 
    echo json_encode(["error" => $e->getMessage()]); 
}
?>