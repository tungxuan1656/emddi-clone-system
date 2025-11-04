#!/bin/bash

# Script build branch cho Expo project
# Usage: ./scripts/build-branch-expo.sh <platform> <env> <branch>

set -e

echo "=========================================="
echo "🚀 BUILD BRANCH SCRIPT - EXPO VERSION"
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

if [ "$PLATFORM" = "ios" ]; then
  echo "🍎 Bắt đầu build iOS..."
  cd emddi-v2-ios
else
  echo "🤖 Bắt đầu build Android..."
  cd emddi-v2-android
fi

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
ENV_FILE=".env.$ENV"
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

# Expo prebuild (tạo native projects)
echo ""
echo "🔨 Expo prebuild..."
export APP_ENV=$ENV

# iOS specific setup
if [ "$PLATFORM" = "ios" ]; then
  echo ""
  echo "🍎 iOS Setup..."
  rm -rf ./ios
  npx expo prebuild --clean --platform ios
else
  echo ""
  echo "🤖 Android Setup..."
  rm -rf ./android
  npx expo prebuild --clean --platform android
fi

# Build với Fastlane
echo ""
echo "🚀 Build với Fastlane..."


# Install Fastlane dependencies
echo "  📦 Install Fastlane plugins..."
bundle update --bundler
bundle update && bundle install
bundle exec fastlane install_plugins --verbose

# Run Fastlane
echo "  🏃 Run Fastlane $PLATFORM $ENV..."
export APP_ENV=$ENV
bundle exec fastlane $PLATFORM $ENV

echo ""
echo "=========================================="
echo "✅ BUILD HOÀN THÀNH!"
echo "=========================================="
echo "Platform: $PLATFORM"
echo "Environment: $ENV"
echo "Branch: $BRANCH"
echo "App: $APP_NAME v$APP_VERSION"
echo "=========================================="
