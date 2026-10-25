#!/usr/bin/env bash
# =====================================================================
# إصدارٌ كامل لـ«دعاية» من نسخة pubspec الواحدة: الويب ← iOS ← APK
# =====================================================================
#   ./scripts/release_all.sh                   # الويب يُنشر، iOS يُرسل للمراجعة، ثم APK
#   ./scripts/release_all.sh --upload-only     # iOS إلى TestFlight فقط، بلا مراجعة
#   ./scripts/release_all.sh --manual-release  # بعد موافقة Apple يبقى بانتظار زرّ «Release»
#   ./scripts/release_all.sh --skip-precheck   # يُمرَّر إلى release_ios.sh
#   ./scripts/release_all.sh --skip-web        # تخطَّ مرحلةً — للاستئناف بعد فشل
#   ./scripts/release_all.sh --skip-ios
#   ./scripts/release_all.sh --skip-apk
#
# على الماك وحده: iOS يحتاج Xcode. كل مرحلةٍ سكربتُها نفسه كما هو — release_web.sh ثم
# release_ios.sh — وهذا الملف يرتّبها، ويفحص قبل أن يُنشر شيءٌ ما يُفشلها في منتصفها: إعدادَ رفع
# الويب والوصولَ إلى الخادم، مفتاحَ App Store Connect وfastlane. أما فحوصات iOS نفسها (ملاحظات
# الإصدار، حالة النسخة لدى Apple) فتجري أول مرحلتها كما في سكربتها، والويب حينها منشورٌ فعلاً.
# فشلُ أي مرحلةٍ يوقف ما بعدها ويطبع أمر الاستئناف.
# =====================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${YELLOW}$*${NC}"; }
ok()   { echo -e "${GREEN}$*${NC}"; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

WEB=true; IOS=true; APK=true
IOS_ARGS=()
SKIPS=""   # ما تُخطّي أو نجح — يصير أمرَ الاستئناف إن فشلت مرحلة
for arg in "$@"; do
  case "$arg" in
    --skip-web) WEB=false; SKIPS+=" $arg" ;;
    --skip-ios) IOS=false; SKIPS+=" $arg" ;;
    --skip-apk) APK=false; SKIPS+=" $arg" ;;
    --upload-only|--manual-release|--skip-precheck) IOS_ARGS+=("$arg") ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) fail "خيارٌ غير معروف: $arg" ;;
  esac
done
$WEB || $IOS || $APK || fail "كل المراحل متخطّاة — لا شيء لفعله"

# bash 3.2 على الماك يرى المصفوفة الفارغة «unbound» تحت `set -u`، فتُمدّ هكذا.
ios_args() { echo ${IOS_ARGS[@]+"${IOS_ARGS[@]}"}; }

STEP=""
on_exit() {
  local code=$?
  [[ $code -ne 0 && -n "$STEP" ]] || return 0
  echo -e "${RED}✗ توقّف الإصدار في مرحلة «$STEP».${NC}" >&2
  echo -e "${RED}  للاستئناف منها: ./scripts/release_all.sh${SKIPS} $(ios_args)${NC}" >&2
}
trap on_exit EXIT

