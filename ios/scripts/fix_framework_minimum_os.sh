#!/bin/bash
# ITMS-90208: Firebase/gRPC binary frameworks must declare MinimumOSVersion >= app target.
set +e

MIN_OS="${MINIMUM_OS_VERSION:-15.0}"

fix_plist() {
  local plist="$1"
  [ -f "$plist" ] || return 0

  if plutil -replace MinimumOSVersion -string "$MIN_OS" "$plist" 2>/dev/null; then
    return 0
  fi
  plutil -insert MinimumOSVersion -string "$MIN_OS" "$plist" 2>/dev/null

  if ! plutil -extract CFBundleShortVersionString raw "$plist" 2>/dev/null; then
    plutil -insert CFBundleShortVersionString -string "1.0" "$plist" 2>/dev/null
  fi
}

patch_frameworks_dir() {
  local dir="$1"
  [ -n "$dir" ] || return 0
  [ -d "$dir" ] || return 0

  shopt -s nullglob 2>/dev/null || true
  for fw in "$dir"/*.framework; do
    [ -d "$fw" ] || continue
    fix_plist "${fw}/Info.plist"
    for nested in "${fw}"/Versions/*/Resources/Info.plist "${fw}"/Resources/Info.plist; do
      [ -f "$nested" ] && fix_plist "$nested"
    done
  done
}

# Patch every known location of the embedded app bundle (archive + local + CI).
for frameworks_dir in \
  "${CODESIGNING_FOLDER_PATH}/Frameworks" \
  "${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks" \
  "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Frameworks" \
  "${ARCHIVE_PRODUCTS_PATH}/Applications/${WRAPPER_NAME}/Frameworks" \
  "${INSTALL_ROOT}/Applications/${WRAPPER_NAME}/Frameworks"; do
  patch_frameworks_dir "$frameworks_dir"
done

exit 0
