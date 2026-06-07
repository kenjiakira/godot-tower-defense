# Tower Defense

Một game **Tower Defense** làm bằng **Godot 4.6**, dự án học tập để làm quen với game loop, UI, quản lý state và kiến trúc scene trong Godot.

## Tính năng

- **Main menu** — Play, How to Play, Settings (âm lượng, nhạc, fullscreen), Quit
- **4 loại tháp** — Basic, AOE, Sniper, Slow (mỗi loại nâng cấp tối đa 3 cấp)
- **4 loại quái** — Normal, Fast, Tank, Boss (boss xuất hiện cuối mỗi wave chia hết cho 5)
- **Wave system** — Bấm nút để bắt đầu wave, số lượng quái tăng dần sau mỗi wave
- **Kinh tế** — Tiền từ giết quái, dùng để xây / nâng cấp tháp, bán tháp hoàn lại 70%
- **HUD** — Hiển thị tiền, HP base, wave; pause, tốc độ 1x/2x, bật/tắt âm thanh
- **Hiệu ứng** — Floating damage text, camera shake, death effect
- **Game over** — Thua khi base hết HP, có nút chơi lại

## Cách chơi

1. Bấm **Start Wave** để quái bắt đầu xuất hiện.
2. Click vào **ô build spot** trống → chọn loại tháp muốn xây.
3. Click vào tháp đã xây → xem stats, **Upgrade** hoặc **Sell**.
4. Giết quái để kiếm tiền, nâng cấp tháp để sống sót qua nhiều wave hơn.
5. **Đừng để quái chạm vào base** — mỗi quái vào base trừ 1 HP.

## Tháp

| Loại | Giá | Đặc điểm |
|------|-----|----------|
| Basic | 50$ | Cân bằng, bắn đơn mục tiêu |
| AOE | 70$ | Gây sát thương diện rộng |
| Sniper | 100$ | Sát thương cao, tầm xa, ưu tiên quái máu nhiều |
| Slow | 60$ | Làm chậm quái, ưu tiên quái chạy nhanh |

## Quái

| Loại | Tốc độ | HP | Thưởng |
|------|--------|-----|--------|
| Normal | 130 | 200 | 10$ |
| Fast | 200 | 150 | 15$ |
| Tank | 50 | 600 | 30$ |
| Boss | 80 | 500 | 100$ |

Wave càng cao, tỷ lệ xuất hiện quái mạnh càng lớn.

## Yêu cầu

- [Godot 4.6](https://godotengine.org/download) trở lên

## Chạy game

```bash
# Mở project trong Godot Editor, rồi nhấn F5 (Play)
```

Hoặc: **Project → Run** trong Godot Editor.

Scene khởi động: `scenes/main_menu.tscn`

## Cấu trúc thư mục

```
tower-defense/
├── assets/          # Hình ảnh, âm thanh, font
├── scenes/          # Scene Godot (.tscn)
│   ├── main_menu.tscn
│   ├── main.tscn
│   ├── ui/
│   └── bullets/
├── scripts/
│   ├── autoload/    # GameState, GameConfig (global singleton)
│   ├── core/        # Main.gd, MainMenu.gd
│   ├── entities/    # Tower, Enemy, Bullet, BuildSpot, TownHall
│   ├── systems/     # WaveManager, BuildManager, EffectsManager
│   ├── ui/          # HUD và UI components
│   └── effects/     # FloatingText, CameraShake, DeathEffect
└── themes/          # UI theme
```

## Kiến trúc

Dự án dùng pattern **Manager** để tách logic:

| Module | Vai trò |
|--------|---------|
| `GameState` | State toàn cục: tiền, HP, wave, tháp đang chọn |
| `GameConfig` | Cấu hình tĩnh: giá tháp, stats theo level |
| `WaveManager` | Spawn quái, theo dõi wave, emit signal |
| `BuildManager` | Xây / bán tháp, quản lý build spot |
| `EffectsManager` | Floating text, camera shake, death effect |
| `Main.gd` | Điều phối managers, xử lý input và UI |

## Những gì đã học được

- Scene tree, signals, và autoload trong Godot
- `PathFollow2D` cho quái di chuyển theo đường
- `Area2D` cho phát hiện quái trong tầm bắn của tháp
- Quản lý game loop: wave → spawn → combat → reward
- Tách UI (`CanvasLayer`) khỏi gameplay (`Node2D`)
- Cấu hình hóa stats qua `GameConfig` thay vì hard-code
- Polish cơ bản: âm thanh, pause, tốc độ game, hiệu ứng

## Ghi chú

Đây là **dự án học tập**, không phải sản phẩm thương mại. Game chạy wave vô hạn — không có màn thắng, chỉ có game over khi base bị phá.

## License

Assets (hình ảnh, âm thanh) thuộc về tác giả gốc tương ứng. Code trong repo này dùng cho mục đích học tập cá nhân.
