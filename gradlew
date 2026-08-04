#!/usr/bin/env sh
set -eu

APP_HOME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WRAPPER_PROPERTIES="$APP_HOME/gradle/wrapper/gradle-wrapper.properties"
DIST_URL=$(grep '^distributionUrl=' "$WRAPPER_PROPERTIES" | cut -d= -f2- | sed 's/\\:/:/g')
DIST_FILE=$(basename "$DIST_URL")
DIST_VERSION=$(printf '%s' "$DIST_FILE" | sed -E 's/gradle-([0-9.]+)-bin\.zip/\1/')
CACHE_ROOT="${GRADLE_USER_HOME:-$HOME/.gradle}/oxygenforge-wrapper"
CACHE_DIR="$CACHE_ROOT/gradle-$DIST_VERSION"
INSTALL_DIR="$CACHE_DIR/gradle-$DIST_VERSION"
ZIP_PATH="$CACHE_DIR/$DIST_FILE"

mkdir -p "$CACHE_DIR"

if [ ! -x "$INSTALL_DIR/bin/gradle" ]; then
  if [ ! -f "$ZIP_PATH" ]; then
    echo "Downloading Gradle $DIST_VERSION..."
    if command -v curl >/dev/null 2>&1; then
      curl -fL "$DIST_URL" -o "$ZIP_PATH"
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$ZIP_PATH" "$DIST_URL"
    else
      echo "Neither curl nor wget is available." >&2
      exit 1
    fi
  fi

  TMP_DIR="$CACHE_DIR/unpack"
  rm -rf "$TMP_DIR" "$INSTALL_DIR"
  mkdir -p "$TMP_DIR"
  unzip -q "$ZIP_PATH" -d "$TMP_DIR"
  FOUND_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "gradle-$DIST_VERSION" | head -n 1)
  if [ -z "$FOUND_DIR" ]; then
    echo "Could not unpack Gradle distribution." >&2
    exit 1
  fi
  mv "$FOUND_DIR" "$INSTALL_DIR"
  rm -rf "$TMP_DIR"
fi

exec "$INSTALL_DIR/bin/gradle" -p "$APP_HOME" "$@"
