#!/bin/bash

# Script to create a new partner environment configuration file
# Usage: ./create-partner-env.sh <APP_NAME> <PARTNER_KEY> <APP_CODE> <COLOR_PARAMS...>
# Example: ./create-partner-env.sh "My App" myapp MY_APP 'PRIMARY_COLOR="#0CC3C9"' 'PRIMARY_100="#E5F9FA"' ...

set -e

# Check if required parameters are provided
if [ $# -lt 4 ]; then
    echo "Error: Missing required parameters"
    echo "Usage: $0 <APP_NAME> <PARTNER_KEY> <APP_CODE> <COLOR_PARAMS...>"
    echo ""
    echo "Parameters:"
    echo "  APP_NAME       - The display name of the app (e.g., 'Aida Go')"
    echo "  PARTNER_KEY    - The partner key identifier (e.g., 'aidago')"
    echo "  APP_CODE       - The app code identifier (e.g., 'AIDA_GO')"
    echo "  COLOR_PARAMS   - Primary colors as separate parameters"
    echo ""
    echo "Example:"
    echo "  $0 \"My App\" myapp MY_APP 'PRIMARY_COLOR=\"#0CC3C9\"' 'PRIMARY_100=\"#E5F9FA\"' 'PRIMARY_200=\"#B3EDF1\"' 'PRIMARY_300=\"#80E2E7\"' 'PRIMARY_400=\"#4DDAE0\"' 'PRIMARY_500=\"#0CC3C9\"' 'PRIMARY_600=\"#0B989C\"' 'PRIMARY_700=\"#086C6E\"'"
    exit 1
fi

APP_NAME="$1"
PARTNER_KEY="$2"
APP_CODE="$3"
shift 3

# Initialize color variables as empty
PRIMARY_COLOR=""
PRIMARY_100=""
PRIMARY_200=""
PRIMARY_300=""
PRIMARY_400=""
PRIMARY_500=""
PRIMARY_600=""
PRIMARY_700=""

# Parse all color parameters
for param in "$@"; do
    # Extract variable name and value using sed (BSD-compatible)
    if [[ $param =~ PRIMARY_COLOR=\"(.+)\" ]]; then
        PRIMARY_COLOR="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_100=\"(.+)\" ]]; then
        PRIMARY_100="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_200=\"(.+)\" ]]; then
        PRIMARY_200="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_300=\"(.+)\" ]]; then
        PRIMARY_300="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_400=\"(.+)\" ]]; then
        PRIMARY_400="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_500=\"(.+)\" ]]; then
        PRIMARY_500="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_600=\"(.+)\" ]]; then
        PRIMARY_600="${BASH_REMATCH[1]}"
    elif [[ $param =~ PRIMARY_700=\"(.+)\" ]]; then
        PRIMARY_700="${BASH_REMATCH[1]}"
    fi
done

# Validate that all required colors are provided
MISSING_COLORS=()
if [ -z "$PRIMARY_COLOR" ]; then MISSING_COLORS+=("PRIMARY_COLOR"); fi
if [ -z "$PRIMARY_100" ]; then MISSING_COLORS+=("PRIMARY_100"); fi
if [ -z "$PRIMARY_200" ]; then MISSING_COLORS+=("PRIMARY_200"); fi
if [ -z "$PRIMARY_300" ]; then MISSING_COLORS+=("PRIMARY_300"); fi
if [ -z "$PRIMARY_400" ]; then MISSING_COLORS+=("PRIMARY_400"); fi
if [ -z "$PRIMARY_500" ]; then MISSING_COLORS+=("PRIMARY_500"); fi
if [ -z "$PRIMARY_600" ]; then MISSING_COLORS+=("PRIMARY_600"); fi
if [ -z "$PRIMARY_700" ]; then MISSING_COLORS+=("PRIMARY_700"); fi

if [ ${#MISSING_COLORS[@]} -gt 0 ]; then
    echo "❌ Error: Missing required color parameters!"
    echo ""
    echo "Missing colors:"
    for color in "${MISSING_COLORS[@]}"; do
        echo "  - $color"
    done
    echo ""
    echo "All 8 color parameters are required:"
    echo "  PRIMARY_COLOR, PRIMARY_100, PRIMARY_200, PRIMARY_300,"
    echo "  PRIMARY_400, PRIMARY_500, PRIMARY_600, PRIMARY_700"
    echo ""
    echo "Example:"
    echo "  $0 \"$APP_NAME\" $PARTNER_KEY $APP_CODE 'PRIMARY_COLOR=\"#0CC3C9\"' 'PRIMARY_100=\"#E5F9FA\"' 'PRIMARY_200=\"#B3EDF1\"' 'PRIMARY_300=\"#80E2E7\"' 'PRIMARY_400=\"#4DDAE0\"' 'PRIMARY_500=\"#0CC3C9\"' 'PRIMARY_600=\"#0B989C\"' 'PRIMARY_700=\"#086C6E\"'"
    exit 1
fi

# Generate Android package name
APP_ID_ANDROID="com.emddi.partner.$PARTNER_KEY"

# Generate iOS bundle ID
APP_ID_IOS="com.emddi.$PARTNER_KEY"

# Output file path
OUTPUT_FILE="./${PARTNER_KEY}.env.txt"

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Warning: File $OUTPUT_FILE already exists"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
fi

# Create the partner-configs directory if it doesn't exist
mkdir -p partner-configs

# Create the env file
cat > "$OUTPUT_FILE" << EOF
# CONFIG ALL APP
ENV_NAME=Production
APP_NAME="$APP_NAME"
PARTNER_KEY=$PARTNER_KEY
APP_ID_ANDROID=$APP_ID_ANDROID
APP_ID_IOS=$APP_ID_IOS
REGION="kg"

# Phiên bản app
APP_VERSION=1.0.0
APP_BUILD_CODE=1

# Key phân biệt hãng
APP_CODE=$APP_CODE

# Deeplink open app
DEEPLINK=$PARTNER_KEY

# Sửa thông tin hãng
PRIMARY_COLOR="$PRIMARY_COLOR"
PRIMARY_100="$PRIMARY_100"
PRIMARY_200="$PRIMARY_200"
PRIMARY_300="$PRIMARY_300"
PRIMARY_400="$PRIMARY_400"
PRIMARY_500="$PRIMARY_500"
PRIMARY_600="$PRIMARY_600"
PRIMARY_700="$PRIMARY_700"

# Server
BASE_URL=https://customer-v2.emddi.com/api
BASE_URL_CONVENIENT=https://api.emddi.com/gw-booking-convenient-api/api/v1
BASE_URL_MAP=https://api.emddi.com/gw-maps/maps/api
BASE_URL_MERCHANT=https://api.emddi.com/gw-merchant/api/v1
EOF

echo "✅ Successfully created partner configuration file: $OUTPUT_FILE"
echo ""
echo "Configuration details:"
echo "  APP_NAME: $APP_NAME"
echo "  PARTNER_KEY: $PARTNER_KEY"
echo "  APP_CODE: $APP_CODE"
echo "  APP_ID_ANDROID: $APP_ID_ANDROID"
echo "  APP_ID_IOS: $APP_ID_IOS"
echo "  PRIMARY_COLOR: $PRIMARY_COLOR"
echo ""
echo "You can now use this configuration with other scripts."
