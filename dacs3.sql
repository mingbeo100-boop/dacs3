-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th5 06, 2026 lúc 11:34 AM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `dacs3`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `devices`
--

CREATE TABLE `devices` (
  `id` int(11) NOT NULL,
  `room_id` varchar(50) DEFAULT NULL,
  `device_name` varchar(50) DEFAULT NULL,
  `device_type` enum('light','lock','fan','ac') NOT NULL,
  `status` tinyint(1) DEFAULT 0,
  `mqtt_topic` varchar(100) DEFAULT NULL,
  `watt_usage` float DEFAULT 20,
  `last_on_time` timestamp NULL DEFAULT NULL,
  `total_kwh` double(15,8) DEFAULT 0.00000000
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `devices`
--

INSERT INTO `devices` (`id`, `room_id`, `device_name`, `device_type`, `status`, `mqtt_topic`, `watt_usage`, `last_on_time`, `total_kwh`) VALUES
(1, '2_302', 'Bóng đèn', 'light', 1, 'vku/nhatlong/room2302/all', 20, '2026-05-01 08:57:05', 9.39055000),
(2, '2_302', 'Quạt máy', 'fan', 1, 'vku/nhatlong/room2302/all', 65, '2026-05-01 08:57:05', 30.51928749),
(3, '2_302', 'Điều hòa', 'ac', 1, 'vku/nhatlong/room2302/all', 1200, '2026-05-01 08:57:06', 563.40366667),
(4, '2_302', 'Khóa cửa', 'lock', 0, 'vku/nhatlong/room2302/all', 10, NULL, 0.00000833),
(5, '2_421', 'Bóng đèn', 'light', 1, 'vku/nhatlong/room2421/all', 20, '2026-05-01 08:58:57', 0.03548889),
(6, '2_421', 'Quạt máy', 'fan', 1, 'vku/nhatlong/room2421/all', 65, '2026-05-01 08:58:57', 0.11477917),
(7, '2_421', 'Điều hòa', 'ac', 1, 'vku/nhatlong/room2421/all', 1200, '2026-05-01 08:59:03', 2.13033334),
(8, '2_421', 'Khóa cửa', 'lock', 0, 'vku/nhatlong/room2421/all', 10, NULL, 0.00025278),
(9, '2_422', 'Bóng đèn', 'light', 0, 'vku/nhatlong/room2422/all', 20, NULL, 0.00000000),
(10, '2_422', 'Quạt máy', 'fan', 0, 'vku/nhatlong/room2422/all', 65, NULL, 0.00000000),
(11, '2_422', 'Điều hòa', 'ac', 0, 'vku/nhatlong/room2422/all', 1200, NULL, 0.00000000),
(12, '2_422', 'Khóa cửa', 'lock', 0, 'vku/nhatlong/room2422/all', 10, NULL, 0.00000000),
(13, '2_208', 'Bóng đèn', 'light', 0, 'vku/nhatlong/room2208/all', 20, NULL, 9.43590000),
(14, '2_208', 'Quạt máy', 'fan', 0, 'vku/nhatlong/room2208/all', 65, NULL, 30.66665694),
(15, '2_208', 'Điều hòa', 'ac', 0, 'vku/nhatlong/room2208/all', 1200, NULL, 566.15333334),
(16, '2_208', 'Khóa cửa', 'lock', 0, 'vku/nhatlong/room2208/all', 10, NULL, 0.00000000);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `dormitory_news`
--

CREATE TABLE `dormitory_news` (
  `id` int(11) NOT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `dormitory_news`
--

INSERT INTO `dormitory_news` (`id`, `content`, `created_at`) VALUES
(1, 'Hệ thống Smart Dormitory đã đồng bộ dữ liệu phòng mới.', '2026-04-17 05:13:40'),
(3, '\"???? NHẮC ĐÓNG PHÍ NỘI TRÚ: Hiện tại đã đến hạn đóng phí phòng tháng 04/2026. Đề nghị các bạn sinh viên kiểm tra mục \'Sổ tay nội trú\' và hoàn thành thanh toán trước ngày 20 để tránh bị hệ thống tự động ngắt kết nối thiết bị điện.\"', '2026-04-17 05:28:49'),
(4, 'THÔNG BÁO KHẨN: Yêu cầu tất cả sinh viên có mặt tại hội trường tầng 1 vào lúc 19h00 tối nay để phổ biến quy định phòng cháy chữa cháy. Sinh viên vắng mặt không lý do sẽ bị trừ điểm chuyên cần nội trú tháng này.\"', '2026-04-17 05:31:51'),
(5, 'BẢO TRÌ HỆ THỐNG ĐIỆN: Ban quản lý sẽ tiến hành bảo trì trạm biến áp KTX từ 08h00 đến 11h00 sáng Thứ Bảy (18/04). Trong thời gian này, các thiết bị thông minh và hệ thống điều hòa sẽ tạm ngưng hoạt động. Mong các bạn thông cảm.', '2026-04-17 05:32:15');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `invoices`
--

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL,
  `room_id` varchar(20) NOT NULL,
  `type` enum('Electricity','Water','Room') NOT NULL,
  `old_index` double DEFAULT 0,
  `new_index` double DEFAULT 0,
  `consumption` double DEFAULT 0,
  `amount` double NOT NULL,
  `billing_month` int(11) NOT NULL,
  `billing_year` int(11) NOT NULL,
  `due_date` date DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `evidence_img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `invoices`
--

INSERT INTO `invoices` (`id`, `room_id`, `type`, `old_index`, `new_index`, `consumption`, `amount`, `billing_month`, `billing_year`, `due_date`, `status`, `evidence_img`, `created_at`) VALUES
(2, '2_302', 'Electricity', 0, 0, 378.52848055, 1324850, 4, 2026, NULL, 2, 'bl_2_302_T4_1776398661.jpg', '2026-04-17 04:04:00'),
(3, '2_421', 'Electricity', 0, 0, 0.07035141, 246, 4, 2026, NULL, 2, 'bl_2_421_T4_1776398741.jpg', '2026-04-17 04:04:00'),
(4, '2_422', 'Electricity', 0, 0, 0, 0, 4, 2026, NULL, 0, NULL, '2026-04-17 04:04:00'),
(5, '2_208', 'Electricity', 0, 0, 606.25589028, 2121896, 4, 2026, NULL, 2, 'bl_2_208_T4_1776399009.jpg', '2026-04-17 04:09:29'),
(6, '2_208', 'Electricity', 0, 0, 606.25589028, 2121896, 5, 2026, NULL, 0, NULL, '2026-05-01 09:00:57'),
(7, '2_302', 'Electricity', 0, 0, 603.31351249, 2111597, 5, 2026, NULL, 1, 'bl_2_302_T5_1777626535.jpg', '2026-05-01 09:00:57'),
(8, '2_421', 'Electricity', 0, 0, 2.28085418, 7983, 5, 2026, NULL, 2, 'bl_2_421_T5_1777626625.jpg', '2026-05-01 09:00:57'),
(9, '2_422', 'Electricity', 0, 0, 0, 0, 5, 2026, NULL, 0, NULL, '2026-05-01 09:00:57');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `marketplace`
--

CREATE TABLE `marketplace` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `status` enum('available','sold') DEFAULT 'available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `marketplace`
--

INSERT INTO `marketplace` (`id`, `user_id`, `title`, `description`, `price`, `image_url`, `status`, `created_at`) VALUES
(3, 5, 'Tủ lạnh mini', 'Siêu rẻ dễ dùng đẹp', 200.00, '1773824233_69ba68e9004be.jpg', 'available', '2026-03-18 08:57:13'),
(4, 5, 'Bàn học gỗ gấp gọn', 'Bàn gỗ chắc chắn, chân sắt sơn tĩnh điện. Gập lại được khi không dùng cho đỡ chật phòng', 150.00, '1773825063_69ba6c2731231.jpg', 'available', '2026-03-18 09:11:03'),
(5, 5, 'Nồi cơm điện Sharp', 'Dung tích 1.8L, nấu cơm ngon, có xửng hấp kèm theo. Đổi nồi to hơn nên pass lại.', 250.00, '1773825104_69ba6c50b7184.jpg', 'available', '2026-03-18 09:11:44'),
(6, 5, 'Giáo trình Cấu trúc dữ liệu', 'Sách còn mới, không vẽ bậy. Tặng kèm bộ đề cương ôn thi cuối kỳ cho bạn nào mua sớm', 50.00, '1773825146_69ba6c7ace8a8.jpg', 'available', '2026-03-18 09:12:26'),
(7, 5, 'Quạt lửng Senko', 'Quạt chạy êm, gió mạnh, có 3 tốc độ. Vừa thay cánh mới nên chạy rất bốc.', 180.00, '1773825180_69ba6c9c00f73.jpg', 'available', '2026-03-18 09:13:00'),
(8, 5, 'Ấm siêu tốc Lock&Lock', 'Dung tích 1.5L, đun nước siêu nhanh. Vỏ inox bền đẹp, tự động ngắt khi sôi. Rất tiện để pha mì đêm', 120.00, '1773825258_69ba6cea6778a.jpg', 'available', '2026-03-18 09:14:18'),
(9, 5, 'Đèn học chống cận', 'Đèn LED 3 chế độ sáng (trắng, vàng, trung tính). Có khay cắm bút và giá đỡ điện thoại cực tiện lợi.', 90.00, '1773825308_69ba6d1c93f5e.jpg', 'available', '2026-03-18 09:15:08'),
(10, 5, 'Kệ để giày 5 tầng', 'Kệ khung inox chắc chắn, lắp ráp dễ dàng. Để được khoảng 10-12 đôi giày dép cho cả phòng.', 70.00, '1773825344_69ba6d4053e06.jpg', 'available', '2026-03-18 09:15:44'),
(11, 5, 'Loa Bluetooth Marshall', 'Âm thanh cực chất, bass mạnh. Pin dùng liên tục 4-5 tiếng. Ngoại hình mới 98%, pass lại lấy tiền đóng tiền điện.', 350.00, '1773825377_69ba6d615395a.jpg', 'available', '2026-03-18 09:16:17'),
(12, 5, 'Combo 5 móc treo áo quần', 'Móc nhôm loại dày, không gỉ sét. Còn thừa nhiều nên để lại cho bạn nào mới nhập học KTX', 20.00, '1773825402_69ba6d7abf2c0.jpg', 'available', '2026-03-18 09:16:42');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `type` enum('billing','recommend','system') DEFAULT 'system',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `content`, `type`, `is_read`, `created_at`) VALUES
(1, 4, 'NHẮC NHỞ TỪ BAN QUẢN LÝ', 'Bạn chưa hoàn tất học phí nội trú Tháng 04. Vui lòng thanh toán sớm để tránh bị khóa dịch vụ điện!', '', 0, '2026-04-17 05:41:23'),
(2, 4, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:54:19'),
(3, 5, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:54:19'),
(4, 7, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:54:19'),
(5, 11, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:54:19'),
(6, 4, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:55:35'),
(7, 5, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:55:35'),
(8, 7, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:55:35'),
(9, 11, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-17 05:55:35'),
(10, 4, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-24 11:35:48'),
(11, 5, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-24 11:35:48'),
(12, 7, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-24 11:35:48'),
(13, 11, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-04-24 11:35:48'),
(14, 4, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-05-01 09:00:52'),
(15, 5, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-05-01 09:00:52'),
(16, 7, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-05-01 09:00:52'),
(17, 11, '⚠️ CẢNH BÁO TIÊU THỤ ĐIỆN', 'Phòng của bạn đã sử dụng quá 15.0 kWh điện. Hãy chú ý tắt các thiết bị không cần thiết để tiết kiệm điện năng!', '', 0, '2026-05-01 09:00:52');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `month` varchar(10) NOT NULL,
  `year` varchar(10) NOT NULL,
  `status` tinyint(1) DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `week1` tinyint(1) DEFAULT 0 COMMENT 'Tuần 1: 0-Vắng, 1-Có mặt',
  `week2` tinyint(1) DEFAULT 0 COMMENT 'Tuần 2: 0-Vắng, 1-Có mặt',
  `week3` tinyint(1) DEFAULT 0 COMMENT 'Tuần 3: 0-Vắng, 1-Có mặt',
  `week4` tinyint(1) DEFAULT 0 COMMENT 'Tuần 4: 0-Vắng, 1-Có mặt'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `payments`
--

INSERT INTO `payments` (`id`, `user_id`, `month`, `year`, `status`, `updated_at`, `week1`, `week2`, `week3`, `week4`) VALUES
(1, 4, 'Tháng 06', '2026', 1, '2026-03-27 02:50:57', 0, 1, 1, 0),
(2, 5, 'Tháng 05', '2026', 1, '2026-03-27 02:56:58', 0, 1, 0, 1),
(3, 5, 'Tháng 03', '2026', 1, '2026-03-27 04:37:03', 1, 1, 1, 1),
(4, 4, 'Tháng 03', '2026', 1, '2026-03-27 04:51:59', 1, 0, 1, 0),
(5, 4, 'Tháng 03', '2026', 1, '2026-04-03 02:52:16', 0, 0, 0, 0),
(6, 8, 'Tháng 03', '2026', 1, '2026-04-03 05:38:40', 0, 0, 1, 1),
(7, 11, 'Tháng 03', '2026', 1, '2026-04-17 02:24:21', 0, 0, 1, 1),
(8, 11, 'Tháng 04', '2026', 1, '2026-04-17 04:32:33', 0, 1, 1, 0),
(9, 8, 'Tháng 04', '2026', 1, '2026-04-17 04:33:16', 0, 1, 0, 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `power_usage`
--

CREATE TABLE `power_usage` (
  `id` int(11) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `consumption` float DEFAULT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `power_usage_history`
--

CREATE TABLE `power_usage_history` (
  `id` int(11) NOT NULL,
  `room_id` varchar(50) NOT NULL,
  `usage_kwh` double DEFAULT 0,
  `month` varchar(2) NOT NULL,
  `year` varchar(4) NOT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `power_usage_history`
--

INSERT INTO `power_usage_history` (`id`, `room_id`, `usage_kwh`, `month`, `year`, `recorded_at`) VALUES
(1, '2_303', 0, '03', '2026', '2026-03-28 12:40:11'),
(2, '2_208', 0.00180278, '03', '2026', '2026-03-28 12:40:11'),
(3, '2_302', 2.88664583, '03', '2026', '2026-03-28 12:40:11'),
(4, '2_421', 0.03299028, '03', '2026', '2026-03-28 12:40:11'),
(5, '2_208', 0.00180278, '04', '2026', '2026-04-17 03:44:29'),
(6, '2_302', 378.52848055, '04', '2026', '2026-04-17 03:44:29'),
(7, '2_421', 0.07035141, '04', '2026', '2026-04-17 03:44:29'),
(8, '2_422', 0, '04', '2026', '2026-04-17 03:44:29');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `profiles`
--

CREATE TABLE `profiles` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `fullname` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `cccd` varchar(20) DEFAULT NULL,
  `room_id` varchar(50) DEFAULT NULL,
  `email_contact` varchar(255) DEFAULT NULL,
  `avatar_url` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_paid` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `profiles`
--

INSERT INTO `profiles` (`id`, `user_id`, `fullname`, `phone`, `cccd`, `room_id`, `email_contact`, `avatar_url`, `updated_at`, `is_paid`) VALUES
(1, 5, 'Trần Nhật Long', '0796727753', '046206009484', '2_302', 'longtn.24itb@vku.udn.vn', 'http://192.168.1.191/dacs3/uploads/profiles/avatar_5_1775821361.jpg', '2026-05-02 07:03:03', 0),
(13, 4, 'Nguyễn Tùng Dương', '', '', '2_302', '', 'http://192.168.1.191/dacs3/uploads/profiles/avatar_4_1774356660.jpg', '2026-05-02 07:03:03', 1),
(14, 7, 'Nguyễn Hữu Quyền', NULL, NULL, '2_302', NULL, 'http://192.168.1.191/dacs3/uploads/profiles/avatar_7_1774357533.jpg', '2026-05-02 07:03:03', 1),
(19, 8, 'Bùi Ngọc Nhật Minh', NULL, NULL, '2_421', NULL, 'http://192.168.1.191/dacs3/uploads/profiles/avatar_8_1775821663.jpg', '2026-05-02 07:03:03', 0),
(20, 9, 'Trần Viết Thành', NULL, NULL, '2_421', NULL, 'http://192.168.1.191/dacs3/uploads/profiles/avatar_9_1775821683.jpg', '2026-05-02 07:03:03', 0),
(21, 10, 'Nguyễn Thiên Nhật', NULL, NULL, '2_422', NULL, 'http://192.168.1.191/dacs3/uploads/profiles/avatar_10_1775821641.jpg', '2026-05-02 07:03:03', 0),
(22, 11, 'Nguyễn Xuân Anh Khôi', NULL, NULL, '2_208', NULL, 'http://192.168.1.191/dacs3/uploads/profiles/avatar_11_1775821760.jpg', '2026-05-02 07:03:03', 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `rooms`
--

CREATE TABLE `rooms` (
  `id` int(11) NOT NULL,
  `room_number` varchar(10) NOT NULL,
  `floor` int(11) DEFAULT NULL,
  `max_occupants` int(11) DEFAULT 4,
  `current_occupants` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `rooms`
--

INSERT INTO `rooms` (`id`, `room_number`, `floor`, `max_occupants`, `current_occupants`) VALUES
(1, '2_302', 3, 4, 1),
(2, '2_421', NULL, 4, 0),
(2303, '2_422', NULL, 4, 0),
(2304, '2_208', NULL, 4, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `room_analytics`
--

CREATE TABLE `room_analytics` (
  `room_id` varchar(20) NOT NULL,
  `avg_sleep_vector` float DEFAULT NULL,
  `avg_clean_vector` float DEFAULT NULL,
  `power_usage_type` int(11) DEFAULT NULL,
  `room_atmosphere` varchar(50) DEFAULT NULL,
  `is_full` tinyint(1) DEFAULT 0,
  `current_occupants` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `student_preferences`
--

CREATE TABLE `student_preferences` (
  `user_id` int(11) NOT NULL,
  `sleep_time` int(11) DEFAULT NULL,
  `wakeup_time` int(11) DEFAULT NULL,
  `study_habit` int(11) DEFAULT NULL,
  `tech_stack` int(11) DEFAULT NULL,
  `cleanliness` int(11) DEFAULT NULL,
  `smoking` int(11) DEFAULT 0,
  `gaming_level` int(11) DEFAULT NULL,
  `music_volume` int(11) DEFAULT NULL,
  `social_index` int(11) DEFAULT NULL,
  `last_updated` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `student_preferences`
--

INSERT INTO `student_preferences` (`user_id`, `sleep_time`, `wakeup_time`, `study_habit`, `tech_stack`, `cleanliness`, `smoking`, `gaming_level`, `music_volume`, `social_index`, `last_updated`) VALUES
(4, 2, 2, 2, 3, 1, 0, 1, 2, 3, '2026-04-03 10:40:50'),
(7, 1, 1, 2, 1, 3, 0, 0, 2, 3, '2026-04-03 10:40:22'),
(8, 1, 3, 2, 1, 2, 0, 1, 1, 3, '2026-04-03 10:50:55'),
(9, 1, 2, 3, 1, 1, 0, 1, 3, 1, '2026-04-03 12:07:45'),
(10, 3, 3, 2, 1, 1, 1, 2, 3, 2, '2026-04-03 12:42:30'),
(11, 1, 2, 3, 3, 2, 1, 2, 1, 2, '2026-04-03 12:37:17');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `student_status`
--

CREATE TABLE `student_status` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `month` varchar(10) NOT NULL,
  `year` varchar(10) NOT NULL,
  `is_paid` int(1) DEFAULT 0,
  `week1` int(1) DEFAULT 0,
  `week2` int(1) DEFAULT 0,
  `week3` int(1) DEFAULT 0,
  `week4` int(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `student_status`
--

INSERT INTO `student_status` (`id`, `user_id`, `month`, `year`, `is_paid`, `week1`, `week2`, `week3`, `week4`) VALUES
(1, 1, 'Tháng 03', '2026', 1, 1, 0, 1, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tickets`
--

CREATE TABLE `tickets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `room_id` varchar(20) DEFAULT NULL,
  `category` varchar(50) DEFAULT NULL,
  `content` text NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `status` enum('pending','processing','completed') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `tickets`
--

INSERT INTO `tickets` (`id`, `user_id`, `room_id`, `category`, `content`, `image_url`, `status`, `created_at`) VALUES
(1, 4, '2_302', 'Khác', 'den hong ', '', 'completed', '2026-05-01 08:35:21'),
(2, 8, '2_421', 'Khác', 'Voi nuoc hu ', '', 'completed', '2026-05-01 08:36:09'),
(11, 4, '2_302', 'Kỹ thuật', 'hu voi', '', 'pending', '2026-05-01 10:15:46'),
(12, 4, '2_302', 'Kỹ thuật', 'hu voi', '', 'pending', '2026-05-01 10:16:01'),
(13, 4, '2_302', 'Kỹ thuật', 'hu voi nghiem trong', 'http://192.168.1.191/dacs3/uploads/tickets/ticket_1777705903_4490.jpg', 'pending', '2026-05-02 07:11:43');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `fullname` varchar(100) DEFAULT NULL,
  `role` enum('admin','student') DEFAULT 'student',
  `is_paid` tinyint(1) DEFAULT 0,
  `room_id` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `fullname`, `role`, `is_paid`, `room_id`, `created_at`) VALUES
(1, '24IT', '32', 'e', 'student', 0, '3', '2026-03-14 07:25:35'),
(4, '24IT045', '$2y$10$d5MEhAE091forkrgqi/IG.//iJAygU1Aas7ziN81lYwNxShBQRRK.', 'Nguyễn Tùng Dương', 'student', 0, '2_302', '2026-03-18 10:49:33'),
(5, '24ITB103', '$2y$10$f9KHRBF6vcVF8tIPZtdSv.28X2BXCVDF2bEpJxeHydhaVAh1m5z0C', 'Trần Nhật Long', 'admin', 0, '2_302', '2026-03-18 12:00:29'),
(7, '24IC049', '$2y$10$v6ACPSw4T3efxuTG6qmpiuYF6XOvdpUGPmbtJ9cjSa1yaz2xSr/UW', 'Nguyễn Hữu Quyền', 'student', 0, '2_302', '2026-03-24 12:52:05'),
(8, '24IT158', '$2y$10$1QmxvS2.lpj1nn4ZzU0bEecWhUgU6.B5QStqReFUWCBSfMuDSC0ga', 'Bùi Ngọc Nhật Minh', 'student', 0, '2_421', '2026-03-28 10:07:07'),
(9, '24IT250', '$2y$10$yimqO9Jl.5m0ztDPQFUmT.5D1wvztiwalLTt2fD7rVh4Ud9iT4CJS', 'Trần Viết Thành', 'student', 0, '2_421', '2026-03-28 12:02:47'),
(10, '22CE058', '$2y$10$NdJWceUP0XNFTKy68Vk8k.N9fNNC6v.iWTu9iyyiAb/wNjSTYyVyW', 'Nguyễn Thiên Nhật', 'student', 0, '2_422', '2026-03-28 12:11:13'),
(11, '25ITE031', '$2y$10$tWH6SC0Y5221Yn8WS3tP5.F9Ht10gMNIISJHuTOyn5RxOyhU2OfNC', 'Nguyễn Xuân Anh Khôi', 'student', 0, '2_208', '2026-03-28 12:18:12');

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `room_id` (`room_id`);

--
-- Chỉ mục cho bảng `dormitory_news`
--
ALTER TABLE `dormitory_news`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `marketplace`
--
ALTER TABLE `marketplace`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `power_usage`
--
ALTER TABLE `power_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `room_id` (`room_id`);

--
-- Chỉ mục cho bảng `power_usage_history`
--
ALTER TABLE `power_usage_history`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `profiles`
--
ALTER TABLE `profiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD UNIQUE KEY `cccd` (`cccd`);

--
-- Chỉ mục cho bảng `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `room_number` (`room_number`);

--
-- Chỉ mục cho bảng `room_analytics`
--
ALTER TABLE `room_analytics`
  ADD PRIMARY KEY (`room_id`);

--
-- Chỉ mục cho bảng `student_preferences`
--
ALTER TABLE `student_preferences`
  ADD PRIMARY KEY (`user_id`);

--
-- Chỉ mục cho bảng `student_status`
--
ALTER TABLE `student_status`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_student_month` (`user_id`,`month`,`year`);

--
-- Chỉ mục cho bảng `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `devices`
--
ALTER TABLE `devices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT cho bảng `dormitory_news`
--
ALTER TABLE `dormitory_news`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT cho bảng `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT cho bảng `marketplace`
--
ALTER TABLE `marketplace`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT cho bảng `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT cho bảng `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT cho bảng `power_usage`
--
ALTER TABLE `power_usage`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `power_usage_history`
--
ALTER TABLE `power_usage_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT cho bảng `profiles`
--
ALTER TABLE `profiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT cho bảng `rooms`
--
ALTER TABLE `rooms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2305;

--
-- AUTO_INCREMENT cho bảng `student_status`
--
ALTER TABLE `student_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT cho bảng `tickets`
--
ALTER TABLE `tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `marketplace`
--
ALTER TABLE `marketplace`
  ADD CONSTRAINT `marketplace_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Các ràng buộc cho bảng `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Các ràng buộc cho bảng `power_usage`
--
ALTER TABLE `power_usage`
  ADD CONSTRAINT `power_usage_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`);

--
-- Các ràng buộc cho bảng `profiles`
--
ALTER TABLE `profiles`
  ADD CONSTRAINT `fk_profile_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `student_preferences`
--
ALTER TABLE `student_preferences`
  ADD CONSTRAINT `student_preferences_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