FULL_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=${FULL_VERSION%+*}
VERSION_CODE=${FULL_VERSION#*+}

# ── فحوصات تمهيدية: لا يُنشر الويب ثم يُكتشف أن iOS لا يُبنى على هذا الجهاز ──
info "▶ فحوصات تمهيدية..."
command -v flutter >/dev/null || fail "flutter غير موجود في PATH"
PROD_URL=$(grep -E '^BASE_URL=' .env 2>/dev/null | cut -d= -f2- || true)
[[ "$PROD_URL" == https://* ]] || fail "BASE_URL في .env ليس https: «$PROD_URL»"

if $WEB; then
  # release_web.sh بلا هذا الملف يبني ثم يخرج بنجاحٍ دون رفع — هنا يجب أن يكون فشلاً.
  # shellcheck source=/dev/null
  [[ -f scripts/web_deploy.local.sh ]] && source scripts/web_deploy.local.sh
  [[ -n "${WEB_HOST:-}" && -n "${WEB_ROOT:-}" ]] \
    || fail "لا WEB_HOST/WEB_ROOT في scripts/web_deploy.local.sh — الويب كان سيُبنى ولا يُرفع"
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$WEB_HOST" "test -d '$(dirname "$WEB_ROOT")'" \
    || fail "لا وصول بـssh إلى $WEB_HOST:$(dirname "$WEB_ROOT")"
fi

if $IOS; then
  [[ "$(uname)" == Darwin ]] || fail "iOS يُبنى على الماك وحده — أو أضف --skip-ios"
  command -v fastlane >/dev/null || fail "fastlane غير مثبّت — brew install fastlane"
  # shellcheck source=/dev/null
  ( source scripts/asc_env.sh && require_ios_env ) || exit 1
fi
ok "✓ النسخة ${VERSION_NAME} (${VERSION_CODE}) · الخادم ${PROD_URL} · ويب:${WEB} iOS:${IOS} APK:${APK}"

# ── ١/٣ الويب ──
if $WEB; then
  STEP="الويب"
  info "━━━━ ١/٣ الويب ━━━━"
  ./scripts/release_web.sh
  SKIPS+=" --skip-web"
fi

# ── ٢/٣ iOS ──
if $IOS; then
  STEP="iOS"
  info "━━━━ ٢/٣ iOS ━━━━"
  ./scripts/release_ios.sh ${IOS_ARGS[@]+"${IOS_ARGS[@]}"}
  SKIPS+=" --skip-ios"
fi

# ── ٣/٣ APK ──
if $APK; then
  STEP="APK"
  info "━━━━ ٣/٣ APK ━━━━"
  # اثنان مستقلّان: `--flavor prod` نكهةُ Gradle، تختار الحزمة (ly.dayaa.app لا .dev) واسمها
  # وأيقونتها؛ و`FLAVOR=prod` يختار ملفّ البيئة، أي الخادم (AppConfig). كلاهما prod هنا.
  #
  # التوقيع بمفتاح debug (android/app/build.gradle.kts)، ومفتاح debug لكل جهازٍ مختلف:
  # تحديثٌ يُبنى على جهازٍ آخر لا يُنصَّب فوق نسخةٍ قائمة.
  flutter build apk --release --flavor prod --dart-define=FLAVOR=prod

  OUT=build/app/outputs/flutter-apk/app-prod-release.apk
  META=build/app/outputs/apk/prod/release/output-metadata.json
  [[ -f "$OUT" && -f "$META" ]] || fail "لا APK في $OUT"

  # الفحص من داخل الناتج كما في release_ios.sh: الحزمة والنسخة من Gradle، والخادم من ملف البيئة المحزوم.
  read -r BUILT_ID BUILT_VERSION BUILT_NUMBER < <(python3 -c '
import json, sys
m = json.load(open(sys.argv[1])); e = m["elements"][0]
print(m["applicationId"], e["versionName"], e["versionCode"])' "$META")
  BUILT_URL=$(unzip -p "$OUT" assets/flutter_assets/.env | grep -E '^BASE_URL=' | cut -d= -f2- || true)
  [[ "$BUILT_ID" == "ly.dayaa.app" ]] || fail "حزمة الـ APK ${BUILT_ID} لا ly.dayaa.app"
  [[ "$BUILT_VERSION" == "$VERSION_NAME" && "$BUILT_NUMBER" == "$VERSION_CODE" ]] \
    || fail "عدم تطابق! المطلوب ${VERSION_NAME} (${VERSION_CODE}) بينما الـ APK: ${BUILT_VERSION} (${BUILT_NUMBER})"
  [[ "$BUILT_URL" == "$PROD_URL" ]] || fail "الـ APK يكلّم ${BUILT_URL:-?} لا ${PROD_URL}"

  APK_FILE="build/dayaa-${VERSION_NAME}-${VERSION_CODE}.apk"
  cp "$OUT" "$APK_FILE"
  ok "✓ الـ APK: $(pwd)/$APK_FILE — ${BUILT_ID} ${BUILT_VERSION} (${BUILT_NUMBER}) → ${BUILT_URL}"
fi

STEP=""
ok "🎉 اكتمل إصدار ${VERSION_NAME} (${VERSION_CODE})"
