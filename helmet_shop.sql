-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: db:3306
-- Generation Time: May 05, 2024 at 03:58 PM
-- Server version: 8.4.0
-- PHP Version: 8.2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `helmet_shop`
--

DELIMITER $$
--
-- Procedures
--
CREATE PROCEDURE `SP_DOANH_THU` (IN `ngaybatdau` DATE, IN `ngayketthuc` DATE)  NO SQL
SELECT MONTH(created_at) AS THANG, YEAR(created_at) AS NAM, ROUND(SUM(total),2) AS DOANHTHU
		FROM orders as O
		WHERE DATE(O.created_at)>= ngaybatdau AND DATE(O.created_at)<= ngayketthuc AND status != '4'
		GROUP BY MONTH(created_at)$$

CREATE PROCEDURE `SP_GIAO_HANG` (IN `maquan` VARCHAR(20) CHARSET utf8)  NO SQL
SELECT id_employee, E.name, ifnull(A.chuagiao,0) DONCHUAGIAO, ifnull(B.hoantat,0) DONHOANTAT, ifnull((ifnull(A.chuagiao,0) + ifnull(B.hoantat,0)),0) TONGSODON
FROM division_detail DV
LEFT JOIN employee E ON E.id = DV.id_employee

LEFT JOIN (SELECT id_shipper, COUNT(id_shipper) chuagiao FROM orders WHERE status=1 OR status=2 GROUP BY id_shipper) A ON A.id_shipper = DV.id_employee

LEFT JOIN (SELECT id_shipper, COUNT(id_shipper) hoantat FROM orders WHERE status=3 GROUP BY id_shipper) B ON B.id_shipper = DV.id_employee

WHERE district_code = maquan COLLATE utf8_unicode_ci 
ORDER BY A.chuagiao ASC, TONGSODON ASC, B.hoantat ASC$$

CREATE PROCEDURE `SP_LOI_NHUAN` (IN `ngaybatdau` DATE)  NO SQL
SELECT P.product_code, P.name, ifnull(SL,0) TSL, ifnull(XTB,0) DGXTB, ifnull(NTB,0) DGNTB, ifnull(X.SL*(X.XTB - L.NTB),0) LN
FROM products P
INNER JOIN (select IDT.product_code PI, ROUND((SUM(ifnull(IDT.price,0)*ifnull(IDT.quantity_in,0))/ SUM(ifnull(IDT.quantity_in,1))),2) NTB 
           FROM import_detail IDT WHERE import_code in 
           (select import_code from import AS I where DATE(I.created_at) <= ngaybatdau )
           GROUP BY IDT.product_code) L on P.product_code = PI
           
LEFT JOIN (select OD.product_code PC, ROUND((sUM(ifnull(OD.price,0)*ifnull(OD.quantity_out,0))/ SUM(ifnull(quantity_out,1))),2) XTB , SUM(ifnull(OD.quantity_out,0)) SL 
           FROM orders_detail OD WHERE id_order in 
           (select id from orders AS O where O.status != '4' AND DATE(O.created_at) <= ngaybatdau )
           GROUP BY OD.product_code) X on  P.product_code = PC
           ORDER BY product_code$$

CREATE PROCEDURE `SP_SAN_PHAM_BAN` (IN `ngaybatdau` DATE, IN `ngayketthuc` DATE)  NO SQL
SELECT od.product_code,p.name, sum(od.quantity_out) AS SLB
		FROM orders_detail od, orders o, products p 
		WHERE od.id_order=o.id AND p.product_code = od.product_code AND o.status != '4' AND DATE(o.created_at) >= ngaybatdau AND DATE(o.created_at)<=ngayketthuc
		GROUP BY od.product_code 
		ORDER BY od.product_code$$

CREATE PROCEDURE `SP_TON_KHO` (IN `ngaybatdau` DATE)  NO SQL
SELECT C.cate_code, C.name AS cate_name, P.product_code, P.name, ifnull(L.QI,0)AS tongnhap, ifnull(X.QO,0) AS tongxuat, (ifnull(L.QI,0) - ifnull(X.QO,0)) AS tonkho
FROM products P 

LEFT JOIN (select OD.product_code PC, SUM(quantity_out) QO FROM orders_detail OD WHERE id_order in 
           (select id from orders AS O where DATE(O.created_at) <= ngaybatdau and O.status != '4')
           GROUP BY OD.product_code) X on  P.product_code = PC 
           
LEFT JOIN (select IDT.product_code PI, SUM(quantity_in) QI FROM import_detail IDT WHERE import_code in 
           (select import_code from import AS I where DATE(I.created_at) <= ngaybatdau)
           GROUP BY IDT.product_code) L on P.product_code = PI
           
