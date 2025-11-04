#!/bin/bash

# Script build branch cho Expo project - Version 2.2 (Submodule)
# Usage: ./build-branch.sh <platform> <env> <branch>

set -e

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

echo "📂 Chuyển vào submodule: $SUBMODULE_DIR"
cd $SUBMODULE_DIR

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
git clean -fd
git fetch origin
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
  FB_FILE="./resources/GoogleService-Info-${ENV}.plist"
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
  FB_FILE="./resources/google-services-${ENV}.json"
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
yarn install

echo "  📦 Install Fastlane plugins..."
bundle update --bundler
bundle update && bundle install
bundle exec fastlane install_plugins --verbose

# Build với npm script
echo ""
echo "� Build với npm script..."

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

echo "  📌 Running: yarn $NPM_SCRIPT"
yarn $NPM_SCRIPT

echo ""
echo "=========================================="
echo "✅ BUILD HOÀN THÀNH!"
echo "=========================================="
echo "Platform: $PLATFORM"
echo "Environment: $ENV"
echo "Branch: $BRANCH"
echo "App: $APP_NAME v$APP_VERSION"
echo "=========================================="
