# Partner Configs Template

Mỗi partner cần có 4 files trong submodule này:

## 1. {partner-key}.env.txt

Template:

```env
# Partner Information
PARTNER_KEY=example-partner
APP_NAME=Example Partner App
APP_SLUG=example-partner

# App IDs
APP_ID_IOS=com.emddi.example
APP_ID_ANDROID=com.emddi.example

# Version
APP_VERSION=5.0.0
APP_BUILD_CODE=24

# Environment
ENV_NAME=Production

# API
BASE_URL=https://api.emddi.com/customer-api/api
SOCKET_URL=https://api.emddi.com
CHAT_API_URL=https://chat-api.emddi.com/api/v1

# Map API Keys
GOOGLE_MAP_API_KEY_IOS=your-google-map-ios-key
GOOGLE_MAP_API_KEY_ANDROID=your-google-map-android-key

# OneSignal
ONESIGNAL_APP_ID=your-onesignal-app-id

# Social Login (nếu cần)
FACEBOOK_APP_ID=your-facebook-app-id
GOOGLE_WEB_CLIENT_ID=your-google-web-client-id

# Other configs...
```

## 2. {partner-key}.logo.png

- Kích thước: 1024x1024px
- Format: PNG với transparent background (khuyến nghị)
- Sẽ được dùng làm app icon cho cả iOS và Android

## 3. {partner-key}.GoogleService-Info.plist

Firebase config cho iOS, download từ Firebase Console:
1. Vào Firebase Console → Project Settings → iOS app
2. Download GoogleService-Info.plist
3. Đảm bảo Bundle ID trùng với APP_ID_IOS

## 4. {partner-key}.google-services.json

Firebase config cho Android, download từ Firebase Console:
1. Vào Firebase Console → Project Settings → Android app
2. Download google-services.json
3. Đảm bảo Package name trùng với APP_ID_ANDROID

## Ví dụ cấu trúc thư mục:

```
partner-configs/
├── example-partner.env.txt
├── example-partner.logo.png
├── example-partner.GoogleService-Info.plist
├── example-partner.google-services.json
├── abc-taxi.env.txt
├── abc-taxi.logo.png
├── abc-taxi.GoogleService-Info.plist
├── abc-taxi.google-services.json
└── ...
```

## Tạo partner mới:

1. Chuẩn bị 4 files theo template trên
2. Copy vào thư mục partner-configs
3. Commit và push:
   ```bash
   cd partner-configs
   git add .
   git commit -m "Add new partner: {partner-key}"
   git push origin main
   ```
4. Chạy clone-partner script:
   ```bash
   cd ..
   ./clone-partner.sh main --partner {partner-key}
   ```
