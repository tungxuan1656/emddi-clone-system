#!/bin/bash

# Script clone partner cho Expo project - Version 2.2 (Submodule)
# Usage: 
#   ./clone-partner.sh <branch> --partner <partner-key> [--version <version>] [--icon <path>]
#   ./clone-partner.sh <branch> --env <env-file> [--version <version>] [--icon <path>]

set -e

echo "=========================================="
echo "🚀 CLONE PARTNER SCRIPT - EXPO VERSION 2.2"
echo "=========================================="

# Kiểm tra tham số
if [ $# -lt 3 ]; then
  echo "❌ Thiếu tham số!"
  echo ""
  echo "  Usage: $0 <branch> --partner <partner-key> --env <env-file> [--version <version>] [--icon <path>]"
  echo ""
  echo "Version format: <APP_VERSION>-<APP_BUILD_CODE> (ví dụ: 5.0.1-25)"
  exit 1
fi

SOURCE_BRANCH=$1
shift

# Đặt CONFIGS_DIR là đường dẫn tuyệt đối đến folder hiện tại + /partner-configs
CONFIGS_DIR="$(pwd)/partner-configs"
PARTNER_KEY=""
ENV_FILE=""
VERSION_OVERRIDE=""
APP_VERSION_OVERRIDE=""
APP_BUILD_CODE_OVERRIDE=""
APP_ICON_PATH=""
USE_ENV_FILE=false

cd $CONFIGS_DIR
git fetch
git pull --rebase
cd ..
pwd

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --partner)
      PARTNER_KEY="$2"
      shift 2
      ;;
    --env)
      ENV_FILE="$2"
      USE_ENV_FILE=true
      shift 2
      ;;
    --version)
      VERSION_OVERRIDE="$2"
      shift 2
      ;;
    --icon)
      APP_ICON_PATH="$2"
      shift 2
      ;;
    *)
      echo "❌ Tham số không hợp lệ: $1"
      exit 1
      ;;
  esac
done

# Validate: phải có --partner hoặc --env
if [ -z "$PARTNER_KEY" ] && [ -z "$ENV_FILE" ]; then
  echo "❌ Phải có --partner hoặc --env"
  exit 1
fi

if [ -n "$PARTNER_KEY" ] && [ -n "$ENV_FILE" ]; then
  echo "❌ Không thể dùng cả --partner và --env cùng lúc"
  exit 1
fi

# Xác định env file
if [ "$USE_ENV_FILE" = true ]; then
  if [ ! -f "$ENV_FILE" ]; then
    echo "❌ File env không tồn tại: $ENV_FILE"
    exit 1
  fi
