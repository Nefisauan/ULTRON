#!/bin/bash
set -euo pipefail
ultron_root="$(cd "$(dirname "$0")/.." && pwd)"
ultron_build_root="${ULTRON_BUILD_DIR:-$ultron_root/.build}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ultron_build_root/ModuleCache}"
ultron_options=(--package-path "$ultron_root" --scratch-path "$ultron_build_root" --cache-path "$ultron_build_root/cache")
# Opt-in only for nested/restricted development environments; this does not change app permissions.
if [[ "${ULTRON_DISABLE_BUILD_SANDBOX:-0}" == "1" ]]; then
    ultron_options+=(--disable-sandbox)
fi
swift build "${ultron_options[@]}" --product UltronMac
ultron_binary_dir="$(swift build "${ultron_options[@]}" --show-bin-path)"
ultron_app="$ultron_build_root/app/ULTRON.app"
mkdir -p "$ultron_app/Contents/MacOS"
cp "$ultron_binary_dir/UltronMac" "$ultron_app/Contents/MacOS/UltronMac"
cp "$ultron_root/Apps/macOS/Info.plist" "$ultron_app/Contents/Info.plist"
codesign --force --sign - "$ultron_app"
printf 'Built %s\n' "$ultron_app"
