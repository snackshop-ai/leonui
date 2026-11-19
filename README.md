# Module 1 — Di chuyển và Leo núi (Godot 4)

## Tệp

- `player_movement.gd`: script gắn lên node gốc `CharacterBody3D`.
- `mobile_controls.gd`: HUD joystick và nút cảm ứng tự co giãn theo màn hình.
- `main.tscn`: màn chơi thử 3D có sàn, vách leo `Climbable`, bục đỉnh, nhân vật mẫu và camera bám theo.
- `camera_follow.gd`: camera góc nhìn thứ ba cho scene thử.
- `project.godot`: Input Map mặc định (WASD, Shift chạy, Space nhảy, E bắt đầu bám).
- `export_presets.cfg` và `scripts/build_web.sh`: xuất WebAssembly/WebGL cho Render Static Site.

## Dựng scene nhân vật

Mở `project.godot` trong Godot 4 và chạy scene `main.tscn` để thử ngay. Scene dùng capsule làm nhân vật mẫu, có sàn, vách leo và bục đỉnh. Để thay model, giữ `CharacterBody3D` cùng collision rồi thay node mesh.

Để bật điều khiển di động, thêm `CanvasLayer` làm con của nhân vật, rồi thêm node `Control` làm con của CanvasLayer và gắn `mobile_controls.gd`. Joystick ảo nằm góc trái dưới; Chạy, Nhảy và Leo nằm bên phải dưới, giữ vùng trung tâm thông thoáng cho gameplay. Cấu hình project đặt cửa sổ thiết kế 1280×720 theo chiều ngang.

## Vách leo

Tạo vách với collision (thường là `StaticBody3D`), chọn node collider trong Scene dock, vào **Node > Groups**, thêm group `Climbable`. Đứng sát vách và nhấn E để bám. WASD di chuyển lên/xuống/sang ngang; giữ Shift để leo nhanh và ồn hơn. Nhấn Space để bật khỏi vách. Leo yêu cầu raycast trước ngực vẫn chạm collider thuộc group `Climbable`; khi hết thể lực hoặc mất mặt vách, nhân vật nhả tay và trọng lực làm nhân vật rơi.

## Nối AI thú và UI

`noise_emitted(world_position, radius)` phát tối đa mỗi 0,35 giây khi đang di chuyển. Kết nối signal này tới AI; AI kiểm tra khoảng cách từ vị trí phát tiếng tới thú có nhỏ hơn `radius` không. Bán kính mặc định: đi bộ 3 m, chạy 12 m, leo thường 5 m, leo nhanh 15 m.

`stamina_changed(current, maximum)` dùng để cập nhật thanh thể lực. `climbing_changed(active)` báo trạng thái bám vách. Có thể điều chỉnh tốc độ, mức hao/hồi thể lực và bán kính tiếng ồn trực tiếp trong Inspector.

## Ghi chú MVP

Đây là bộ điều khiển tối giản cho địa hình test và collider vách tĩnh. Chuyển động ngang trên vách dùng mặt phẳng tiếp tuyến đơn giản; hệ thống chưa bao gồm animation, ledge grab, stamina UI hay camera orbit tự do.

## Xuất bản web

Render Static Site chạy `bash scripts/build_web.sh` và phục vụ thư mục `build`. Script tải bản Godot stable đã pin cùng export templates, sau đó xuất scene sang WebAssembly. Bản web dùng template không đa luồng để không cần cấu hình COOP/COEP headers.

