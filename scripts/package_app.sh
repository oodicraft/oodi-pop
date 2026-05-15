#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="OodiPop"
PROJECT_PATH="$ROOT_DIR/OodiPop.xcodeproj"
SCHEME="OodiPop"
CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="${1:-${GITHUB_REF_NAME:-local}}"
BUILD_DIR="$ROOT_DIR/build/package"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle was not produced: $APP_PATH" >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "$ZIP_PATH"
