#!/bin/bash
# One-time local setup; never enter the login password in a Jenkins build log.
set -e
set +x
umask 077
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
KEYCHAIN_PATH=${IOS_KEYCHAIN_PATH:-"$HOME/Library/Keychains/login.keychain-db"}
PASSWORD_FILE=${IOS_KEYCHAIN_PASSWORD_FILE:-"$HOME/.config/emddi-cicd/keychain-password"}

if [ ! -t 0 ]; then
  echo "Run this script in an interactive Terminal on the Jenkins Mac." >&2
  exit 1
fi
IFS= read -r -s -p "Login keychain password (stored locally with mode 600 for Jenkins): " SIGNING_PASSWORD
printf '\n'
if [ -z "$SIGNING_PASSWORD" ]; then
  echo "Password cannot be empty." >&2
  exit 1
fi
/usr/bin/security unlock-keychain -p "$SIGNING_PASSWORD" "$KEYCHAIN_PATH"
# Verify access before persisting the credential. macOS may ask to Always Allow.
IOS_KEYCHAIN_PASSWORD="$SIGNING_PASSWORD" /bin/bash "$SCRIPT_DIR/ios-signing-preflight.sh"
mkdir -p "$(dirname "$PASSWORD_FILE")"
PASSWORD_TMP=$(mktemp "$PASSWORD_FILE.XXXXXX")
trap 'rm -f "$PASSWORD_TMP"' EXIT
printf '%s' "$SIGNING_PASSWORD" > "$PASSWORD_TMP"
unset SIGNING_PASSWORD
chmod 600 "$PASSWORD_TMP"
mv -f "$PASSWORD_TMP" "$PASSWORD_FILE"
echo "✅ Saved local Jenkins keychain credential: $PASSWORD_FILE"
