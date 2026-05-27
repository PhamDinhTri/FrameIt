# FrameIt Studio

Ứng dụng Flutter để xem trước tác phẩm nghệ thuật trong khung và bối cảnh trưng bày. Một codebase có thể build ra Android, iOS và Web.

## Yêu cầu

- Flutter SDK 3.24+.
- Android Studio hoặc Android SDK nếu build Android.
- Xcode trên macOS nếu build iOS.

## Thiết lập lần đầu

```powershell
flutter create . --platforms=android,ios,web
flutter pub get
```

Lệnh `flutter create` sinh các thư mục native còn thiếu mà không ghi đè `lib/main.dart`, `pubspec.yaml` nếu bạn chọn giữ file hiện tại khi Flutter hỏi.

Sau khi sinh thư mục `ios/`, thêm quyền đọc thư viện ảnh vào `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>FrameIt cần quyền chọn ảnh tác phẩm từ thư viện của bạn.</string>
```

## Chạy thử

```powershell
flutter run -d chrome
flutter run -d android
```

## Build

```powershell
flutter build web
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## Deploy GitHub Pages

Project đã có workflow GitHub Actions tại `.github/workflows/pages.yml`.

1. Tạo repository trên GitHub, ví dụ `FrameIt`.
2. Push code lên branch `main`.
3. Vào `Settings` -> `Pages`.
4. Ở `Build and deployment`, chọn `Source: GitHub Actions`.
5. Mỗi lần push lên `main`, GitHub Actions sẽ chạy:

```text
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href "/<ten-repo>/"
```

Nếu repo tên `FrameIt`, URL sẽ có dạng:

```text
https://<username>.github.io/FrameIt/
```

Nếu bạn đổi tên repo, workflow tự dùng đúng tên repo qua `${{ github.event.repository.name }}`.

## Tính năng

- Tải ảnh tác phẩm từ thư viện ảnh trên điện thoại hoặc trình duyệt.
- Chọn cảnh trưng bày, kiểu khung và màu giấy.
- Tự thêm ảnh cảnh trưng bày và texture khung từ folder asset.
- Kéo cả cụm khung trên nền cảnh, pinch để phóng to/thu nhỏ, hoặc chỉnh bằng slider.
- Điều chỉnh độ rộng khung, viền giấy, bo góc, hiệu ứng khử nhăn và bóng đổ.
- Xuất PNG: tải trực tiếp trên Web, chia sẻ file trên mobile.

## Thêm ảnh custom

Đặt ảnh cảnh trưng bày vào:

```text
assets/scenes/
```

Đặt ảnh texture/kiểu khung vào:

```text
assets/frames/
```

Định dạng hỗ trợ: `.png`, `.jpg`, `.jpeg`, `.webp`.

Tên file sẽ được dùng làm tên hiển thị trong app. Ví dụ:

```text
assets/scenes/phong-trien-lam-01.jpg
assets/frames/go-oc-cho.png
```

Sau khi thêm hoặc xóa ảnh asset, chạy lại:

```powershell
flutter pub get
flutter run -d chrome
```

Với ảnh cảnh trưng bày, app sẽ dùng ảnh đó làm toàn bộ nền preview. Với ảnh khung, app sẽ phủ texture lên phần viền khung hiện tại.

## Bản web tĩnh cũ

Các file `index.html`, `styles.css`, `app.js` là bản prototype web tĩnh trước đó. Bản Flutter chính nằm trong `lib/main.dart`.
