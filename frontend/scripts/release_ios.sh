#!/usr/bin/env bash
# =====================================================================
# إصدار iOS لـ«دعاية»: بناء IPA الإنتاج (نكهة prod) ثم رفعه عبر fastlane
# =====================================================================
# منقولٌ عن primula_client/scripts/release_ios_submit.sh، بلا Shorebird (هذا المشروع لا يستعمله)،
# ومعه فحص الـ IPA من release_ios_test.sh: الحزمة والنسخة والخادم من داخل الملف لا من الشجرة.
#
#   ./scripts/release_ios.sh                    # بناء ثم إرسال للمراجعة
#   ./scripts/release_ios.sh --upload-only      # بناء ثم رفع إلى TestFlight فقط، بلا مراجعة
#   ./scripts/release_ios.sh --skip-build       # استخدم آخر IPA مبني
#   ./scripts/release_ios.sh --ipa path/to/app.ipa
#   ./scripts/release_ios.sh --manual-release   # بعد الموافقة يبقى بانتظار زرّ «Release»
#   ./scripts/release_ios.sh --skip-precheck
#   ./scripts/release_ios.sh --cancel-pending [--force-cancel] [--yes]
#   ./scripts/release_ios.sh --status           # حالة النسخ في App Store Connect، بلا بناء
# =====================================================================
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/asc_env.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${YELLOW}$*${NC}"; }
ok()   { echo -e "${GREEN}$*${NC}"; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

FLAVOR="$RELEASE_FLAVOR"
SKIP_BUILD=false
UPLOAD_ONLY=false
IPA_OVERRIDE=""
CANCEL_PENDING=false
FORCE_CANCEL=false
ASSUME_YES=false
STATUS_ONLY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)     SKIP_BUILD=true; shift ;;
    --ipa)            IPA_OVERRIDE="${2:-}"; [[ -n "$IPA_OVERRIDE" ]] || fail "--ipa يحتاج مساراً"; SKIP_BUILD=true; shift 2 ;;
    --upload-only)    UPLOAD_ONLY=true; shift ;;
    --manual-release) export ASC_AUTOMATIC_RELEASE=false; shift ;;
    --skip-precheck)  export ASC_SKIP_PRECHECK=true; shift ;;
    --cancel-pending) CANCEL_PENDING=true; shift ;;
    --force-cancel)   FORCE_CANCEL=true; shift ;;
    --yes|-y)         ASSUME_YES=true; shift ;;
    --status)         STATUS_ONLY=true; shift ;;
    -h|--help)        sed -n '2,17p' "$0"; exit 0 ;;
    *) fail "وسيط غير معروف: $1" ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# يقرأ مفتاحاً من Info.plist داخل الـ IPA
ipa_plist() {
  local tmp; tmp=$(mktemp)
  unzip -p "$1" 'Payload/*.app/Info.plist' > "$tmp"
  plutil -extract "$2" raw -o - "$tmp"
  rm -f "$tmp"
}

# ── فحوصات ما قبل البناء (بدل الفشل بعد عشرين دقيقة بناء) ──
info "▶ فحوصات تمهيدية..."
command -v flutter  >/dev/null || fail "flutter غير موجود في PATH"
command -v fastlane >/dev/null || fail "fastlane غير مثبّت — brew install fastlane"
require_ios_env || exit 1

if [[ "$STATUS_ONLY" == true ]]; then
  fastlane ios status
  exit 0
fi

