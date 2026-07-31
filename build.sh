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

echo "📦 [1/6] Processing Backend..."
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

echo "📦 [2/6] Processing Worker..."
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

echo "📦 [3/6] Processing Updater..."
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

echo "📦 [4/6] Processing WebUI..."
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

echo "📦 [5/6] Processing Launcher..."
cd "$CWD"
cd "$TARGET_DIR/launcher"
LAUNCHER_VER=$(jq -r '.launcher.version' "$VERSION_JSON")
LAUNCHER_OUTPUT_DIR="$(pwd)/output/windows"
cd "$CWD"

LAUNCHER_DIRECTML_TARGET="$BUILD_DIR/launcher_${LAUNCHER_VER}_directml_windows_amd64.zip"
LAUNCHER_CUDA_TARGET="$BUILD_DIR/launcher_${LAUNCHER_VER}_cuda_windows_amd64.zip"

find_versioned_zip() {
    local variant="$1"
    [ -d "$LAUNCHER_OUTPUT_DIR" ] || return 0
    find "$LAUNCHER_OUTPUT_DIR" -maxdepth 1 -iname "launcher_${LAUNCHER_VER}_${variant}_windows_amd64.zip" 2>/dev/null | head -n 1
}

# Bersihin sisa zip versi lain di output dir (yang beda dari versi manifest saat ini)
if [ -d "$LAUNCHER_OUTPUT_DIR" ]; then
    find "$LAUNCHER_OUTPUT_DIR" -maxdepth 1 -iname "launcher_*_windows_amd64.zip" ! -iname "launcher_${LAUNCHER_VER}_*" -exec rm -f {} \;
fi

# ── DirectML ─────────────────────────────────────────────
if [ -f "$LAUNCHER_DIRECTML_TARGET" ]; then
    echo "⏭️  Duplicate version found (launcher_${LAUNCHER_VER}_directml), skip build."
else
    EXISTING_DIRECTML_ZIP=$(find_versioned_zip "directml")
    if [ -n "$EXISTING_DIRECTML_ZIP" ]; then
        echo "ℹ️  Found existing DirectML zip matching manifest version v${LAUNCHER_VER}, skip build & reuse."
        mv "$EXISTING_DIRECTML_ZIP" "$LAUNCHER_DIRECTML_TARGET"
    else
        cd "$TARGET_DIR/launcher"
        echo "🛠️  Building Launcher (DirectML)..."
        sh build.sh --directml

        DIRECTML_ZIP=$(find_versioned_zip "directml")
        if [ -z "$DIRECTML_ZIP" ]; then
            echo "❌ Error: DirectML zip v${LAUNCHER_VER} not found in $LAUNCHER_OUTPUT_DIR after build!"
            exit 1
        fi
        mv "$DIRECTML_ZIP" "$LAUNCHER_DIRECTML_TARGET"
        cd "$CWD"
    fi
    echo "✅ Launcher (DirectML) ready in build dir."
fi

# ── CUDA ─────────────────────────────────────────────────
if [ -f "$LAUNCHER_CUDA_TARGET" ]; then
    echo "⏭️  Duplicate version found (launcher_${LAUNCHER_VER}_cuda), skip build."
else
    EXISTING_CUDA_ZIP=$(find_versioned_zip "cuda")
    if [ -n "$EXISTING_CUDA_ZIP" ]; then
        echo "ℹ️  Found existing CUDA zip matching manifest version v${LAUNCHER_VER}, skip build & reuse."
        mv "$EXISTING_CUDA_ZIP" "$LAUNCHER_CUDA_TARGET"
    else
        cd "$TARGET_DIR/launcher"
        echo "🛠️  Building Launcher (CUDA)..."
        sh build.sh --cuda

        CUDA_ZIP=$(find_versioned_zip "cuda")
        if [ -z "$CUDA_ZIP" ]; then
            echo "❌ Error: CUDA zip v${LAUNCHER_VER} not found in $LAUNCHER_OUTPUT_DIR after build!"
            exit 1
        fi
        mv "$CUDA_ZIP" "$LAUNCHER_CUDA_TARGET"
        cd "$CWD"
    fi
    echo "✅ Launcher (CUDA) ready in build dir."
fi

echo "📦 [6/6] Processing Docker Deployment Bundle..."
cd "$CWD"

DOCKER_TARGET="$BUILD_DIR/facesync_docker_${BACKEND_VER}_amd64.tar.gz"

if check_artifact "facesync_docker_*_amd64.tar.gz" "$DOCKER_TARGET"; then
    :
else
    DOCKER_STAGING=$(mktemp -d)

    echo "📁 Copying required docker deployment files..."
    cp "$CWD/docker-compose.yml"   "$DOCKER_STAGING/"
    cp "$CWD/Dockerfile"           "$DOCKER_STAGING/"
    cp "$CWD/entrypoint.sh"        "$DOCKER_STAGING/"
    cp "$CWD/supervisord.conf"     "$DOCKER_STAGING/"
    cp "$CWD/manifest.json"        "$DOCKER_STAGING/"

    echo "🔧 Converting .env.example -> .env..."
    cp "$CWD/.env.example"         "$DOCKER_STAGING/.env"

    echo "🤐 Compressing Docker deployment bundle to .tar.gz..."
    tar -czf "$DOCKER_TARGET" -C "$DOCKER_STAGING" .

    rm -rf "$DOCKER_STAGING"
    echo "✅ Docker deployment bundle successfully compressed."
fi

# =====================================================================
# FINISHING
# =====================================================================
echo "--------------------------------------------------------"
echo "🏁 [SUCCESS] Full dynamic build and packing complete!"
echo "📂 All artifacts located in: $BUILD_DIR"
echo "--------------------------------------------------------"
ls -lh "$BUILD_DIR"