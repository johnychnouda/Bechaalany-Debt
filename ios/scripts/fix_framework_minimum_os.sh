#!/bin/bash
# Patches embedded pod frameworks so App Store validation (ITMS-90208) passes.
# Framework MinimumOSVersion must be >= the app's deployment target.
set -euo pipefail

MIN_OS="${MINIMUM_OS_VERSION:-15.0}"

fix_plist() {
  local plist="$1"
  [ -f "$plist" ] || return 0

  if /usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion ${MIN_OS}" "$plist" || true
  else
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string ${MIN_OS}" "$plist" || true
  fi

  if ! /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$plist" || true
  fi
}

patch_frameworks_dir() {
  local dir="$1"
  [ -d "$dir" ] || return 0

  for fw in "$dir"/*.framework; do
    [ -d "$fw" ] || continue
    fix_plist "${fw}/Info.plist"
    for nested in "${fw}"/Versions/*/Resources/Info.plist "${fw}"/Resources/Info.plist; do
      [ -f "$nested" ] && fix_plist "$nested"
    done
  done
}

# Xcode archive / local build: frameworks inside the app bundle.
patch_frameworks_dir "${TARGET_BUILD_DIR:-}/${WRAPPER_NAME:-}/Frameworks"

# Optional: pass PODS_ROOT when invoked from Podfile post_install.
if [ -n "${PODS_ROOT:-}" ] && [ -d "${PODS_ROOT}" ]; then
  while IFS= read -r plist; do
    fix_plist "$plist"
  done < <(find "${PODS_ROOT}" -path '*.framework/Info.plist' 2>/dev/null)
fi
