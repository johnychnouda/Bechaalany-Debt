#!/bin/bash
# ITMS-90208: Apple validates Mach-O LC_BUILD_VERSION *and* framework Info.plist.
# Firebase/gRPC binaries ship with wrong minos (e.g. 10.0/100.0); App.framework ships 13.0.
set +e

# vtool invalidates code signatures — only patch Release archives (App Store), not Debug/simulator.
if [ "${CONFIGURATION:-Debug}" != "Release" ]; then
  exit 0
fi

MIN_OS="${MINIMUM_OS_VERSION:-15.0}"
# Match the SDK used to build (Xcode 26.x); required for vtool -set-build-version.
SDK_OS="${SDK_VERSION_OS:-26.0}"

fix_plist() {
  local plist="$1"
  [ -f "$plist" ] || return 0

  plutil -replace MinimumOSVersion -string "$MIN_OS" "$plist" 2>/dev/null \
    || plutil -insert MinimumOSVersion -string "$MIN_OS" "$plist" 2>/dev/null

  if ! plutil -extract CFBundleShortVersionString raw "$plist" 2>/dev/null; then
    plutil -insert CFBundleShortVersionString -string "1.0" "$plist" 2>/dev/null
  fi
}

patch_framework_binary() {
  local binary="$1"
  [ -f "$binary" ] || return 0

  local tmp="${binary}.vtool.$$"
  if xcrun vtool -set-build-version ios "$MIN_OS" "$SDK_OS" -output "$tmp" "$binary" 2>/dev/null; then
    mv "$tmp" "$binary"
    chmod +x "$binary" 2>/dev/null
  else
    rm -f "$tmp"
  fi
}

patch_frameworks_dir() {
  local dir="$1"
  [ -n "$dir" ] || return 0
  [ -d "$dir" ] || return 0

  shopt -s nullglob 2>/dev/null || true
  for fw in "$dir"/*.framework; do
    [ -d "$fw" ] || continue
    local name
    name="$(basename "$fw" .framework)"
    fix_plist "${fw}/Info.plist"
    for nested in "${fw}"/Versions/*/Resources/Info.plist "${fw}"/Resources/Info.plist; do
      [ -f "$nested" ] && fix_plist "$nested"
    done
    patch_framework_binary "${fw}/${name}"
  done
}

for frameworks_dir in \
  "${CODESIGNING_FOLDER_PATH}/Frameworks" \
  "${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks" \
  "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Frameworks" \
  "${ARCHIVE_PRODUCTS_PATH}/Applications/${WRAPPER_NAME}/Frameworks" \
  "${INSTALL_ROOT}/Applications/${WRAPPER_NAME}/Frameworks"; do
  patch_frameworks_dir "$frameworks_dir"
done

exit 0
