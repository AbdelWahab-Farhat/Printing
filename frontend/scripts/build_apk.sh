#!/usr/bin/env bash
# =====================================================================
# APK الإنتاج لتطبيق الموظفين: بناءُ نكهة prod، فحصُه من داخله، ثم نسخُه إلى سطح المكتب
# =====================================================================
#   ./scripts/build_apk.sh                 # بناء + فحص + نسخ إلى ~/Desktop
#   ./scripts/build_apk.sh --out <مجلّد>   # مجلّدٌ آخر للنسخة
#
# مقابلُ build_user_release.sh في بريمولا. التطبيقُ يُنصَّب يدوياً بتوقيع debug، لا من Google Play،
# فلا رفع هنا: الناتج `Dayaa-Staff-<النسخة>-prod.apk` كما سُمّيت النسخ السابقة.
# =====================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${YELLOW}$*${NC}"; }
ok()   { echo -e "${GREEN}$*${NC}"; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

OUT_DIR="$HOME/Desktop"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)     OUT_DIR="${2:-}"; [[ -n "$OUT_DIR" ]] || fail "--out يحتاج مجلّداً"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) fail "وسيط غير معروف: $1" ;;
  esac
done

FULL_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=${FULL_VERSION%+*}
VERSION_CODE=${FULL_VERSION#*+}
APP_ID="ly.dayaa.app"

# ── فحوصات قبل البناء ──
command -v flutter >/dev/null || fail "flutter غير موجود في PATH"
# الفحصُ في آخر البناء يحتاج aapt2؛ غيابُه يُكتشف الآن لا بعد بناءٍ كامل.
AAPT2=$(ls "$HOME"/Library/Android/sdk/build-tools/*/aapt2 2>/dev/null | tail -1 || true)
[[ -n "$AAPT2" && -x "$AAPT2" ]] || fail "aapt2 غير موجود في Android SDK build-tools — ثبّته من SDK Manager"
PROD_URL=$(grep -E '^BASE_URL=' .env | cut -d= -f2- || true)
[[ -n "$PROD_URL" ]] || fail "BASE_URL غير موجود في .env"
[[ -d "$OUT_DIR" ]] || fail "مجلّد النسخة غير موجود: $OUT_DIR"

# ── البناء ──
info "▶ بناء APK (نكهة prod) — ${VERSION_NAME} (${VERSION_CODE})..."
# اثنان مستقلّان: `--flavor prod` نكهةُ Gradle، تختار الحزمة (ly.dayaa.app لا .dev) واسمها
# وأيقونتها؛ و`FLAVOR=prod` يختار ملفّ البيئة، أي الخادم (AppConfig). كلاهما prod هنا.
#
# التوقيع بمفتاح debug (android/app/build.gradle.kts)، ومفتاحُ debug لكل جهازٍ مختلف:
# تحديثٌ يُبنى على جهازٍ آخر لا يُنصَّب فوق نسخةٍ قائمة.
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod

APK="build/app/outputs/flutter-apk/app-prod-release.apk"
[[ -f "$APK" ]] || fail "لم يُعثر على $APK"

# ── التحقق من داخل الـ APK، لا من الشجرة ──
BADGING=$("$AAPT2" dump badging "$APK" | head -1)
BUILT_ID=$(sed -E "s/.*name='([^']*)'.*/\1/" <<<"$BADGING")
BUILT_CODE=$(sed -E "s/.*versionCode='([^']*)'.*/\1/" <<<"$BADGING")
BUILT_NAME=$(sed -E "s/.*versionName='([^']*)'.*/\1/" <<<"$BADGING")
BUILT_URL=$(unzip -p "$APK" 'assets/flutter_assets/.env' | grep -E '^BASE_URL=' | cut -d= -f2- || true)

[[ "$BUILT_ID" == "$APP_ID" ]] || fail "معرّف الحزمة $BUILT_ID لا يطابق $APP_ID"
[[ "$BUILT_NAME" == "$VERSION_NAME" && "$BUILT_CODE" == "$VERSION_CODE" ]] \
  || fail "عدم تطابق! المطلوب ${VERSION_NAME} (${VERSION_CODE}) بينما الـ APK: ${BUILT_NAME} (${BUILT_CODE})"
[[ "$BUILT_URL" == "$PROD_URL" ]] || fail "الـ APK يكلّم ${BUILT_URL:-?} لا ${PROD_URL}"

DEST="$OUT_DIR/Dayaa-Staff-${VERSION_NAME}-prod.apk"
cp "$APK" "$DEST"
ok "✓ الـ APK: $DEST — ${BUILT_ID} ${BUILT_NAME} (${BUILT_CODE}) → ${BUILT_URL}"
