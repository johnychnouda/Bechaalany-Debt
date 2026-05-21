#!/usr/bin/env bash
# Build Flutter web and copy static legal/support pages for Firebase Hosting.
set -euo pipefail

cd "$(dirname "$0")"

flutter build web --release

# Disable service worker (patch only the final loader call — not the minified flutter.js)
rm -f build/web/flutter_service_worker.js
if [ -f build/web/flutter_bootstrap.js ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path("build/web/flutter_bootstrap.js")
text = p.read_text()
marker = "_flutter.loader.load({"
idx = text.rfind(marker)
if idx != -1:
    end = text.find("});", idx)
    if end != -1:
        text = text[:idx] + "_flutter.loader.load({});" + text[end + 3 :]
        p.write_text(text)
PY
  node -e "new Function(require('fs').readFileSync('build/web/flutter_bootstrap.js','utf8')); console.log('flutter_bootstrap.js: syntax OK')" \
    || { echo "ERROR: flutter_bootstrap.js is invalid"; exit 1; }
fi

# Copy legal/support pages only — never overwrite Flutter's index.html
if [ -d public ]; then
  if [ -f public/support.html ]; then
    cp -f public/support.html build/web/
  fi
  if [ -f public/legal/privacy-policy.html ]; then
    mkdir -p build/web/legal
    cp -f public/legal/privacy-policy.html build/web/legal/
  fi
fi
# Remove old root privacy page so cached redirects hit Firebase rules instead
rm -f build/web/privacy-policy.html

echo "Web build ready in build/web"
echo ""
echo "Deploy to Firebase (required to see changes on web.app):"
echo "  firebase deploy --only hosting --project bechaalany-debt-app-e1bb0"
echo ""
echo "Then hard-refresh the site (Cmd+Shift+R) or use a private window."