INNER JOIN categories C 
ON P.cate_code = C.cate_code
ORDER BY C.cate_code, P.product_code$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bills`
--

CREATE TABLE `bills` (
  `bill_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `created_at` date NOT NULL,
  `fax` int DEFAULT NULL,
  `id_order` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `cate_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `status` int NOT NULL COMMENT '0: chưa xóa, 1: đã xóa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`cate_code`, `name`, `status`) VALUES
('BT', 'Mũ 3/4 đầu', 0),
('FF', 'Mũ Fullface', 0),
('LC', 'Mũ lật cằm', 0),
('ND', 'Mũ 1/2 đầu', 0),
('TT', 'Mũ trẻ em', 0);

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int NOT NULL,
  `username` varchar(12) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `password` varchar(12) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `gender` enum('Nam','Nữ') CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `district_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `phone` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `status` enum('0','1') CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '0=Chưa kích hoạt\r\n1=Đã kích hoạt',
  `id_role` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `username`, `email`, `password`, `name`, `gender`, `address`, `district_code`, `phone`, `status`, `id_role`) VALUES
(6, 'phipgn', 'phipgn@test.com', '123456', 'Gia Phi', 'Nam', '123 Lò Lu 3', 'Q09', '0982769791', '1', 5),
(38, 'antran', 'antran@test.com', '123456', 'Gia Phi', 'Nam', '123 Lo Lu', 'HBC', '0123123123', '0', 5),
(39, 'hoailinh', 'hoailinh@test.com', '123456', 'Hoài Linh', 'Nam', '30 Phường 2 ', 'QBTH', '0333789987', '0', 5),
(41, 'hongtham', 'hongtham@test.com', '123456', 'Hồng Thắm', 'Nữ', '123 Lê Văn Việt', 'QGV', '0333344466', '1', 5),
(46, 'lyquynh', 'lyquynh@test.com', '123456', 'Lý Quỳnh', 'Nữ', '97 Man Thiện, Phường Hiệp Phú', 'Q09', '0333639679', '1', 5),
(49, 'tham98', 'tham98@test.com', '123456', 'Hồng Thắm', 'Nữ', '37 Lý Thường Kiệt', 'QBTH', '0333639680', '1', 5),
(53, 'sontung', 'sontung@test.com', '123456', 'Phạm Quỳnh', 'Nữ', '144 Man Thiện, Hiệp Phú', 'Q09', '0333347268', '1', 5);

-- --------------------------------------------------------

--
-- Table structure for table `district`
--

