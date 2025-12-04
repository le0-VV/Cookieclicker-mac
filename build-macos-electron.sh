#!/usr/bin/env bash
set -euo pipefail

# Build a macOS Electron wrapper for Cookie Clicker.
# - Verifies Node/npm (installs via Homebrew if available).
# - Ensures Electron + packager deps are present.
# - Generates minimal Electron bootstrap files if missing.
# - Packages a signed-offline macOS app into dist/.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

APP_NAME="Cookie Clicker"
PACKAGE_JSON="${ROOT}/package.json"
ELECTRON_MAIN="${ROOT}/electron-main.js"
ICON_BASE="${ROOT}/icon"
ICON_PATH="${ICON_BASE}.icns"
OUT_DIR="${ROOT}/dist"

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script targets macOS only." >&2
  exit 1
fi

if ! require_cmd node; then
  if require_cmd brew; then
    echo "Node.js not found; installing via Homebrew..."
    brew install node
  else
    echo "Node.js is required. Install it (https://nodejs.org/) and re-run." >&2
    exit 1
  fi
fi

NODE_MAJOR="$(node -v | sed 's/^v//' | cut -d. -f1)"
if [[ "${NODE_MAJOR}" -lt 18 ]]; then
  echo "Node.js >= 18 required (found $(node -v)). Please upgrade." >&2
  exit 1
fi

if ! require_cmd npm; then
  echo "npm is required but was not found alongside Node." >&2
  exit 1
fi

ensure_package_json() {
  if [[ -f "${PACKAGE_JSON}" ]]; then
    return
  fi

  cat >"${PACKAGE_JSON}" <<'EOF'
{
  "name": "cookieclicker-electron",
  "productName": "Cookie Clicker",
  "version": "2.052.0",
  "description": "Electron wrapper for Cookie Clicker",
  "main": "electron-main.js",
  "scripts": {
    "start": "electron .",
    "build:mac": "electron-packager . \"Cookie Clicker\" --platform=darwin --arch=x64,arm64 --out=dist --overwrite --prune=true --asar --ignore=\"^dist$\""
  },
  "devDependencies": {
    "electron": "^35.7.5",
    "@electron/packager": "^19.0.1"
  }
}
EOF
}

ensure_main_js() {
  if [[ -f "${ELECTRON_MAIN}" ]]; then
    return
  fi

  cat >"${ELECTRON_MAIN}" <<'EOF'
const {app, BrowserWindow} = require('electron');
const path = require('path');

const createWindow = () => {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false
    }
  });
  win.setMenuBarVisibility(false);
  win.loadFile(path.join(__dirname, 'index.html'));
};

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
EOF
}

ensure_package_json
ensure_main_js

# Ensure required dev dependencies are present.
if ! node -e "const pkg=require('./package.json');process.exit(pkg.devDependencies && pkg.devDependencies.electron ? 0 : 1);" >/dev/null 2>&1; then
  npm install --save-dev electron@^35.7.5
fi
if ! node -e "const pkg=require('./package.json');process.exit(pkg.devDependencies && pkg.devDependencies['@electron/packager'] ? 0 : 1);" >/dev/null 2>&1; then
  npm install --save-dev @electron/packager@^19.0.1
fi

echo "Installing npm dependencies..."
npm install

ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64) BUILD_ARCH="x64" ;;
  arm64) BUILD_ARCH="arm64" ;;
  *) BUILD_ARCH="${ARCH_RAW}" ;;
esac

mkdir -p "${OUT_DIR}"

echo "Building ${APP_NAME} for macOS (${BUILD_ARCH})..."
if [[ ! -f "${ICON_PATH}" ]]; then
  echo "Warning: icon file ${ICON_PATH} not found; app will use default Electron icon." >&2
fi
PACKAGER_ARGS=(
  "${APP_NAME}"
  --platform=darwin
  --arch="${BUILD_ARCH}"
  --out="${OUT_DIR}"
  --overwrite
  --prune=true
  --asar
  --ignore="^dist$"
  --quiet
)
if [[ -n "${ICON_BASE}" ]]; then
  PACKAGER_ARGS+=(--icon="${ICON_BASE}")
fi
npx @electron/packager . "${PACKAGER_ARGS[@]}"

echo "Build complete. Output located in ${OUT_DIR}/${APP_NAME}-darwin-${BUILD_ARCH}"
