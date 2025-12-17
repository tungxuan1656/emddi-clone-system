# EMDDI Customer Clone System

Hệ thống quản lý và build multiple partner apps từ source code chung sử dụng Git Submodules.

## 📂 Cấu trúc Project

```
emddi-customer-clone-system/
├── partner-configs/         
│   ├── {partner-key}.env.txt
│   ├── {partner-key}.logo.png
│   ├── {partner-key}.GoogleService-Info.plist
│   └── {partner-key}.google-services.json
├── emddi-v2/              
├── emddi-v2-ios/             
├── emddi-v2-android/         
├── secrets/                  # Secrets cho Fastlane (KHÔNG commit)
│   ├── AuthKey_C7894KGAY7.p8
│   ├── emddi2024-key-fastlane-upload-aab.json
│   └── emddicustomer.jks
├── clone-partner.sh          # Script tạo branch mới cho partner
└── build-branch.sh           # Script build app
```

## 🚀 Quick Start

### 1. Setup lần đầu

```bash
git clone git@github.com:tungxuan1656/emddi-clone-system.git
cd emddi-clone-system
git clone git@github.com:tungxuan1656/emddi-customer-v2.git emddi-v2
cp -R ./emddi-v2 ./emddi-v2-ios
cp -R ./emddi-v2 ./emddi-v2-android
git clone git@github.com:tungxuan1656/emddi-customer-partner-configs.git partner-configs
git clone git@gitlab.emddi.xyz:emddi-software/emddi-onelink.git
```

### 2. Setup Secrets cho Fastlane

Tạo folder `secrets` và copy các file cần thiết cho Fastlane build:

```bash
mkdir -p secrets

# Copy các file secrets (lấy từ team hoặc 1Password/LastPass)
# iOS: Apple App Store Connect API Key
cp /path/to/AuthKey_C7894KGAY7.p8 secrets/

# Android: Google Play Service Account Key
cp /path/to/emddi2024-key-fastlane-upload-aab.json secrets/

# Android: Keystore
cp /path/to/emddicustomer.jks secrets/
```

**⚠️ LƯU Ý:**
- Folder `secrets` đã được thêm vào `.gitignore` - **KHÔNG BAO GIỜ** commit các file này
- Các file này chỉ cần ở máy build, không cần trên repo
- Lưu trữ an toàn trong 1Password/LastPass hoặc CI/CD secrets

**Chi tiết các file:**

1. **AuthKey_C7894KGAY7.p8**
   - Apple App Store Connect API Key
   - Dùng để upload app lên App Store qua Fastlane
   - Download từ: Apple Developer Portal → Keys → App Store Connect API

2. **emddi2024-key-fastlane-upload-aab.json**
   - Google Play Service Account JSON key
   - Dùng để upload app lên Google Play qua Fastlane
   - Tạo từ: Google Cloud Console → Service Accounts

3. **emddicustomer.jks**
   - Android keystore file
   - Dùng để sign APK/AAB cho production
   - Bảo mật mật khẩu keystore trong env hoặc CI/CD secrets

### 3. Tạo partner mới

```bash
# Chuẩn bị configs trong partner-configs (xem mục "Partner Configs")
cd partner-configs
git add .
git commit -m "Add partner: abc-taxi"
git push origin main
cd ..

# Tạo branch cho partner
./clone-partner.sh main --partner abc-taxi

# Build
./build-branch.sh ios production partners/abc-taxi
./build-branch.sh android production partners/abc-taxi
```

## 📝 Chi tiết Scripts

### clone-partner.sh

Tạo branch mới cho partner trong submodule `emddi-v2`, copy configs và tự động commit vào `partner-configs`.

**Cách dùng:**
```bash
./clone-partner.sh <source-branch> --partner <partner-key> [--version <version>] [--icon <path>]
./clone-partner.sh <source-branch> --env <env-file> [--version <version>] [--icon <path>]
```

**Ví dụ:**
```bash
# Dùng partner có sẵn
./clone-partner.sh main --partner abc-taxi

# Override version (format: version-buildcode)
./clone-partner.sh main --partner abc-taxi --version 5.0.1-25

# Dùng icon tùy chỉnh
./clone-partner.sh main --partner abc-taxi --icon /path/to/icon.png

# Dùng env file mới
./clone-partner.sh main --env /path/to/partner.env.txt --icon /path/to/icon.png
```

