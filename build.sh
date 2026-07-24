#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

CWD=$(pwd)
TARGET_DIR="../sources"
BUILD_DIR="$CWD/build"
VERSION_JSON="$CWD/manifest.json"

case "$1" in
    --cuda)     PARAM="cuda" ;;
    --directml) PARAM="directml" ;;
    --openvino) PARAM="openvino" ;;
    --cpu|*)    PARAM="cpu" ;;
esac

echo "🚀 [START] Starting Automated Dynamic Build & Packing Process..."
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Target directory '$TARGET_DIR' not found!"
    echo "Please verify that the relative path  exists."
    exit 1
fi

if [ ! -f "$VERSION_JSON" ]; then
    echo "❌ Error: File version.json not found at $VERSION_JSON!"
    exit 1
fi

# Dynamically parse "version": "x.x.x" using pure Bash grep + sed (cross-platform friendly)
BACKEND_VER=$(jq -r '.backend.version' "$VERSION_JSON")

if [ -z "$BACKEND_VER" ]; then
    echo "⚠️  Warning: Failed to detect version from JSON. Falling back to default: 1.0.0"
    BACKEND_VER="1.0.0"
else
    echo "🏷️  Successfully detected project version: v$BACKEND_VER"
fi

# Pastikan build dir ada, tapi jangan dihapus isinya (incremental build)
mkdir -p "$BUILD_DIR"

# ── Helper: cek versi artifact yang sudah ada ─────────────────────────────────
# Args: $1 = glob pattern file lama (mis. "backend_*_linux_amd64.tar.gz")
#       $2 = nama file target versi baru (path lengkap)
# Return: 0 (true) kalau harus di-skip (versi sama sudah ada)
#         1 (false) kalau harus lanjut build (file lama dihapus 1/1 kalau ada)
check_artifact() {
    local glob_pattern="$1"
    local target_file="$2"

    if [ -f "$target_file" ]; then
        echo "⏭️  Duplicate version found ($(basename "$target_file")), skip build."
        return 0
    fi

    # Hapus file versi lama satu per satu (kalau ada)
    local found_old=0
    for old_file in $BUILD_DIR/$glob_pattern; do
        [ -e "$old_file" ] || continue
        echo "🗑️  Deleting old artifact: $(basename "$old_file")"
        rm -f "$old_file"
        found_old=1
    done
    [ "$found_old" -eq 0 ] && echo "ℹ️  Nothing artifacts, building new."

    return 1
}

echo "📦 [1/4] Processing Backend..."
BACKEND_TARGET="$BUILD_DIR/backend_${BACKEND_VER}_linux_amd64.tar.gz"

if check_artifact "backend_*_linux_amd64.tar.gz" "$BACKEND_TARGET"; then
    :
else
    cd "$TARGET_DIR/backend"

    echo "🛠️  Compiling Go binary for Linux AMD64..."
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-w -s" -o backend main.go

    echo "🤐 Compressing Backend to .tar.gz..."
    tar -czf "$BACKEND_TARGET" backend --transform 's|^./packages/models|models|' ./packages/models/

    # Clean up the local temporary binary after packing
    rm backend
    echo "✅ Backend successfully compressed."
    cd "$CWD"
fi

echo "📦 [2/4] Processing Worker..."
cd "$CWD"
cd "$TARGET_DIR/worker"
WORKER_VER=$(jq -r '.worker.version' "$VERSION_JSON")
cd "$CWD"

WORKER_TARGET="$BUILD_DIR/worker_${WORKER_VER}_${PARAM}_linux_amd64.tar.gz"

if check_artifact "worker_*_${PARAM}_linux_amd64.tar.gz" "$WORKER_TARGET"; then
    :
else
    cd "$TARGET_DIR/worker"

    # Binary worker sekarang berada di ./.build/main_{param}.bin
    WORKER_BIN=".build/main_${PARAM}.bin"
    if [ ! -f "$WORKER_BIN" ]; then
        echo "❌ Error: Worker binary not found at $WORKER_BIN"
        exit 1
    fi

    echo "🤐 Compressing Worker binary & Models folder to .tar.gz..."
    tar -czf "$WORKER_TARGET" \
        --transform="s|^$(basename "$WORKER_BIN")\$|main.bin|" \
        -C "$(dirname "$WORKER_BIN")" "$(basename "$WORKER_BIN")" \
        -C "../" models
    echo "✅ Worker successfully compressed."
    cd "$CWD"
fi

echo "📦 [3/4] Processing Updater..."
cd "$CWD"
cd "$TARGET_DIR/updater"
UPDATER_VER=$(jq -r '.updater.version' "$VERSION_JSON")
cd "$CWD"

UPDATER_TARGET="$BUILD_DIR/updater_${UPDATER_VER}_linux_amd64.tar.gz"

if check_artifact "updater_*_linux_amd64.tar.gz" "$UPDATER_TARGET"; then
    :
else
    cd "$TARGET_DIR/updater"

    echo "🛠️  Compiling Updater binary for Linux AMD64..."
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-w -s" -o updater .

    echo "🤐 Compressing Updater to .tar.gz..."
    tar -czf "$UPDATER_TARGET" updater

    # Clean up the local temporary binary after packing
    rm updater
    echo "✅ Updater successfully compressed."
    cd "$CWD"
fi

echo "📦 [4/4] Processing WebUI..."
cd "$CWD"
cd "$TARGET_DIR/web-ui"
WEBUI_VER=$(jq -r '.webui.version' "$VERSION_JSON")
cd "$CWD"

WEBUI_TARGET="$BUILD_DIR/webui_${WEBUI_VER}_linux_amd64.tar.gz"

if check_artifact "webui_*_linux_amd64.tar.gz" "$WEBUI_TARGET"; then
    :
else
    cd "$TARGET_DIR/web-ui"

    echo "🛠️  Running Next.js production build in standalone mode..."
    bun run build

    echo "📁 Injecting required static assets directly into the standalone directory..."
    # Inject static assets into the standalone directory structure
    if [ -d ".next/static" ]; then
        mkdir -p .next/standalone/.next
        cp -r .next/static .next/standalone/.next/
    fi

    if [ -d "public" ]; then
        cp -r public .next/standalone/
    fi

    # Navigate directly into the built standalone directory for isolated compression
    cd .next/standalone

    echo "🤐 Compressing WebUI Complete Standalone structure to .tar.gz..."
    tar -czf "$WEBUI_TARGET" .

    # Return to the initial working directory
    cd "$CWD"
    echo "✅ WebUI successfully compressed."
fi

# =====================================================================
# FINISHING
# =====================================================================
echo "--------------------------------------------------------"
echo "🏁 [SUCCESS] Full dynamic build and packing complete!"
echo "📂 All artifacts located in: $BUILD_DIR"
echo "--------------------------------------------------------"
ls -lh "$BUILD_DIR"