FULL_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=${FULL_VERSION%+*}
VERSION_CODE=${FULL_VERSION#*+}

# ملاحظات الإصدار (ما الجديد) — إلزامية لأي تحديث، وApple ترفض بدونها.
# ar-SA لغة المتجر المفترضة؛ `--status` يطبع اللغات المفعّلة فعلاً — أضف مجلد كل لغة
# تحت fastlane/metadata وإلا فشل deliver بعد رفع الـ IPA كاملاً.
NOTES="fastlane/metadata/ar-SA/release_notes.txt"
if [[ "$UPLOAD_ONLY" == false ]]; then
  [[ -f "$NOTES" ]] || fail "ملف ملاحظات الإصدار مفقود: $NOTES"
  grep -q '^###' "$NOTES" && fail "لم تُكتب ملاحظات الإصدار بعد — عدّل $NOTES"
  [[ -n "$(tr -d '[:space:]' < "$NOTES")" ]] || fail "ملاحظات الإصدار فارغة: $NOTES"
  ok "✓ ملاحظات الإصدار جاهزة ($NOTES)"
fi
ok "✓ النسخة: ${VERSION_NAME} (build ${VERSION_CODE}) — نكهة ${FLAVOR}"

PROD_URL=$(grep -E '^BASE_URL=' .env | cut -d= -f2- || true)
[[ -n "$PROD_URL" ]] || fail "BASE_URL غير موجود في .env"

if [[ "$UPLOAD_ONLY" == false ]]; then
  if [[ "$CANCEL_PENDING" == true ]]; then
    # نأخذ الموافقة الآن (والمستخدم أمام الشاشة) وننفّذ السحب بعد نجاح البناء،
    # حتى لا نخسر المكان في الطابور مقابل بناء فاشل.
    info "▶ الحالة الحالية في App Store Connect:"
    fastlane ios status
    echo ""
    echo -e "${RED}⚠ ستُسحب النسخة الحالية من المراجعة بعد اكتمال البناء —${NC}"
    echo -e "${RED}  تفقد مكانها في طابور Apple ولا يمكن التراجع عن ذلك.${NC}"
    if [[ "$ASSUME_YES" == false ]]; then
      [[ -t 0 ]] || fail "--cancel-pending يحتاج تأكيداً تفاعلياً — أضف --yes"
      read -r -p "اكتب yes للمتابعة: " CONFIRM
      [[ "$CONFIRM" == "yes" ]] || fail "أُلغيت العملية"
    fi
  else
    # Apple تسمح بنسخة واحدة "قيد الطريق" فقط؛ فحصها الآن يوفّر البناء كله
    info "▶ فحص حالة النسخة في App Store Connect..."
    fastlane ios check_version version:"$VERSION_NAME"
  fi
else
  info "▶ فحص مسار النسخة في TestFlight..."
  fastlane ios check_test_version version:"$VERSION_NAME"
fi

# ── البناء ──
if [[ "$SKIP_BUILD" == false ]]; then
  flutter pub get
  rm -rf build/ios/ipa

  info "▶ بناء IPA (نكهة ${FLAVOR})..."
  # أول `build ipa` بعد `pub get` قد يفشل بـ«firebase-core requires minimum platform version 15.0»:
  # Package.swift المولَّد يبدأ بـ iOS 13 ولا يُرفع إلى 15 إلا إن وُجد قبل البناء. الإعادة تنجح.
  LOG=$(mktemp)
  if ! flutter build ipa --release --flavor "$FLAVOR" 2>&1 | tee "$LOG"; then
    grep -q 'requires minimum platform version' "$LOG" || fail "فشل البناء"
    info "▶ إعادة البناء مرةً (فخّ iOS 13/15 في Package.swift)..."
    flutter build ipa --release --flavor "$FLAVOR" || fail "فشل البناء"
  fi
  rm -f "$LOG"
else
  info "▶ تخطّي البناء (--skip-build)"
fi

# ── تحديد الـ IPA ──
if [[ -n "$IPA_OVERRIDE" ]]; then
  IPA_PATH="$IPA_OVERRIDE"
else
  IPA_PATH=$(find build/ios/ipa -name "*.ipa" -type f 2>/dev/null | head -1 || true)
fi
[[ -n "$IPA_PATH" && -f "$IPA_PATH" ]] || fail "لم يُعثر على ملف IPA"
IPA_ABS="$(cd "$(dirname "$IPA_PATH")" && pwd)/$(basename "$IPA_PATH")"

# ── التحقق أن الناتج هو فعلاً ما طلبناه — من داخل الـ IPA، لا من الشجرة ──
BUILT_ID=$(ipa_plist "$IPA_ABS" CFBundleIdentifier)
BUILT_VERSION=$(ipa_plist "$IPA_ABS" CFBundleShortVersionString)
BUILT_NUMBER=$(ipa_plist "$IPA_ABS" CFBundleVersion)
BUILT_URL=$(unzip -p "$IPA_ABS" 'Payload/*.app/Frameworks/App.framework/flutter_assets/.env' \
  | grep -E '^BASE_URL=' | cut -d= -f2- || true)
[[ "$BUILT_ID" == "$ASC_APP_IDENTIFIER" ]] || fail "معرّف الحزمة $BUILT_ID لا يطابق $ASC_APP_IDENTIFIER"
[[ "$BUILT_VERSION" == "$VERSION_NAME" && "$BUILT_NUMBER" == "$VERSION_CODE" ]] \
  || fail "عدم تطابق! المطلوب ${VERSION_NAME} (${VERSION_CODE}) بينما الـ IPA: ${BUILT_VERSION} (${BUILT_NUMBER})"
[[ "$BUILT_URL" == "$PROD_URL" ]] || fail "الـ IPA يكلّم ${BUILT_URL:-?} لا ${PROD_URL}"
ok "✓ الـ IPA: $IPA_ABS — ${BUILT_ID} ${BUILT_VERSION} (${BUILT_NUMBER}) → ${BUILT_URL}"

# ── السحب المؤجَّل (بعد نجاح البناء) ──
if [[ "$CANCEL_PENDING" == true && "$UPLOAD_ONLY" == false ]]; then
  info "▶ سحب النسخة السابقة من المراجعة..."
  fastlane ios cancel_pending_review allow_in_review:"$FORCE_CANCEL"
fi

# ── الرفع ──
if [[ "$UPLOAD_ONLY" == true ]]; then
  info "▶ رفع الـ Build إلى TestFlight بلا إرسال للمراجعة..."
  fastlane ios upload_build ipa:"$IPA_ABS"
  ok "🎉 رُفع build ${VERSION_CODE} — يظهر في TestFlight بعد 10–30 دقيقة معالجة لدى Apple"
else
  info "▶ الرفع والإرسال للمراجعة..."
  fastlane ios submit ipa:"$IPA_ABS" version:"$VERSION_NAME"
  ok "🎉 النسخة ${VERSION_NAME} (build ${VERSION_CODE}) بانتظار مراجعة Apple"
fi
