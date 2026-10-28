#!/bin/bash

# Jenkins historically invokes this file with `sh`, bypassing the shebang.
if [ -z "${BASH_VERSION:-}" ]; then
  exec /bin/bash "$0" "$@"
fi

# Script build branch cho Expo project - Version 2.2 (Submodule)
# Usage: ./build-branch.sh <platform> <env> <branch>

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "=========================================="
echo "🚀 BUILD BRANCH SCRIPT - EXPO VERSION 2.2"
echo "=========================================="

# Kiểm tra tham số
if [ $# -lt 3 ]; then
  echo "❌ Thiếu tham số!"
  echo "Usage: $0 <platform> <env> <branch>"
  echo "  platform: ios | android"
  echo "  env: development | staging | production | store"
  echo "  branch: tên branch cần build"
  echo ""
  echo "Example: $0 ios production partners/example-partner"
  exit 1
fi

PLATFORM=$1
ENV=$2
BRANCH=$3

# Validate platform
if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "android" ]]; then
  echo "❌ Platform không hợp lệ: $PLATFORM"
  echo "   Chỉ chấp nhận: ios | android"
  exit 1
fi

# Validate env
if [[ "$ENV" != "development" && "$ENV" != "staging" && "$ENV" != "production" && "$ENV" != "store" ]]; then
  echo "❌ Environment không hợp lệ: $ENV"
  echo "   Chỉ chấp nhận: development | staging | production | store"
  exit 1
fi

echo ""
echo "📋 Build Configuration:"
echo "  Platform: $PLATFORM"
echo "  Environment: $ENV"
echo "  Branch: $BRANCH"
echo ""

# Xác định thư mục submodule dựa vào platform
if [ "$PLATFORM" = "ios" ]; then
  echo "🍎 Bắt đầu build iOS..."
  SUBMODULE_DIR="emddi-v2-ios"
else
  echo "🤖 Bắt đầu build Android..."
  SUBMODULE_DIR="emddi-v2-android"
fi

# Check signing before checkout/prebuild changes the shared working directory.
if [ "$PLATFORM" = "ios" ]; then
  /bin/bash "$SCRIPT_DIR/scripts/ios-signing-preflight.sh"
fi

echo "📂 Chuyển vào submodule: $SUBMODULE_DIR"
cd "$SCRIPT_DIR/$SUBMODULE_DIR"

# Setup PATH
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "📌 Node version: $(node -v)"
echo "📌 Current directory: $(pwd)"
echo ""

# Git checkout
echo "🔧 Git setup..."
git reset --hard
git clean -fd && git checkout .
git fetch origin
git checkout main
git branch -D $BRANCH 2>/dev/null || true
git checkout $BRANCH
git pull origin $BRANCH

# Load env file
# Nếu env là store thì load file .env.production
if [ "$ENV" = "store" ]; then
  ENV_FILE=".env.production"
else
  ENV_FILE=".env.$ENV"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ File env không tồn tại: $ENV_FILE"
  exit 1
fi

source $ENV_FILE

echo ""
echo "📦 App Info (from env):"
echo "  APP_NAME: $APP_NAME"
echo "  APP_VERSION: $APP_VERSION"
echo "  APP_ID_IOS: $APP_ID_IOS"
echo "  APP_ID_ANDROID: $APP_ID_ANDROID"
echo ""

# Validate Firebase config
echo "🔍 Kiểm tra Firebase config..."
if [ "$PLATFORM" = "ios" ]; then
  if [ "$ENV" = "store" ]; then
    FB_FILE="./resources/GoogleService-Info-production.plist"
  else
    FB_FILE="./resources/GoogleService-Info-${ENV}.plist"
  fi
  if [ ! -f "$FB_FILE" ]; then
    echo "❌ File Firebase iOS không tồn tại: $FB_FILE"
    exit 1
  fi
  
  if grep -q "$APP_ID_IOS" "$FB_FILE"; then
    echo "  ✅ Firebase iOS hợp lệ"
  else
    echo "  ❌ Firebase iOS không hợp lệ! Bundle ID không khớp: $APP_ID_IOS"
    exit 1
  fi
else
  if [ "$ENV" = "store" ]; then
    FB_FILE="./resources/google-services-production.json"
  else
    FB_FILE="./resources/google-services-${ENV}.json"
  fi
  if [ ! -f "$FB_FILE" ]; then
    echo "❌ File Firebase Android không tồn tại: $FB_FILE"
    exit 1
  fi
  
  if grep -q "$APP_ID_ANDROID" "$FB_FILE"; then
    echo "  ✅ Firebase Android hợp lệ"
  else
    echo "  ❌ Firebase Android không hợp lệ! Package không khớp: $APP_ID_ANDROID"
    exit 1
  fi
fi

# Install dependencies
echo ""
echo "📦 Install dependencies..."
pnpm install

echo "  📦 Install Fastlane plugins..."
bundle install
bundle exec fastlane install_plugins

# Build với npm script
echo ""
echo "📦 Build với npm script..."

# Xác định npm script cần chạy
if [ "$PLATFORM" = "ios" ]; then
  case "$ENV" in
    development)
      NPM_SCRIPT="build:ios:dev"
      ;;
    staging)
      NPM_SCRIPT="build:ios:staging"
      ;;
    production)
      NPM_SCRIPT="build:ios:prod"
      ;;
    store)
      NPM_SCRIPT="build:ios:store"
      ;;
  esac
else
  case "$ENV" in
    development)
      NPM_SCRIPT="build:android:dev"
      ;;
    staging)
      NPM_SCRIPT="build:android:staging"
      ;;
    production)
      NPM_SCRIPT="build:android:prod"
      ;;
    store)
      NPM_SCRIPT="build:android:store"
      ;;
  esac
fi

echo "  📌 Running: pnpm $NPM_SCRIPT"
pnpm $NPM_SCRIPT

echo ""
echo "=========================================="
echo "✅ BUILD HOÀN THÀNH!"
echo "=========================================="
echo "Platform: $PLATFORM"
echo "Environment: $ENV"
echo "Branch: $BRANCH"
echo "App: $APP_NAME v$APP_VERSION"
echo "=========================================="
