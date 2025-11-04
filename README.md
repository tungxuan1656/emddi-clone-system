# EMDDI Customer Clone System

Hệ thống quản lý và build multiple partner apps từ source code chung sử dụng Git Submodules.

## 📂 Cấu trúc Project

```
emddi-customer-clone-system/
├── partner-configs/          # Submodule chứa configs của các partner
│   ├── {partner-key}.env.txt
│   ├── {partner-key}.logo.png
│   ├── {partner-key}.GoogleService-Info.plist
│   └── {partner-key}.google-services.json
├── emddi-v2/                 # Submodule source code chính
├── emddi-v2-ios/            # Submodule cho iOS build
├── emddi-v2-android/        # Submodule cho Android build
├── clone-partner.sh         # Script tạo branch mới cho partner
└── build-branch.sh          # Script build app
```

## 🚀 Workflow

### 1. Clone Partner (Tạo branch mới cho partner)

Script này sẽ:
- Checkout source branch từ `emddi-v2`
- Tạo branch mới `partners/{partner-key}`
- Copy configs từ `partner-configs` submodule
- Update Firebase configs và app icon
- Commit và push branch mới
- Lưu configs vào `partner-configs` submodule

**Cách dùng:**

```bash
# Dùng partner key có sẵn
./clone-partner.sh <source-branch> --partner <partner-key> [--version <version>] [--icon <path>]

# Hoặc dùng file env tùy chỉnh
./clone-partner.sh <source-branch> --env <env-file> [--version <version>] [--icon <path>]
```

**Ví dụ:**

```bash
# Clone từ branch main cho partner "abc-taxi"
./clone-partner.sh main --partner abc-taxi

# Clone với version override
./clone-partner.sh main --partner abc-taxi --version 5.0.1-25

# Clone với icon tùy chỉnh
./clone-partner.sh main --partner abc-taxi --icon /path/to/icon.png

# Clone với env file mới
./clone-partner.sh main --env /path/to/new-partner.env.txt --icon /path/to/icon.png
```

**Version format:** `<APP_VERSION>-<APP_BUILD_CODE>` (ví dụ: `5.0.1-25`)

### 2. Build Branch

Script này sẽ:
- Chuyển vào submodule tương ứng (`emddi-v2-ios` hoặc `emddi-v2-android`)
- Checkout branch đã tạo
- Pull latest changes
- Load env file
- Validate Firebase configs
- Run Expo prebuild
- Build với Fastlane

**Cách dùng:**

```bash
./build-branch.sh <platform> <env> <branch>
```

**Tham số:**
- `platform`: `ios` hoặc `android`
- `env`: `development`, `staging`, `production`, hoặc `store`
- `branch`: tên branch cần build (ví dụ: `partners/abc-taxi`)

**Ví dụ:**

```bash
# Build iOS production
./build-branch.sh ios production partners/abc-taxi

# Build Android staging
./build-branch.sh android staging partners/abc-taxi

# Build iOS development
./build-branch.sh ios development partners/abc-taxi
```

## 📋 Cấu trúc File Configs trong partner-configs

Mỗi partner cần có 4 files trong submodule `partner-configs`:

1. **{partner-key}.env.txt** - Environment variables
   ```env
   PARTNER_KEY=abc-taxi
   APP_NAME=ABC Taxi
   APP_ID_IOS=com.abc.taxi
   APP_ID_ANDROID=com.abc.taxi
   APP_VERSION=5.0.0
   APP_BUILD_CODE=24
   # ... các biến khác
   ```

2. **{partner-key}.logo.png** - App icon (1024x1024px)

3. **{partner-key}.GoogleService-Info.plist** - Firebase config cho iOS

4. **{partner-key}.google-services.json** - Firebase config cho Android

## 🔄 Update Submodules

```bash
# Update tất cả submodules
git submodule update --remote --merge

# Update một submodule cụ thể
cd partner-configs
git pull origin main
cd ..

# Init submodules lần đầu (sau khi clone repo)
git submodule update --init --recursive
```

## 📝 Notes

- Tất cả configs của partner được lưu trong submodule `partner-configs` và sẽ được git commit/push tự động
- Mỗi platform (iOS/Android) có submodule riêng để tránh conflict khi build song song
- Branch của partner được tạo trong submodule `emddi-v2` và sẽ được reuse cho cả iOS và Android builds
- Firebase configs phải match với Bundle ID (iOS) và Package Name (Android)

## 🛠️ Troubleshooting

### Submodule rỗng sau khi clone
```bash
git submodule update --init --recursive
```

### Cần update configs trong partner-configs
```bash
cd partner-configs
# Thêm/sửa files
git add .
git commit -m "Update configs"
git push origin main
cd ..
git add partner-configs
git commit -m "Update partner-configs submodule"
```

### Conflict trong submodule
```bash
cd <submodule-name>
git fetch origin
git reset --hard origin/main
cd ..
```
