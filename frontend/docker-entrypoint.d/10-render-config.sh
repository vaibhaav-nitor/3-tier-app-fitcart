#!/bin/sh
# Runs automatically via the base nginx image's docker-entrypoint.sh, before
# nginx starts. Only takes effect where HERO_HIGHLIGHT_TEXT arrives as a
# container environment variable — Azure App Service app settings, notably.
# On AKS the value instead arrives as a ConfigMap volume mounted directly over
# config.js (see helm/frontend/templates/configmap.yaml); no env var is set
# there, so this script leaves that mounted file untouched.
set -eu

if [ -n "${HERO_HIGHLIGHT_TEXT:-}" ]; then
  escaped=$(printf '%s' "$HERO_HIGHLIGHT_TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')
  cat > /usr/share/nginx/html/config.js <<EOF
window.__FITCART_CONFIG__ = {
  HERO_HIGHLIGHT_TEXT: "${escaped}"
};
EOF
fi