else
  # Tìm env file trong partner-configs
  ENV_FILE="${CONFIGS_DIR}/${PARTNER_KEY}.env.txt"
  if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Không tìm thấy env file cho partner: $PARTNER_KEY"
    echo "   Đường dẫn: $ENV_FILE"
    echo ""
    echo "💡 Các partner có sẵn:"
    ls -1 ${CONFIGS_DIR}/*.env.txt 2>/dev/null | xargs -n1 basename | sed 's/.env.txt//' | sed 's/^/   - /'
    exit 1
  fi
fi

# Parse version override nếu có
if [ -n "$VERSION_OVERRIDE" ]; then
  if [[ $VERSION_OVERRIDE =~ ^([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+)$ ]]; then
    APP_VERSION_OVERRIDE="${BASH_REMATCH[1]}"
    APP_BUILD_CODE_OVERRIDE="${BASH_REMATCH[2]}"
    echo "📌 Version override: $APP_VERSION_OVERRIDE (build: $APP_BUILD_CODE_OVERRIDE)"
  else
    echo "❌ Version format không hợp lệ: $VERSION_OVERRIDE"
    echo "   Format đúng: <version>-<build_code> (ví dụ: 5.0.1-25)"
    exit 1
  fi
fi

# Load biến môi trường
source $ENV_FILE

# Validate thông tin partner
if [ -z "$PARTNER_KEY" ]; then
  echo "❌ PARTNER_KEY không được để trống trong file env"
  exit 1
fi

if [ -z "$APP_NAME" ]; then
  echo "❌ APP_NAME không được để trống trong file env"
  exit 1
fi

echo ""
echo "📋 Thông tin Partner:"
echo "  PARTNER_KEY: $PARTNER_KEY"
echo "  APP_NAME: $APP_NAME"
echo "  APP_ID_IOS: $APP_ID_IOS"
echo "  APP_ID_ANDROID: $APP_ID_ANDROID"
if [ -n "$APP_VERSION_OVERRIDE" ]; then
  echo "  APP_VERSION: $APP_VERSION_OVERRIDE (override từ: $APP_VERSION)"
  echo "  APP_BUILD_CODE: $APP_BUILD_CODE_OVERRIDE (override từ: $APP_BUILD_CODE)"
else
  echo "  APP_VERSION: $APP_VERSION"
  echo "  APP_BUILD_CODE: $APP_BUILD_CODE"
fi
echo "  SOURCE_BRANCH: $SOURCE_BRANCH"
echo ""

# Xác định đường dẫn Firebase configs
FB_IOS_PATH="${CONFIGS_DIR}/${PARTNER_KEY}.GoogleService-Info.plist"
FB_ANDROID_PATH="${CONFIGS_DIR}/${PARTNER_KEY}.google-services.json"

# Chuyển vào thư mục emddi-v2
echo ""
echo "📂 Chuyển vào submodule emddi-v2..."
cd emddi-v2

# Kiểm tra Firebase files
if [ ! -f "$FB_IOS_PATH" ]; then
  echo "❌ Không tìm thấy Firebase iOS config: $FB_IOS_PATH"
  exit 1
fi

if [ ! -f "$FB_ANDROID_PATH" ]; then
  echo "❌ Không tìm thấy Firebase Android config: $FB_ANDROID_PATH"
  exit 1
fi

# Xác định đường dẫn app icon
if [ -n "$APP_ICON_PATH" ]; then
  # Có truyền icon path - cần chuyển sang absolute path
  if [ ! -f "$APP_ICON_PATH" ]; then
    echo "❌ File app icon không tồn tại: $APP_ICON_PATH"
    exit 1
  fi
  
  # Chuyển sang absolute path
  if [[ "$APP_ICON_PATH" != /* ]]; then
    APP_ICON_PATH="$(cd "$(dirname "$APP_ICON_PATH")" && pwd)/$(basename "$APP_ICON_PATH")"
  fi
  
  echo "📄 Icon được truyền vào: $APP_ICON_PATH"
  
  # Kiểm tra xem có phải file PNG 1024x1024 hay không
  NEED_CONVERT=false
  if command -v identify &> /dev/null; then
    ICON_INFO=$(identify -format "%wx%h %m" "$APP_ICON_PATH" 2>/dev/null || echo "")
    if [[ ! "$ICON_INFO" =~ ^1024x1024\ PNG ]]; then
      echo "⚙️  Icon cần được chuyển đổi sang PNG 1024x1024"
      NEED_CONVERT=true
    else
      echo "✅ Icon đã đúng định dạng PNG 1024x1024"
    fi
  else
    # Không có ImageMagick, kiểm tra extension
    if [[ ! "$APP_ICON_PATH" =~ \.png$ ]]; then
      echo "⚙️  Icon không phải PNG, cần chuyển đổi"
      NEED_CONVERT=true
    fi
  fi
  
  # Convert icon nếu cần
  if [ "$NEED_CONVERT" = true ]; then
    echo "🎨 Converting và resizing icon..."
    
    # Check if ImageMagick is installed
    if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
      echo "❌ Error: ImageMagick is not installed"
      echo "   Icon sẽ được sử dụng nguyên bản (không convert)"
      echo "   Để convert tự động, cài đặt ImageMagick: brew install imagemagick"
    else
      # Determine convert command
      CONVERT_CMD="convert"
      if command -v magick &> /dev/null; then
        CONVERT_CMD="magick"
      fi
      
      # Tạo file tạm cho icon đã convert
      TEMP_ICON_PATH="${CONFIGS_DIR}/.temp_${PARTNER_KEY}_icon.png"
      
      # Convert và resize
      $CONVERT_CMD "$APP_ICON_PATH" -resize 1024x1024 -background none -gravity center -extent 1024x1024 "$TEMP_ICON_PATH"
      
      if [ $? -eq 0 ]; then
        # Lấy kích thước file
        ICON_SIZE=$(du -h "$TEMP_ICON_PATH" | cut -f1)
        echo "  ✅ Icon converted: $TEMP_ICON_PATH (size: $ICON_SIZE)"
        
        # Cập nhật APP_ICON_PATH để sử dụng file đã convert
        APP_ICON_PATH="$TEMP_ICON_PATH"
      else
        echo "  ⚠️  Convert thất bại, sử dụng icon gốc"
      fi
    fi
  fi
  
  SKIP_ICON=false
  ICON_SOURCE="custom"
elif [ -f "${CONFIGS_DIR}/${PARTNER_KEY}.logo.png" ]; then
  APP_ICON_PATH="${CONFIGS_DIR}/${PARTNER_KEY}.logo.png"
  echo "📄 Sử dụng icon từ partner-configs: $APP_ICON_PATH"
  SKIP_ICON=false
  ICON_SOURCE="config"
else
  echo "⚠️  Không tìm thấy app icon trong partner-configs: ${CONFIGS_DIR}/${PARTNER_KEY}.logo.png"
  echo "   Sẽ giữ nguyên icon hiện tại"
  SKIP_ICON=true
  ICON_SOURCE="none"
fi

# Validate Firebase config
echo "🔍 Kiểm tra Firebase config..."
if grep -q "$APP_ID_IOS" "$FB_IOS_PATH"; then
  echo "  ✅ Firebase iOS hợp lệ (bundle ID: $APP_ID_IOS)"
else
  echo "  ❌ Firebase iOS không hợp lệ! Bundle ID không khớp: $APP_ID_IOS"
  exit 1
fi

if grep -q "$APP_ID_ANDROID" "$FB_ANDROID_PATH"; then
  echo "  ✅ Firebase Android hợp lệ (package: $APP_ID_ANDROID)"
else
  echo "  ❌ Firebase Android không hợp lệ! Package không khớp: $APP_ID_ANDROID"
  exit 1
fi

# Tạo tên branch
BRANCH_NAME="partners/$PARTNER_KEY"
echo ""
echo "🌿 Branch: $BRANCH_NAME"


# Git setup - xoá branch cũ nếu tồn tại
echo ""
echo "🔧 Git setup..."
git clean -fd && git checkout .
git fetch origin
echo "  ✨ Checkout branch: $SOURCE_BRANCH"
git checkout $SOURCE_BRANCH
git pull origin $SOURCE_BRANCH


# Xoá branch remote nếu tồn tại
if git ls-remote --exit-code --heads origin $BRANCH_NAME > /dev/null 2>&1; then
  echo "  🗑️  Xoá branch remote cũ: $BRANCH_NAME"
  git push origin --delete $BRANCH_NAME || true
else
  echo "  ⏭️  Không có branch remote để xoá: $BRANCH_NAME"
fi

# Xoá branch local nếu tồn tại
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
  echo "  🗑️  Xoá branch local cũ: $BRANCH_NAME"
  git branch -D $BRANCH_NAME
fi
# Checkout source branch
git checkout -b $BRANCH_NAME

# Copy resources
echo ""
echo "📦 Copy resources..."

# Copy Firebase configs cho tất cả môi trường (development, staging, production)
echo "  📄 Copy Firebase configs..."
cp "$FB_IOS_PATH" "./resources/GoogleService-Info-development.plist"
cp "$FB_IOS_PATH" "./resources/GoogleService-Info-staging.plist"
cp "$FB_IOS_PATH" "./resources/GoogleService-Info-production.plist"

cp "$FB_ANDROID_PATH" "./resources/google-services-development.json"
cp "$FB_ANDROID_PATH" "./resources/google-services-staging.json"
cp "$FB_ANDROID_PATH" "./resources/google-services-production.json"

echo "  🎨 Copy app icon..."
if [ "$SKIP_ICON" = false ]; then
  cp "$APP_ICON_PATH" "./resources/app-icon.png"
  echo "     ✅ Icon đã được cập nhật"
else
  echo "     ⏭️  Giữ nguyên icon hiện tại"
fi

# Copy env files cho các môi trường
echo "  ⚙️  Copy env configs..."
cp "$ENV_FILE" "./.env.production"

# Tạo env files cho development và staging
cat "$ENV_FILE" > "./.env.development"
cat "$ENV_FILE" > "./.env.staging"

# Override version nếu có
if [ -n "$APP_VERSION_OVERRIDE" ]; then
  echo "  🔢 Update version..."
  sed -i '' "s|APP_VERSION=.*|APP_VERSION=$APP_VERSION_OVERRIDE|" ./.env.production
  sed -i '' "s|APP_VERSION=.*|APP_VERSION=$APP_VERSION_OVERRIDE|" ./.env.development
  sed -i '' "s|APP_VERSION=.*|APP_VERSION=$APP_VERSION_OVERRIDE|" ./.env.staging
  
  sed -i '' "s|APP_BUILD_CODE=.*|APP_BUILD_CODE=$APP_BUILD_CODE_OVERRIDE|" ./.env.production
  sed -i '' "s|APP_BUILD_CODE=.*|APP_BUILD_CODE=$APP_BUILD_CODE_OVERRIDE|" ./.env.development
  sed -i '' "s|APP_BUILD_CODE=.*|APP_BUILD_CODE=$APP_BUILD_CODE_OVERRIDE|" ./.env.staging
  echo "     ✅ Version updated: $APP_VERSION_OVERRIDE (build: $APP_BUILD_CODE_OVERRIDE)"
fi

# Chỉnh sửa env development
sed -i '' 's/ENV_NAME=production/ENV_NAME=development/' ./.env.development
sed -i '' "s|BASE_URL=.*|BASE_URL=https://api.dev.emddi.net/customer-api/api|" ./.env.development
sed -i '' 's|https://api.emddi.com|https://api.dev.emddi.net|g' ./.env.development

# Chỉnh sửa env staging
sed -i '' 's/ENV_NAME=production/ENV_NAME=staging/' ./.env.staging
sed -i '' "s|BASE_URL=.*|BASE_URL=https://api.uat.emddi.net/customer-api/api|" ./.env.staging
sed -i '' 's|https://api.emddi.com|https://api.emddi.com|g' ./.env.staging

# Lưu configs vào submodule partner-configs
echo ""
echo "💾 Lưu configs vào submodule partner-configs..."
cd ${CONFIGS_DIR}

# Copy env file vào partner-configs nếu ENV_FILE được truyền từ ngoài vào
if [ "$USE_ENV_FILE" = true ]; then
  cp "$ENV_FILE" "./${PARTNER_KEY}.env.txt"
fi
# Nếu có version override thì cập nhật version trong file env
if [ -n "$APP_VERSION_OVERRIDE" ]; then
  sed -i '' "s|APP_VERSION=.*|APP_VERSION=$APP_VERSION_OVERRIDE|" "./${PARTNER_KEY}.env.txt"
  sed -i '' "s|APP_BUILD_CODE=.*|APP_BUILD_CODE=$APP_BUILD_CODE_OVERRIDE|" "./${PARTNER_KEY}.env.txt"
  echo "  ✅ Updated version trong partner-configs: $APP_VERSION_OVERRIDE (build: $APP_BUILD_CODE_OVERRIDE)"
fi

# Copy logo vào partner-configs chỉ khi có APP_ICON_PATH truyền vào từ câu lệnh
if [ "$SKIP_ICON" = false ] && [ "$ICON_SOURCE" = "custom" ]; then
  TARGET_LOGO_PATH="./${PARTNER_KEY}.logo.png"
  
  # Kiểm tra xem icon đã tồn tại và giống nhau hay chưa
  if [ -f "$TARGET_LOGO_PATH" ] && cmp -s "$APP_ICON_PATH" "$TARGET_LOGO_PATH"; then
    echo "  ⏭️  Logo đã giống nhau, không cần copy"
  else
    cp "$APP_ICON_PATH" "$TARGET_LOGO_PATH"
    
    # Lấy kích thước file
    LOGO_SIZE=$(du -h "$TARGET_LOGO_PATH" | cut -f1)
    
    # Kiểm tra kích thước ảnh nếu có ImageMagick
    if command -v identify &> /dev/null; then
      LOGO_DIMENSIONS=$(identify -format "%wx%h" "$TARGET_LOGO_PATH" 2>/dev/null || echo "unknown")
      echo "  ✅ Updated logo trong partner-configs (${LOGO_DIMENSIONS}, ${LOGO_SIZE})"
    else
      echo "  ✅ Updated logo trong partner-configs (${LOGO_SIZE})"
    fi
  fi
fi

# Git commit trong partner-configs
# Cleanup temporary icon file if exists
if [ -n "$TEMP_ICON_PATH" ] && [ -f "$TEMP_ICON_PATH" ]; then
  echo ""
  echo "🧹 Cleanup temporary files..."
  rm -f "$TEMP_ICON_PATH"
  echo "  ✅ Removed temporary icon file"
fi
echo "  📤 Commit configs trong partner-configs..."
git add .
if git diff --staged --quiet; then
  echo "  ⏭️  Không có thay đổi trong partner-configs"
else
  COMMIT_MSG="📝 Update configs cho partner: $PARTNER_KEY

- Partner: $PARTNER_KEY
- App: $APP_NAME
- Version: ${APP_VERSION_OVERRIDE:-$APP_VERSION} (build: ${APP_BUILD_CODE_OVERRIDE:-$APP_BUILD_CODE})
- iOS Bundle ID: $APP_ID_IOS
- Android Package: $APP_ID_ANDROID"

  if [ -n "$APP_VERSION_OVERRIDE" ]; then
    COMMIT_MSG="$COMMIT_MSG
- Version updated from $APP_VERSION to $APP_VERSION_OVERRIDE"
  fi

  if [ "$SKIP_ICON" = false ]; then
    COMMIT_MSG="$COMMIT_MSG
- Logo updated"
  fi

  git commit -m "$COMMIT_MSG"
  git push origin main
  echo "  ✅ Đã commit và push partner-configs"
fi

# Quay lại thư mục emddi-v2
cd ../emddi-v2

# Install dependencies (optional)
echo ""
echo "📦 Install dependencies..."
yarn install
yarn rounded-icon

# Git commit và push
echo ""
echo "📤 Git commit và push..."
git add .

# Tạo commit message
COMMIT_VERSION="${APP_VERSION_OVERRIDE:-$APP_VERSION}"
COMMIT_BUILD_CODE="${APP_BUILD_CODE_OVERRIDE:-$APP_BUILD_CODE}"

git commit -m "🎉 Init partner: $APP_NAME ($PARTNER_KEY)

- App Name: $APP_NAME
- Partner Key: $PARTNER_KEY
- Version: $COMMIT_VERSION (build: $COMMIT_BUILD_CODE)
- iOS Bundle ID: $APP_ID_IOS
- Android Package: $APP_ID_ANDROID
"

git push --set-upstream origin $BRANCH_NAME

echo ""
echo "=========================================="
echo "✅ HOÀN THÀNH!"
echo "=========================================="
echo "Branch: $BRANCH_NAME (trong submodule emddi-v2)"
echo "App Name: $APP_NAME"
echo "Partner Key: $PARTNER_KEY"
echo ""
echo "🚀 Các bước tiếp theo:"
echo "  1. Build iOS production: ./build-branch.sh ios production $BRANCH_NAME"
echo "  2. Build Android production: ./build-branch.sh android production $BRANCH_NAME"
echo "=========================================="
