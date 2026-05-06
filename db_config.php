<?php

$host = "localhost";
$db_name = "dacs3"; // Tên database trong hình của bạn
$username = "root";
$password = ""; // Để trống nếu dùng XAMPP mặc định

try {
    $conn = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->exec("set names utf8");
} catch(PDOException $exception) {
    echo "Kết nối lỗi: " . $exception->getMessage();
}
?>