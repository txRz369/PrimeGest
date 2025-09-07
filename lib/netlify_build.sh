#!/usr/bin/env bash
set -euo pipefail

# 1) Instalar Flutter (stable) no ambiente do Netlify
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PWD/flutter/bin:$PATH"

# 2) Info e dependências
flutter --version
flutter config --no-analytics
flutter pub get

# 3) Build de produção com as envs do Netlify
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

# 4) Garante que o _redirects vai com o build (normalmente já vai)
cp -f web/_redirects build/web/_redirects || true
