<?php
include_once 'db_config.php';

$invoice_id = $_POST['invoice_id'];

try {
    // Chuyển status thành 2 (Đã thanh toán thành công)
    $sql = "UPDATE invoices SET status = 2 WHERE id = :id";
    $stmt = $conn->prepare($sql);
    $result = $stmt->execute(['id' => $invoice_id]);

    if ($result) {
        echo json_encode(["success" => true, "message" => "Duyệt thanh toán thành công!"]);
    }
} catch (PDOException $e) {
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>