**Script sẽ:**
- ✅ Tạo branch `partners/{partner-key}` trong `emddi-v2`
- ✅ Copy configs từ `partner-configs`
- ✅ Setup Firebase và app icon
- ✅ Tạo env files cho development/staging/production
- ✅ **Tự động lưu thay đổi (version, logo) vào `partner-configs` và commit/push**
- ✅ Commit và push branch mới

### build-branch.sh

Build app cho platform và environment cụ thể.

**Cách dùng:**
```bash
./build-branch.sh <platform> <env> <branch>
```

**Tham số:**
- `platform`: `ios` | `android`
- `env`: `development` | `staging` | `production` | `store`
- `branch`: `partners/{partner-key}`

**Ví dụ:**
```bash
./build-branch.sh ios production partners/abc-taxi
./build-branch.sh android staging partners/abc-taxi
```

## 📋 Partner Configs

Mỗi partner cần 4 files trong `partner-configs` submodule:

### 1. {partner-key}.env.txt
```env
# Partner Information
PARTNER_KEY=abc-taxi
APP_NAME=ABC Taxi
APP_SLUG=abc-taxi

# App IDs
APP_ID_IOS=com.emddi.abc.taxi
APP_ID_ANDROID=com.emddi.abc.taxi

# Version
APP_VERSION=5.0.0
APP_BUILD_CODE=24

# Environment
ENV_NAME=Production

# API
BASE_URL=https://api.emddi.com/customer-api/api
SOCKET_URL=https://api.emddi.com
CHAT_API_URL=https://chat-api.emddi.com/api/v1

# Map & Services
GOOGLE_MAP_API_KEY_IOS=your-key
GOOGLE_MAP_API_KEY_ANDROID=your-key
ONESIGNAL_APP_ID=your-onesignal-id

# Social Login (optional)
FACEBOOK_APP_ID=your-facebook-id
GOOGLE_WEB_CLIENT_ID=your-google-client-id
```

### 2. {partner-key}.logo.png
- Kích thước: **1024x1024px**
- Format: PNG (khuyến nghị transparent background)
- Dùng làm app icon cho cả iOS và Android

### 3. {partner-key}.GoogleService-Info.plist
Firebase config cho iOS (download từ Firebase Console)
- Bundle ID phải trùng với `APP_ID_IOS`

### 4. {partner-key}.google-services.json
Firebase config cho Android (download từ Firebase Console)
- Package name phải trùng với `APP_ID_ANDROID`

## 🔄 Workflow Chi tiết

### Tạo partner mới hoàn toàn

```bash
# 1. Tạo 4 files trong partner-configs
cd partner-configs
# Copy template và chỉnh sửa
cp example-partner.env.txt new-partner.env.txt
# Add logo, Firebase configs...

git add .
git commit -m "Add new partner: new-partner"
git push origin main
cd ..

# 2. Clone partner
./clone-partner.sh main --partner new-partner

# 3. Build
./build-branch.sh ios production partners/new-partner
```

### Update partner hiện có

```bash
# Update configs trực tiếp trong partner-configs
cd partner-configs
# Sửa file .env.txt, thay logo, etc...
git add .
git commit -m "Update new-partner configs"
git push origin main
cd ..

# Re-clone để update branch
./clone-partner.sh main --partner new-partner

# Build lại
./build-branch.sh ios production partners/new-partner
```

### Update version cho partner

```bash
# Cách 1: Override version khi clone (khuyến nghị)
./clone-partner.sh main --partner abc-taxi --version 5.1.0-26
# -> Version sẽ được tự động lưu vào partner-configs

# Cách 2: Sửa trực tiếp trong partner-configs
cd partner-configs
# Edit abc-taxi.env.txt: APP_VERSION=5.1.0, APP_BUILD_CODE=26
git add abc-taxi.env.txt
git commit -m "Update abc-taxi version to 5.1.0-26"
git push origin main
cd ..
./clone-partner.sh main --partner abc-taxi
```

### Update logo cho partner

