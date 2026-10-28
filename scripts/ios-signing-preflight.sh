#!/bin/bash
# Run in the build process so unlocking applies to Jenkins' security session.
set -e
set +x

KEYCHAIN_PATH=${IOS_KEYCHAIN_PATH:-"$HOME/Library/Keychains/login.keychain-db"}
PASSWORD_FILE=${IOS_KEYCHAIN_PASSWORD_FILE:-"$HOME/.config/emddi-cicd/keychain-password"}

if [ ! -f "$KEYCHAIN_PATH" ]; then
  echo "❌ Signing keychain not found: $KEYCHAIN_PATH" >&2
  exit 1
fi

# Jenkins Credentials Binding can provide IOS_KEYCHAIN_PASSWORD instead.
SIGNING_PASSWORD=${IOS_KEYCHAIN_PASSWORD:-}
unset IOS_KEYCHAIN_PASSWORD
if [ -z "$SIGNING_PASSWORD" ] && [ -f "$PASSWORD_FILE" ]; then
  if [ "$(stat -f '%u' "$PASSWORD_FILE")" != "$(id -u)" ] ||
     [ "$(stat -f '%Lp' "$PASSWORD_FILE")" != "600" ]; then
    echo "❌ Keychain password file must belong to $(id -un) and have mode 600." >&2
    exit 1
  fi
  SIGNING_PASSWORD=$(cat "$PASSWORD_FILE")
fi

if [ -n "$SIGNING_PASSWORD" ]; then
  if ! /usr/bin/security unlock-keychain -p "$SIGNING_PASSWORD" "$KEYCHAIN_PATH"; then
    unset SIGNING_PASSWORD
    echo "❌ Cannot unlock the signing keychain. Run scripts/setup-ios-signing.sh locally." >&2
    exit 1
  fi
fi
unset SIGNING_PASSWORD

IDENTITIES=$(/usr/bin/security find-identity -v -p codesigning "$KEYCHAIN_PATH")
SIGNING_IDENTITY=${IOS_SIGNING_IDENTITY:-$(printf '%s\n' "$IDENTITIES" | awk '/"Apple Development:|"iPhone Developer:/ {print $2; exit}')}
if [ -z "$SIGNING_IDENTITY" ]; then
  SIGNING_IDENTITY=$(printf '%s\n' "$IDENTITIES" | awk '/"Apple Distribution:|"iPhone Distribution:/ {print $2; exit}')
fi
if [ -z "$SIGNING_IDENTITY" ]; then
  echo "❌ No valid iOS signing identity in $KEYCHAIN_PATH" >&2
  exit 1
fi

PROBE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/emddi-codesign.XXXXXX")
trap 'rm -rf "$PROBE_DIR"' EXIT
cp /usr/bin/true "$PROBE_DIR/probe"
if ! /usr/bin/codesign --force --sign "$SIGNING_IDENTITY" --keychain "$KEYCHAIN_PATH" \
    --timestamp=none "$PROBE_DIR/probe"; then
  echo "❌ Jenkins cannot use the signing private key (unlock/ACL failure)." >&2
  echo "Run scripts/setup-ios-signing.sh in Terminal on this Mac." >&2
  echo "If macOS asks for signing-key access, choose Always Allow for codesign." >&2
  exit 1
fi
/usr/bin/codesign --verify --strict "$PROBE_DIR/probe"
echo "✅ iOS signing preflight passed as $(id -un)"
