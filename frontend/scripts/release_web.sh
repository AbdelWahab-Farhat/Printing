#!/usr/bin/env bash
# =====================================================================
# نسخة الويب لتطبيق الموظفين: بناءُ الإنتاج، فحصُه، ثم رفعُه إلى الخادم إن عُرف
# =====================================================================
#   ./scripts/release_web.sh               # بناء + فحص، ثم رفع إن وُجد web_deploy.local.sh
#   ./scripts/release_web.sh --build-only  # بناء + فحص فقط؛ الناتج في build/web
#   ./scripts/release_web.sh --skip-build  # رفعُ آخر بناءٍ كما هو
#
# **أين يُرفع ليس هنا.** المستودع عامّ، فالمضيف والمجلّد في `scripts/web_deploy.local.sh`،
# ملفٍّ غير متتبَّع بجانب هذا:
#
#     WEB_HOST=<اسم المضيف كما في ~/.ssh/config>
#     WEB_ROOT=/var/www/<مجلّد النسخة>
#
# إعداد nginx والنطاق وCORS على الخادم: Docs/web/STAFF-WEB.md.
# =====================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${YELLOW}$*${NC}"; }
ok()   { echo -e "${GREEN}$*${NC}"; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

BUILD=true
UPLOAD=true
for arg in "$@"; do
  case "$arg" in
    --build-only) UPLOAD=false ;;
    --skip-build) BUILD=false ;;
    *) fail "خيارٌ غير معروف: $arg" ;;
  esac
done

OUT=build/web

if $BUILD; then
  info "▸ بناء الويب (prod)…"
  # بلا `--flavor`: النكهات لأندرويد وiOS. الخادمُ يختاره FLAVOR وحده، وprod هو الافتراضي.
  #
  # `--no-web-resources-cdn`: محرّكُ الرسم (canvaskit.wasm) يُنشر مع الصفحة لا من خوادم Google.
  # جُرّب من الماك: جلبُه من gstatic أخذ ٤ ثوانٍ والتطبيقُ لا يبدأ قبله.
  flutter build web --release --dart-define=FLAVOR=prod --no-web-resources-cdn --no-wasm-dry-run
fi

[[ -f "$OUT/index.html" && -f "$OUT/main.dart.js" ]] || fail "لا بناء في $OUT"

# الفحص من داخل الناتج لا من الشجرة: ملفُّ البيئة المحزوم هو ما سيقرؤه المتصفّح فعلاً،
# ونسخةٌ تُرفع وهي تشير إلى ماك المطوّر لا يكتشفها أحدٌ إلا موظفٌ يرى «تعذّر الاتصال».
base_url="$(grep -E '^BASE_URL=' "$OUT/assets/.env" | cut -d= -f2- || true)"
[[ "$base_url" == https://* ]] || fail "BASE_URL في البناء ليس https: «$base_url»"
grep -q 'removeSplashFromWeb' "$OUT/index.html" || fail "index.html بلا removeSplashFromWeb — main.dart يناديها"
grep -q '"useLocalCanvasKit":true' "$OUT/flutter_bootstrap.js" \
  || fail "المحرّك يُجلب من gstatic — البناء بلا --no-web-resources-cdn"
ok "✓ البناء: $OUT  ·  الخادم: $base_url  ·  النسخة: $(grep -E '^version:' pubspec.yaml | cut -d' ' -f2)"

$UPLOAD || exit 0

# shellcheck source=/dev/null
[[ -f scripts/web_deploy.local.sh ]] && source scripts/web_deploy.local.sh
if [[ -z "${WEB_HOST:-}" || -z "${WEB_ROOT:-}" ]]; then
  info "لا scripts/web_deploy.local.sh — لم يُرفع شيء. الناتج جاهزٌ في $OUT."
  exit 0
fi

info "▸ رفعٌ إلى $WEB_HOST:$WEB_ROOT…"
# `--delete`: ملفُّ main.dart.js القديم لا يبقى بجانب الجديد. والمجلّد يُملأ أولاً ثم يُبدَّل،
# فلا يرى موظفٌ يفتح الصفحة أثناء الرفع نصفَ نسخةٍ قديمة ونصفَ جديدة.
rsync -az --delete "$OUT/" "$WEB_HOST:$WEB_ROOT.next/"
ssh "$WEB_HOST" "rm -rf '$WEB_ROOT.prev' \
  && { [ -d '$WEB_ROOT' ] && mv '$WEB_ROOT' '$WEB_ROOT.prev' || true; } \
  && mv '$WEB_ROOT.next' '$WEB_ROOT'"
ok "✓ رُفعت. النسخة السابقة في $WEB_ROOT.prev للرجوع إليها."
