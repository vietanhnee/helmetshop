# Cài đặt môi trường
- Cài Docker (https://www.docker.com/products/docker-desktop/) và khởi chạy
- Tại thư mục helmet_shop, chạy lệnh `docker-compose up`
- Chạy lệnh `docker-compose down` để xóa sạch các container

# Đường dẫn
- Trang bán hàng: http://localhost/helmet_shop/index.php (lyquynh/123456)
- Trang admin: http://localhost/helmet_shop/admin/login.php (admin/123456)
- PhpMyAdmin: http://localhost:8001/ (admin/123456)

# Dữ liệu
- Dữ liệu được nạp sẵn từ file `helmet_shop.sql` trong thư mục `db`
- Dữ liệu sẽ bị reset về ban đầu sau khi tắt Docker và mở lại
- Nếu muốn có dữ liệu mới nhất, từ PhpMyAdmin, export file SQL và ghi đè lên file SQL cũ
- Các stored procedures (SP) nếu không export được cần chép vào file SQL bằng tay