CREATE TABLE `district` (
  `district_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `district`
--

INSERT INTO `district` (`district_code`, `name`) VALUES
('HBC', 'H. Bình Chánh'),
('HCG', 'H. Cần Giờ'),
('HCC', 'H. Củ Chi'),
('HHM', 'H. Hóc Môn'),
('HNB', 'H. Nhà Bè'),
('QBTA', 'Q. Bình Tân'),
('QBTH', 'Q. Bình Thạnh'),
('QGV', 'Q. Gò Vấp'),
('QPN', 'Q. Phú Nhuận'),
('QTB', 'Q. Tân Bình'),
('QTP', 'Q. Tân Phú'),
('QTD', 'Q. Thủ Đức'),
('Q01', 'Q.1'),
('Q10', 'Q.10'),
('Q11', 'Q.11'),
('Q12', 'Q.12'),
('Q02', 'Q.2'),
('Q03', 'Q.3'),
('Q04', 'Q.4'),
('Q05', 'Q.5'),
('Q06', 'Q.6'),
('Q07', 'Q.7'),
('Q08', 'Q.8'),
('Q09', 'Q.9');

-- --------------------------------------------------------

--
-- Table structure for table `division_detail`
--

CREATE TABLE `division_detail` (
  `district_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `id_employee` int NOT NULL,
  `status` enum('0','1') CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `division_detail`
--

INSERT INTO `division_detail` (`district_code`, `id_employee`, `status`) VALUES
('HBC', 4, '1'),
('HBC', 8, '1'),
('HCC', 3, '1'),
('HCC', 8, '1'),
('HCG', 3, '1'),
('HCG', 8, '1'),
('HHM', 3, '1'),
('HNB', 3, '1'),
('Q01', 3, '1'),
('Q01', 4, '1'),
('Q01', 8, '1'),
('Q02', 3, '1'),
('Q02', 4, '1'),
('Q02', 6, '1'),
('Q03', 4, '1'),
('Q03', 8, NULL),
('Q04', 4, '1'),
('Q05', 4, '1'),
('Q06', 4, '1'),
('Q06', 5, '1'),
('Q07', 4, '1'),
('Q07', 5, '1'),
('Q08', 5, '1'),
('Q09', 4, NULL),
('Q09', 5, NULL),
('Q09', 8, NULL),
('Q10', 5, '1'),
('Q11', 5, '1'),
('Q11', 6, '1'),
('Q12', 5, '1'),
('Q12', 6, '1'),
('QBTA', 6, '1'),
('QBTH', 6, '1'),
('QGV', 6, '1'),
('QPN', 6, '1'),
('QPN', 8, '1'),
('QTB', 6, '1'),
('QTB', 8, '1'),
('QTD', 8, '1'),
('QTP', 8, '1');

-- --------------------------------------------------------

--
-- Table structure for table `employee`
--

CREATE TABLE `employee` (
  `id` int NOT NULL,
  `username` varchar(12) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `password` varchar(12) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `gender` enum('Nam','Nữ') CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `phone` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `status` int NOT NULL,
  `id_role` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `employee`
--

INSERT INTO `employee` (`id`, `username`, `email`, `password`, `name`, `gender`, `address`, `phone`, `status`, `id_role`) VALUES
(1, 'admin', 'admin@test.com', '123456', 'Admin', 'Nam', '45/97 đường 13 Phường Long Phước, Quận 9', '0333836633', 1, 1),
(2, 'manager', 'manager@test.com', '123456', 'Manager', 'Nữ', '97 Man Thiện, Phường Hiệp Phú, Quận 9', '0333836638', 1, 2),
(3, 'chaukietluan', 'chaukietluan@gtest.com', '123456', 'Châu Kiệt Luân', 'Nam', '123, Phường 7, Quận 1', '0333222444', 1, 4),
(4, 'sontung', 'sontung@test.com', '123456', 'Sơn Tùng', 'Nam', '165 Tô Ngọc Vân, Quận Thủ Đức', '0394000123', 1, 4),
(5, 'ducphuc', 'ducphuc@test.com', '123456', 'Đức Phúc', 'Nam', 'D18, Phường An Phú, Quận 2', '0333836632', 1, 4),
(6, 'damvinhhung', 'damvinhhung@test.com', '123456', 'Đàm Vĩnh Hưng', 'Nam', '215 Phường 4, Quận 5', '0333375123', 1, 4),
(7, 'approver', 'approver@test.com', '123456', 'Approver', 'Nam', '272, Phường 6, Quận 3', '0333484725', 1, 3),
(8, 'khacviet', 'khacviet@test.com', '123456', 'Khắc Việt', 'Nam', ' 54 Đường Nguyễn Văn Thủ, Đa Kao, Quận 1', '0373484296', 1, 4);

-- --------------------------------------------------------

--
-- Table structure for table `function`
--

CREATE TABLE `function` (
  `id_function` int NOT NULL,
  `id_category` int DEFAULT NULL,
  `url` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `title` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `display_on_homepage` enum('0','1') CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `function`
--

INSERT INTO `function` (`id_function`, `id_category`, `url`, `title`, `display_on_homepage`) VALUES
(1, 1, 'manage-bill.php?status=0', 'Đơn chưa duyệt', '1'),
(2, 2, 'add-type.php', 'Thêm loại sản phẩm', '0'),
(3, 2, 'edit-type.php', 'Sửa loại sản phẩm', '0'),
(4, 3, 'add-product.php', 'Thêm sản phẩm', '0'),
(5, 3, 'edit-product.php', 'Sửa sản phẩm', '0'),
(6, 3, 'list-products.php', 'Danh sách sản phẩm', '1'),
(7, 5, 'statistical.php', 'Báo cáo sản phẩm', '1'),
(8, 5, 'statistical-revenue.php', 'Báo cáo doanh thu', '1'),
(9, 4, 'import-products.php', 'Danh sách nhập hàng', '1'),
(10, 8, 'list-orders.php?status=0', 'Đang xử lý', '1'),
(13, 8, 'add-order.php', 'Tạo đặt hàng', '0'),
(14, 2, 'list-type.php', 'Danh sách loại sản phẩm', '1'),
(16, 1, 'manage-bill.php?status=2', 'Đơn đang giao', '1'),
(17, 1, 'manage-bill.php?status=3', 'Đơn hoàn tất', '1'),
(18, 1, 'manage-bill.php?status=4', 'Đơn đã hủy', '1'),
(19, 1, 'manage-bill.php?status=5', 'Đơn của tôi', '1'),
(22, 6, 'employees.php', 'Danh sách nhân viên', '1'),
(23, 7, 'customers.php', 'Danh sách khách hàng', '1'),
(24, 5, 'statistical-inventory.php', 'Báo cáo tồn kho', '1'),
(25, 5, 'statistical-interest.php', 'Báo cáo lợi nhuận', '1'),
(26, 8, 'list-orders.php?status=1', 'Đã hoàn tất', '1'),
(27, 8, 'list-orders.php?status=2', 'Đã hủy', '1'),
(28, 9, 'suppliers.php', 'Danh sách NCC', '1'),
(30, 10, 'division-delivery.php', 'Phân công giao hàng', '1'),
(31, 11, 'functions.php?type=2', 'Phân quyền', '1'),
(32, 11, 'functions.php?type=0', 'Danh sách URL', '1'),
(33, 11, 'functions.php?type=1', 'Danh mục', '1'),
(34, 12, 'my-account.php', 'Tài khoản của tôi', '0'),
(36, 14, 'promotions.php', 'Chương trình khuyến mãi', '1');

-- --------------------------------------------------------

--
-- Table structure for table `function_categories`
--

CREATE TABLE `function_categories` (
  `id_category` int NOT NULL,
  `cate_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_vietnamese_ci NOT NULL,
  `ordering` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_vietnamese_ci;

--
-- Dumping data for table `function_categories`
--

INSERT INTO `function_categories` (`id_category`, `cate_name`, `ordering`) VALUES
(1, 'Quản lý đơn hàng', 1),
(2, 'Quản lý loại sản phẩm', 2),
(3, 'Quản lý sản phẩm', 3),
(4, 'Quản lý nhập hàng', 5),
(5, 'Quản lý thống kê', 6),
(6, 'Quản lý nhân viên', 7),
(7, 'Quản lý khách hàng', 8),
(8, 'Quản lý đặt hàng', 4),
(9, 'Quản lý NCC', 9),
(10, 'Quản lý phân công', 10),
(11, 'Quản lý phân quyền', 11),
(12, 'Quản lý tài khoản', 12),
(14, 'Quản lý khuyến mãi', 13);

-- --------------------------------------------------------

--
-- Table structure for table `function_detail`
--

CREATE TABLE `function_detail` (
  `id_function` int NOT NULL,
  `id_role` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `function_detail`
--

INSERT INTO `function_detail` (`id_function`, `id_role`) VALUES
(1, 1),
(1, 2),
(1, 3),
(2, 1),
(2, 2),
(2, 3),
(3, 1),
(3, 2),
(3, 3),
(4, 1),
(4, 2),
(4, 3),
(5, 1),
(5, 2),
(5, 3),
(6, 1),
(6, 2),
(6, 3),
(7, 1),
(7, 2),
(8, 1),
(8, 2),
(9, 1),
(9, 2),
(9, 3),
(10, 1),
(10, 2),
(10, 3),
(13, 1),
(13, 2),
(13, 3),
(14, 1),
(14, 2),
(14, 3),
(16, 1),
(16, 2),
(16, 3),
(17, 1),
(17, 2),
(17, 3),
(18, 1),
(18, 2),
(18, 3),
(19, 4),
(22, 1),
(23, 1),
(24, 1),
(24, 2),
(25, 1),
(25, 2),
(26, 1),
(26, 2),
(26, 3),
(27, 1),
(27, 2),
(27, 3),
(28, 1),
(28, 2),
(30, 1),
(30, 2),
(31, 1),
(32, 1),
(33, 1),
(34, 1),
(34, 2),
(34, 3),
(34, 4),
(36, 1);

-- --------------------------------------------------------

--
-- Table structure for table `import`
--

CREATE TABLE `import` (
  `import_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `id_employee` int NOT NULL,
  `total` float NOT NULL,
  `place_order_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `import_detail`
--

CREATE TABLE `import_detail` (
  `import_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `product_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `price` float NOT NULL,
  `quantity_in` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int NOT NULL,
  `id_customer` int NOT NULL,
  `id_employee` int DEFAULT NULL,
  `id_shipper` int DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `district_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `phone` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `date_receive` date NOT NULL,
  `status` int NOT NULL COMMENT '0: chưa duyệt, 1: chờ shipper xác nhận, 2: đang giao, 3: hoàn tất, 4: hủy',
  `total` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders_detail`
--

CREATE TABLE `orders_detail` (
  `id_order` int NOT NULL,
  `product_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `price` float NOT NULL,
  `quantity_out` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `place_order`
--

CREATE TABLE `place_order` (
  `place_order_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `id_employee` int NOT NULL,
  `supp_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `import_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `status` int DEFAULT NULL COMMENT '0: đang xử lý, 1: hoàn tất, 2: đã hủy'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `place_order_detail`
--

CREATE TABLE `place_order_detail` (
  `place_order_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `product_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `quantity_ord` int NOT NULL,
  `price_ord` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `description` varchar(900) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `price` float NOT NULL,
  `image` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `quantity_exist` int NOT NULL,
  `new` tinyint(1) NOT NULL COMMENT '0: cũ, 1: mới',
  `status` tinyint(1) NOT NULL COMMENT '0: chưa xóa, 1: đã xóa',
  `cate_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `supp_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_code`, `name`, `description`, `price`, `image`, `quantity_exist`, `new`, `status`, `cate_code`, `supp_code`) VALUES
('MH01', 'Mũ bảo hiểm 3/4 BT01-ASA màu đen, kính âm', 'Có độ bền cao và chịu va đập tốt.\nMút xốp bằng EPS hấp thụ chấn động khi có sự cố.\nQuai mũ dệt 2 lớp bằng sợi tổng hợp, chịu lực giật kéo tốt.', 300000, 'BT01.jpg', 14, 1, 0, 'BT', 'ASA'),
('MH02', 'Mũ bảo hiểm 3/4 đầu BT02-P247 màu trắng, kính âm', 'Có độ bền cao và chịu va đập tốt.\r\nMút xốp bằng EPS hấp thụ chấn động khi có sự cố.\r\nQuai mũ dệt 2 lớp bằng sợi tổng hợp, chịu lực giật kéo tốt.', 320000, 'BT02.jpg', 13, 1, 0, 'BT', 'P247'),
('MH03', 'Mũ bảo hiểm 3/4 BT03-ASA màu vàng, kính âm', 'Có độ bền cao và chịu va đập tốt.\r\nMút xốp bằng EPS hấp thụ chấn động khi có sự cố.\r\nQuai mũ dệt 2 lớp bằng sợi tổng hợp, chịu lực giật kéo tốt.', 350000, 'BT03.jpg', 1, 1, 0, 'BT', 'ASA'),
('MH04', 'Mũ bảo hiểm ND04-ASA màu trắng, có kính', 'Mũ được làm từ chất liệu ABS cao cấp. Vải lót êm ái, kính che tiện dụng. Đảm bảo an toàn khi tham gia giao thông.', 180000, 'ND04.jpg', 17, 0, 0, 'ND', 'ASA'),
('MH05', 'Mũ bảo hiểm ND05-ASA màu vàng, có kính', 'Mũ được làm từ chất liệu ABS cao cấp. Vải lót êm ái, kính che tiện dụng. Đảm bảo an toàn khi tham gia giao thông.', 190000, 'ND05.jpg', 15, 0, 0, 'ND', 'ASA'),
('MH06', 'Mũ bảo hiểm 1/2 đầu ND06-ASA màu đen, có kính', 'Mũ được làm từ chất liệu ABS cao cấp. Vải lót êm ái, kính che tiện dụng. Đảm bảo an toàn khi tham gia giao thông.', 150000, 'ND06.jpg', 1, 0, 0, 'ND', 'ASA'),
('MH07', 'Mũ lật cằm LC07-S189 Tem Nhám màu đen', 'Chất liệu nhựa ABS bền đẹp.\r\nKết cấu bền chắc, an toàn và hợp thời trang.\r\nLót đệm bên trong dày và hút ẩm thoải mái khi sử dụng.', 500000, 'LC07.jpg', 30, 0, 0, 'LC', 'S189'),
('MH08', 'Mũ bảo hiểm Full Face FF10-ASA AGU Tem sói', 'Vỏ bằng nhựa ABS nguyên sinh có độ bền cao và chịu va đập tốt.\r\nMiếng lót bên trong nón có thể được tháo rời giúp việc vệ sinh dễ dàng.', 600000, 'FF08.jpg', 8, 1, 0, 'FF', 'ASA'),
('MH09', 'Mũ bảo hiểm Full Face FF09-ASA AGU Tem Racing', 'Vỏ bằng nhựa ABS nguyên sinh có độ bền cao và chịu va đập tốt.\r\nMiếng lót bên trong nón có thể được tháo rời giúp việc vệ sinh dễ dàng.', 630000, 'FF09.jpg', 14, 1, 0, 'FF', 'ASA'),
('MH10', 'Mũ bảo hiểm lật cằm LC10-P247 Tem Carbon màu đỏ/đen', 'Vỏ bằng nhựa ABS nguyên sinh có độ bền cao và chịu va đập tốt.\r\nMiếng lót bên trong nón có thể được tháo rời giúp việc vệ sinh dễ dàng.', 690000, 'LC10.jpg', 22, 0, 0, 'LC', 'P247'),
('MH11', 'Mũ bảo hiểm lật cằm LC11-P247 LS2 màu trắng', 'Vỏ bằng nhựa ABS nguyên sinh có độ bền cao và chịu va đập tốt.\r\nMiếng lót bên trong nón có thể được tháo rời giúp việc vệ sinh dễ dàng.', 720000, 'LC11.jpg', 5, 1, 0, 'LC', 'P247'),
('MH12', 'Mũ bảo hiểm lật cằm LC12-S189 EGO', 'Vỏ bằng nhựa ABS nguyên sinh có độ bền cao và chịu va đập tốt.\r\nMiếng lót bên trong nón có thể được tháo rời giúp việc vệ sinh dễ dàng.', 750000, 'LC12.jpg', 25, 0, 0, 'LC', 'S189'),
('MH13', 'Mũ bảo hiểm lật cằm LC13-S189 Yohe 950', 'Vỏ bằng nhựa ABS nguyên sinh có độ bền cao và chịu va đập tốt.\r\nMiếng lót bên trong nón có thể được tháo rời giúp việc vệ sinh dễ dàng.', 1290000, 'LC13.jpg', 20, 0, 0, 'LC', 'S189'),
('MH14', 'Mũ bảo hiểm 1/2 đầu ND14-S189 màu hồng, có kính', 'Mũ được làm từ chất liệu ABS cao cấp. Vải lót êm ái, kính che tiện dụng. Đảm bảo an toàn khi tham gia giao thông.', 200000, 'ND14.jpg', 23, 0, 0, 'ND', 'S189'),
('MH15', 'Mũ bảo hiểm 1/2 đầu ND15-S189 màu đỏ/trắng, không kính', 'Mũ được làm từ chất liệu ABS cao cấp. Vải lót êm ái, kính che tiện dụng. Đảm bảo an toàn khi tham gia giao thông.', 250000, 'ND15.jpg', 20, 0, 0, 'ND', 'S189'),
('MH16', 'Mũ bảo hiểm 3/4 BT16-P247 màu cam', 'Có độ bền cao và chịu va đập tốt.\r\nMút xốp bằng EPS hấp thụ chấn động khi có sự cố.\r\nQuai mũ dệt 2 lớp bằng sợi tổng hợp, chịu lực giật kéo tốt.', 220000, 'BT16.jpg', 8, 1, 0, 'BT', 'P247'),
('MH17', 'Mũ bảo hiểm 3/4 BT17-S189 màu trắng/xanh dương', 'Có độ bền cao và chịu va đập tốt.\r\nMút xốp bằng EPS hấp thụ chấn động khi có sự cố.\r\nQuai mũ dệt 2 lớp bằng sợi tổng hợp, chịu lực giật kéo tốt.', 230000, 'BT17.jpg', 34, 1, 0, 'BT', 'S189'),
('MH18', 'Mũ bảo hiểm FullFace FF23-P247 Andes Tem Nhám', 'Chất liệu nhựa ABS bền đẹp.\r\nKết cấu bền chắc, an toàn và hợp thời trang.\r\nLót đệm bên trong dày và hút ẩm thoải mái khi sử dụng.', 990000, 'FF18.jpg', 13, 0, 0, 'FF', 'P247'),
('MH19', 'Mũ bảo hiểm FullFace FF24-P247 AGU Tem 46 xanh dương', 'Chất liệu nhựa ABS bền đẹp.\r\nKết cấu bền chắc, an toàn và hợp thời trang.\r\nLót đệm bên trong dày và hút ẩm thoải mái khi sử dụng.', 890000, 'FF19.jpg', 18, 1, 0, 'FF', 'P247'),
('MH20', 'Mũ bảo hiểm FullFace FF20-S189 Tem Avengers', 'Chất liệu nhựa ABS bền đẹp.\r\nKết cấu bền chắc, an toàn và hợp thời trang.\r\nLót đệm bên trong dày và hút ẩm thoải mái khi sử dụng.', 950000, 'FF20.jpg', 29, 1, 0, 'FF', 'S189'),
('MH21', 'Mũ 1/2 đầu trẻ em TT01 màu trắng', 'Vỏ nón được làm từ hạt nhựa ABS nguyên sinh cao cấp. Mút nón được làm từ hạt xốp EPS chất lượng cao. Kính được làm từ nhựa tổng hợp Polymer qua xử lý trong suốt.', 150000, 'TT01.jpg', 11, 1, 0, 'TT', 'ASA'),
('MH22', 'Mũ 1/2 đầu trẻ em TT02 màu xanh, có kính', 'Vỏ nón được làm từ hạt nhựa ABS nguyên sinh cao cấp. Mút nón được làm từ hạt xốp EPS chất lượng cao.\nKính được làm từ nhựa tổng hợp Polymer qua xử lý trong suốt.', 160000, 'TT02.jpg', 12, 1, 0, 'TT', 'ASA'),
('MH23', 'Mũ 1/2 đầu trẻ em TT03 màu đỏ', 'Vỏ nón được làm từ hạt nhựa ABS nguyên sinh cao cấp. Mút nón được làm từ hạt xốp EPS chất lượng cao. Kính được làm từ nhựa tổng hợp Polymer qua xử lý trong suốt.', 170000, 'TT03.jpg', 0, 1, 0, 'TT', 'P247'),
('MH24', 'Mũ 3/4 đầu trẻ em TT04 màu vàng, có kính', 'Vỏ nón được làm từ hạt nhựa ABS nguyên sinh cao cấp. Mút nón được làm từ hạt xốp EPS chất lượng cao. Kính được làm từ nhựa tổng hợp Polymer qua xử lý trong suốt.', 180000, 'TT04.jpg', 14, 1, 0, 'TT', 'ASA');

-- --------------------------------------------------------

--
-- Table structure for table `promotion`
--

CREATE TABLE `promotion` (
  `promotion_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `date_start` date NOT NULL,
  `date_end` date NOT NULL,
  `description` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `id_employee` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `promotion`
--

INSERT INTO `promotion` (`promotion_code`, `date_start`, `date_end`, `description`, `id_employee`) VALUES
('KM01', '2020-12-01', '2030-01-01', 'Khuyến mãi cuối năm', 1),
('KM02', '2021-02-01', '2030-02-01', 'Khuyễn mãi đầu năm mới', 1);

-- --------------------------------------------------------

--
-- Table structure for table `promotion_detail`
--

CREATE TABLE `promotion_detail` (
  `promotion_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `product_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `percent` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `promotion_detail`
--

INSERT INTO `promotion_detail` (`promotion_code`, `product_code`, `percent`) VALUES
('KM01', 'MH06', 0.1),
('KM01', 'MH08', 0.1),
('KM01', 'MH11', 0.1),
('KM01', 'MH14', 0.1),
('KM01', 'MH16', 0.1),
('KM01', 'MH18', 0.1),
('KM01', 'MH20', 0.2),
('KM02', 'MH01', 0.1),
('KM02', 'MH03', 0.1);

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE `role` (
  `id_role` int NOT NULL,
  `name` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `description` varchar(400) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `role`
--

INSERT INTO `role` (`id_role`, `name`, `description`) VALUES
(1, 'Admin', 'Toàn quyền: Quyền của Approver + Manager + quyền quản lý khách hàng, nhân viên'),
(2, 'Manager', 'Quyền của Approver + quyền xem thống kê + CTKM + phân công'),
(3, 'Approver', 'Quyền duyệt đơn hàng + quản lý loại sản phẩm + quản lý sản phẩm + quản lý đặt/nhập+ quản lý NCC '),
(4, 'Shipper', ''),
(5, 'Customer', '');

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

CREATE TABLE `suppliers` (
  `supp_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `phone` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `status` int NOT NULL COMMENT '1: chưa xóa, 0: xóa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;

--
-- Dumping data for table `suppliers`
--

INSERT INTO `suppliers` (`supp_code`, `name`, `address`, `email`, `phone`, `status`) VALUES
('ASA', 'ASA Helmet', '11, Phường Bến Nghé, Quận 1, TP.HCM', 'asa_helmet1@test.com', '0333444555', 1),
('P247', 'Phượt 247', '589C An Phú, Quận 2, Tp.HCM', 'phuot247@test.com', '0333444666', 1),
('S189', 'Store 189', '25 Cao Thắng, Phường 5, Quận 3, Tp.HCM', 'store_189@test.com', '0333444777', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bills`
--
ALTER TABLE `bills`
  ADD PRIMARY KEY (`bill_code`),
  ADD UNIQUE KEY `id_order_2` (`id_order`),
  ADD KEY `id_order` (`id_order`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`cate_code`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `district_code` (`district_code`),
  ADD KEY `id_role` (`id_role`);

--
-- Indexes for table `district`
--
ALTER TABLE `district`
  ADD PRIMARY KEY (`district_code`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `division_detail`
--
ALTER TABLE `division_detail`
  ADD PRIMARY KEY (`district_code`,`id_employee`) USING BTREE,
  ADD KEY `id_employee` (`id_employee`,`district_code`) USING BTREE;

--
-- Indexes for table `employee`
--
ALTER TABLE `employee`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD KEY `id_role` (`id_role`);

--
-- Indexes for table `function`
--
ALTER TABLE `function`
  ADD PRIMARY KEY (`id_function`),
  ADD UNIQUE KEY `url` (`url`),
  ADD UNIQUE KEY `title` (`title`),
  ADD KEY `id_category` (`id_category`);

--
-- Indexes for table `function_categories`
--
ALTER TABLE `function_categories`
  ADD PRIMARY KEY (`id_category`),
  ADD UNIQUE KEY `cate_name` (`cate_name`);

--
-- Indexes for table `function_detail`
--
ALTER TABLE `function_detail`
  ADD PRIMARY KEY (`id_function`,`id_role`) USING BTREE,
  ADD KEY `id_role` (`id_role`,`id_function`) USING BTREE;

--
-- Indexes for table `import`
--
ALTER TABLE `import`
  ADD PRIMARY KEY (`import_code`),
  ADD UNIQUE KEY `place_order_code_2` (`place_order_code`),
  ADD KEY `place_order_code` (`place_order_code`),
  ADD KEY `id_employee` (`id_employee`);

--
-- Indexes for table `import_detail`
--
ALTER TABLE `import_detail`
  ADD PRIMARY KEY (`import_code`,`product_code`) USING BTREE,
  ADD KEY `product_code` (`product_code`,`import_code`) USING BTREE;

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `district_code` (`district_code`),
  ADD KEY `id_customer` (`id_customer`),
  ADD KEY `id_employee` (`id_employee`),
  ADD KEY `id_shipper` (`id_shipper`);

--
-- Indexes for table `orders_detail`
--
ALTER TABLE `orders_detail`
  ADD PRIMARY KEY (`id_order`,`product_code`) USING BTREE,
  ADD KEY `product_code` (`product_code`,`id_order`) USING BTREE;

--
-- Indexes for table `place_order`
--
ALTER TABLE `place_order`
  ADD PRIMARY KEY (`place_order_code`),
  ADD UNIQUE KEY `import_code` (`import_code`),
  ADD KEY `supp_code` (`supp_code`),
  ADD KEY `id_employee` (`id_employee`);

--
-- Indexes for table `place_order_detail`
--
ALTER TABLE `place_order_detail`
  ADD PRIMARY KEY (`place_order_code`,`product_code`) USING BTREE,
  ADD KEY `product_code` (`product_code`,`place_order_code`) USING BTREE;

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_code`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `cate_code` (`cate_code`),
  ADD KEY `supp_code` (`supp_code`);

--
-- Indexes for table `promotion`
--
ALTER TABLE `promotion`
  ADD PRIMARY KEY (`promotion_code`),
  ADD KEY `id_employee` (`id_employee`);

--
-- Indexes for table `promotion_detail`
--
ALTER TABLE `promotion_detail`
  ADD PRIMARY KEY (`promotion_code`,`product_code`) USING BTREE,
  ADD KEY `product_code` (`product_code`,`promotion_code`) USING BTREE;

--
-- Indexes for table `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`id_role`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`supp_code`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- AUTO_INCREMENT for table `employee`
--
ALTER TABLE `employee`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `function`
--
ALTER TABLE `function`
  MODIFY `id_function` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `function_categories`
--
ALTER TABLE `function_categories`
  MODIFY `id_category` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=196;

--
-- AUTO_INCREMENT for table `role`
--
ALTER TABLE `role`
  MODIFY `id_role` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bills`
--
ALTER TABLE `bills`
  ADD CONSTRAINT `bills_ibfk_1` FOREIGN KEY (`id_order`) REFERENCES `orders` (`id`);

--
-- Constraints for table `customers`
--
ALTER TABLE `customers`
  ADD CONSTRAINT `customers_ibfk_1` FOREIGN KEY (`district_code`) REFERENCES `district` (`district_code`),
  ADD CONSTRAINT `customers_ibfk_2` FOREIGN KEY (`id_role`) REFERENCES `role` (`id_role`);

--
-- Constraints for table `division_detail`
--
ALTER TABLE `division_detail`
  ADD CONSTRAINT `division_detail_ibfk_1` FOREIGN KEY (`district_code`) REFERENCES `district` (`district_code`),
  ADD CONSTRAINT `division_detail_ibfk_2` FOREIGN KEY (`id_employee`) REFERENCES `employee` (`id`);

--
-- Constraints for table `employee`
--
ALTER TABLE `employee`
  ADD CONSTRAINT `employee_ibfk_1` FOREIGN KEY (`id_role`) REFERENCES `role` (`id_role`);

--
-- Constraints for table `function`
--
ALTER TABLE `function`
  ADD CONSTRAINT `function_ibfk_1` FOREIGN KEY (`id_category`) REFERENCES `function_categories` (`id_category`);

--
-- Constraints for table `function_detail`
--
ALTER TABLE `function_detail`
  ADD CONSTRAINT `function_detail_ibfk_1` FOREIGN KEY (`id_function`) REFERENCES `function` (`id_function`),
  ADD CONSTRAINT `function_detail_ibfk_2` FOREIGN KEY (`id_role`) REFERENCES `role` (`id_role`);

--
-- Constraints for table `import`
--
ALTER TABLE `import`
  ADD CONSTRAINT `import_ibfk_3` FOREIGN KEY (`place_order_code`) REFERENCES `place_order` (`place_order_code`),
  ADD CONSTRAINT `import_ibfk_4` FOREIGN KEY (`id_employee`) REFERENCES `employee` (`id`);

--
-- Constraints for table `import_detail`
--
ALTER TABLE `import_detail`
  ADD CONSTRAINT `import_detail_ibfk_1` FOREIGN KEY (`product_code`) REFERENCES `products` (`product_code`),
  ADD CONSTRAINT `import_detail_ibfk_2` FOREIGN KEY (`import_code`) REFERENCES `import` (`import_code`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`district_code`) REFERENCES `district` (`district_code`),
  ADD CONSTRAINT `orders_ibfk_4` FOREIGN KEY (`id_customer`) REFERENCES `customers` (`id`),
  ADD CONSTRAINT `orders_ibfk_5` FOREIGN KEY (`id_employee`) REFERENCES `employee` (`id`),
  ADD CONSTRAINT `orders_ibfk_6` FOREIGN KEY (`id_shipper`) REFERENCES `employee` (`id`);

--
-- Constraints for table `orders_detail`
--
ALTER TABLE `orders_detail`
  ADD CONSTRAINT `orders_detail_ibfk_1` FOREIGN KEY (`id_order`) REFERENCES `orders` (`id`),
  ADD CONSTRAINT `orders_detail_ibfk_2` FOREIGN KEY (`product_code`) REFERENCES `products` (`product_code`);

--
-- Constraints for table `place_order`
--
ALTER TABLE `place_order`
  ADD CONSTRAINT `place_order_ibfk_3` FOREIGN KEY (`supp_code`) REFERENCES `suppliers` (`supp_code`),
  ADD CONSTRAINT `place_order_ibfk_4` FOREIGN KEY (`id_employee`) REFERENCES `employee` (`id`),
  ADD CONSTRAINT `place_order_ibfk_5` FOREIGN KEY (`import_code`) REFERENCES `import` (`import_code`);

--
-- Constraints for table `place_order_detail`
--
ALTER TABLE `place_order_detail`
  ADD CONSTRAINT `place_order_detail_ibfk_1` FOREIGN KEY (`place_order_code`) REFERENCES `place_order` (`place_order_code`),
  ADD CONSTRAINT `place_order_detail_ibfk_2` FOREIGN KEY (`product_code`) REFERENCES `products` (`product_code`);

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`cate_code`) REFERENCES `categories` (`cate_code`),
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`supp_code`) REFERENCES `suppliers` (`supp_code`);

--
-- Constraints for table `promotion`
--
ALTER TABLE `promotion`
  ADD CONSTRAINT `promotion_ibfk_1` FOREIGN KEY (`id_employee`) REFERENCES `employee` (`id`);

--
-- Constraints for table `promotion_detail`
--
ALTER TABLE `promotion_detail`
  ADD CONSTRAINT `promotion_detail_ibfk_1` FOREIGN KEY (`product_code`) REFERENCES `products` (`product_code`),
  ADD CONSTRAINT `promotion_detail_ibfk_2` FOREIGN KEY (`promotion_code`) REFERENCES `promotion` (`promotion_code`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
