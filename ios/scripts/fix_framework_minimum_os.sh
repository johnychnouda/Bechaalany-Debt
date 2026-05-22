#!/bin/bash
# Patches embedded frameworks so App Store validation (ITMS-90208) passes.
# Never fail the Xcode build — worst case the upload is rejected again.
set +e

MIN_OS="${MINIMUM_OS_VERSION:-15.0}"

fix_plist() {
  local plist="$1"
  [ -f "$plist" ] || return 0

  if /usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion ${MIN_OS}" "$plist" >/dev/null 2>&1
  else
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string ${MIN_OS}" "$plist" >/dev/null 2>&1
  fi

  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$plist" >/dev/null 2>&1
  fi
}

patch_frameworks_dir() {
  local dir="$1"
  [ -n "$dir" ] || return 0
  [ -d "$dir" ] || return 0
  # Only patch frameworks inside the app build products (never /Frameworks).
  case "$dir" in
    *"${TARGET_BUILD_DIR}"*"/Frameworks") ;;
    *) return 0 ;;
  esac

  shopt -s nullglob 2>/dev/null || true
  for fw in "$dir"/*.framework; do
    [ -d "$fw" ] || continue
    fix_plist "${fw}/Info.plist"
    for nested in "${fw}"/Versions/*/Resources/Info.plist "${fw}"/Resources/Info.plist; do
      [ -f "$nested" ] && fix_plist "$nested"
    done
  done
}

if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ]; then
  patch_frameworks_dir "${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks"
fi

exit 0