```bash
# Cách 1: Override logo khi clone (khuyến nghị)
./clone-partner.sh main --partner abc-taxi --icon /path/to/new-logo.png
# -> Logo sẽ được tự động lưu vào partner-configs

# Cách 2: Thay trực tiếp trong partner-configs
cd partner-configs
cp /path/to/new-logo.png abc-taxi.logo.png
git add abc-taxi.logo.png
git commit -m "Update abc-taxi logo"
git push origin main
cd ..
./clone-partner.sh main --partner abc-taxi
```

## 🏗️ Build Environments

### Development
```bash
./build-branch.sh ios development partners/abc-taxi
```
- API: `https://api.dev.emddi.net`
- Dùng file: `.env.development`

### Staging
```bash
./build-branch.sh ios staging partners/abc-taxi
```
- API: `https://api.uat.emddi.xyz`
- Dùng file: `.env.staging`

### Production
```bash
./build-branch.sh ios production partners/abc-taxi
```
- API: `https://api.emddi.com`
- Dùng file: `.env.production`

## 🔧 Submodule Management

### Init submodules (lần đầu)
```bash
git submodule update --init --recursive
```

### Update tất cả submodules
```bash
git submodule update --remote --merge
```

### Update submodule cụ thể
```bash
cd partner-configs
git pull origin main
cd ..
```

### Reset submodule về clean state
```bash
cd emddi-v2-ios  # hoặc android, emddi-v2
git reset --hard origin/main
git clean -fd
cd ..
```

### Xem branch hiện tại của submodules
```bash
git submodule foreach 'echo $name: $(git rev-parse --abbrev-ref HEAD)'
```

## 💡 Tips & Best Practices

1. **Build song song**: iOS và Android dùng submodule riêng → có thể build cùng lúc
2. **Version control tự động**: Script tự động commit changes vào `partner-configs`
3. **Configs tập trung**: Tất cả configs trong `partner-configs`, dễ quản lý
4. **Branch naming**: Luôn dùng format `partners/{partner-key}`
5. **Override version/logo**: Dùng flags `--version` và `--icon` khi clone
6. **Firebase validation**: Script tự động validate Bundle ID/Package name

## 🛠️ Troubleshooting

### Submodule rỗng hoặc bị lỗi
```bash
git submodule update --init --recursive
```

### Conflict trong submodule
```bash
cd <submodule-name>
git fetch origin
git reset --hard origin/main
cd ..
```

### Cần update submodule reference trong main repo
```bash
cd partner-configs
git pull origin main
cd ..
git add partner-configs
git commit -m "Update partner-configs submodule reference"
git push origin main
```

### Firebase config không match
- Kiểm tra `APP_ID_IOS` trong `.env.txt` phải trùng với Bundle ID trong `GoogleService-Info.plist`
- Kiểm tra `APP_ID_ANDROID` trong `.env.txt` phải trùng với package_name trong `google-services.json`

### Build failed
```bash
# Clean và rebuild
cd emddi-v2-ios  # hoặc emddi-v2-android
git clean -fd
rm -rf ios android node_modules
pnpm install
cd ..
./build-branch.sh ios production partners/abc-taxi
```

### Fastlane không tìm thấy secrets
```bash
# Kiểm tra folder secrets tồn tại
ls -la secrets/

# Kết quả mong đợi:
# AuthKey_C7894KGAY7.p8
# emddi2024-key-fastlane-upload-aab.json
# emddicustomer.jks

# Nếu thiếu, copy lại từ nguồn an toàn
mkdir -p secrets
# Copy các file...
```

### Keystore hoặc API key hết hạn
- **iOS**: Tạo lại API Key mới từ Apple Developer Portal
- **Android**: Tạo lại Service Account key từ Google Cloud Console
- **Keystore**: Không được làm mất, nếu mất phải tạo app mới

## 📊 Quản lý Partners

### Liệt kê tất cả partners
```bash
cd partner-configs
ls -1 *.env.txt | sed 's/.env.txt//'
cd ..
```

### Xem thông tin partner
```bash
cat partner-configs/abc-taxi.env.txt | grep -E "APP_NAME|APP_VERSION|APP_BUILD_CODE"
```

### Danh sách branches của partners
```bash
cd emddi-v2
git branch -r | grep partners/
cd ..
```
