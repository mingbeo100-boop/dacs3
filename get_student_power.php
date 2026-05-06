<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include_once 'db_config.php';

$room_id = $_GET['room_id'] ?? '';
$month = (int)date('m');
$year = (int)date('Y');

if ($room_id != '') {
    try {
        // 1. LẤY TỔNG ĐIỆN NĂNG LIVE
        $sql_total = "SELECT SUM(total_kwh) as room_total FROM devices WHERE room_id = :room_id";
        $stmt_total = $conn->prepare($sql_total);
        $stmt_total->execute(['room_id' => $room_id]);
        $row_total = $stmt_total->fetch(PDO::FETCH_ASSOC);
        $total_live = ($row_total && $row_total['room_total']) ? floatval($row_total['room_total']) : 0.0;

        // 2. LẤY HÓA ĐƠN VÀ TRẠNG THÁI
        $sql_invoice = "SELECT id, amount, status FROM invoices 
                        WHERE room_id = :room_id AND billing_month = :month AND billing_year = :year LIMIT 1";
        $stmt_inv = $conn->prepare($sql_invoice);
        $stmt_inv->execute(['room_id' => $room_id, 'month' => $month, 'year' => $year]);
        $invoice = $stmt_inv->fetch(PDO::FETCH_ASSOC);
        
        $payment_amount = $invoice ? floatval($invoice['amount']) : ($total_live * 3000);
        $payment_status = $invoice ? (int)$invoice['status'] : 0;
        $invoice_id = $invoice ? $invoice['id'] : "";

        // 3. LẤY LỊCH SỬ 7 NGÀY (BIỂU ĐỒ)
        $sql_history = "SELECT usage_kwh FROM power_usage_history WHERE room_id = :room_id ORDER BY recorded_at DESC LIMIT 7";
        $stmt_h = $conn->prepare($sql_history);
        $stmt_h->execute(['room_id' => $room_id]);
        $history_rows = $stmt_h->fetchAll(PDO::FETCH_COLUMN);
        $seven_day_history = !empty($history_rows) ? array_reverse($history_rows) : [0.5, 1.2, 0.8, 2.5, 1.8, 2.2, 3.0];

        // 4. PHÂN TÍCH THIẾT BỊ & TẠO KHUYẾN NGHỊ
        $sql_devices = "SELECT device_name, total_kwh FROM devices WHERE room_id = :room_id ORDER BY total_kwh DESC";
        $stmt_devices = $conn->prepare($sql_devices);
        $stmt_devices->execute(['room_id' => $room_id]);
        $device_list = $stmt_devices->fetchAll(PDO::FETCH_ASSOC);

        $breakdown = [];
        $recs = []; 
        
        foreach ($device_list as $dev) {
            $p_val = ($total_live > 0) ? round(($dev['total_kwh'] / $total_live) * 100, 1) : 0;
            $name = $dev['device_name'];
            $breakdown[] = ["name" => $name, "percent" => $p_val . "%"];

            // 1. Hạ thấp tỉ lệ % để dễ xuất hiện gợi ý hơn (Ví dụ từ 60% xuống 40%)
            if (strpos(strtolower($name), 'điều hòa') !== false && $p_val > 40) {
                $recs[] = "Điều hòa đang chiếm $p_val% điện năng. Nên để nhiệt độ 26-27°C nhé!";
            }
            
            // 2. Tương tự với hệ thống đèn (Ví dụ hạ xuống 10%)
            if (strpos(strtolower($name), 'đèn') !== false && $p_val > 10) {
                $recs[] = "Hệ thống đèn đang dùng $p_val% tổng điện. Nhớ tắt khi không có người trong phòng.";
            }

            // 3. Gợi ý cho quạt máy nếu dùng nhiều
            if (strpos(strtolower($name), 'quạt') !== false && $p_val > 5) {
                $recs[] = "Quạt máy đang chạy khá nhiều. Bạn có thể mở cửa sổ để lấy gió tự nhiên.";
            }
        }
        
        // 4. Hạ thấp mức tiền điện để dễ báo động (Ví dụ hạ từ 1.5 triệu xuống 500k)
        if ($payment_amount > 500000) {
            $recs[] = "Tiền điện tháng này đã vượt mức 500k. Hãy chú ý tiết kiệm nhé!";
        }

        // Nếu không có lỗi gì thì mới hiện lời khen
        if (empty($recs)) {
            $recs[] = "Phòng bạn đang sử dụng điện rất hợp lý. Tuyệt vời!";
        }
        if (empty($recs)) $recs[] = "Phòng bạn đang sử dụng điện rất hợp lý. Tuyệt vời!";

        echo json_encode([
            "status" => "success",
            "total_kwh" => $total_live,
            "amount" => $payment_amount,
            "invoice_id" => $invoice_id,
            "payment_status" => $payment_status,
            "seven_day_history" => $seven_day_history,
            "device_breakdown" => $breakdown,
            "recommendations" => $recs,
            "updated_at" => date("Y-m-d H:i:s")
        ]);
    } catch (PDOException $e) { echo json_encode(["status" => "error", "message" => $e->getMessage()]); }
} else { echo json_encode(["status" => "error", "message" => "Missing room_id"]); }
?>