#!/usr/bin/env bash
# =====================================================================
# إصدارُ تطبيق الموظفين للمنصّات الثلاث بأمرٍ واحد
# =====================================================================
#   1) الويب               → scripts/release_web.sh
#   2) iOS للمراجعة         → scripts/release_ios.sh
#   3) APK                 → scripts/build_apk.sh
#
# منقولٌ عن primula/employee/scripts/release_all.sh، ومدموجٌ مع نسخة 039644ad (كُتبت على خادم
# الإنتاج ولم تُدفع). الفكرة كما هي: كلُّ فحصٍ قد يُفشل أيَّ مرحلة يُنفَّذ *قبل* المرحلة الأولى —
# إعدادُ رفع الويب والوصولُ إليه بـssh، ومفتاحُ App Store Connect وملاحظاتُ الإصدار، ونسخةٌ سابقة
# عالقة في مراجعة Apple — حتى لا يُنشر الويب ثم يُكتشف أن iOS لا يُرسل.
#
# **والفرقُ الذي يستحقّ الذكر: يُبنى من HEAD لا من الشجرة.** هذه الشجرة تعمل فيها جلساتٌ عدّة معاً،
# وما لم يُثبَّت فيها ليس من الإصدار. فإن كان في frontend/ ما لم يُثبَّت، تُبنى المراحل كلُّها من نسخةٍ
# نظيفة لـHEAD في مجلّدٍ مؤقّت (git worktree)، ومعها الملفاتُ المحلية التي لا يحملها git (.env
# وأخواته)، ثم تُحذف. `--in-place` يبني هنا كما هي.
#
# الاستخدام:
#   ./scripts/release_all.sh                      # الويب يُنشر، iOS للمراجعة، ثم APK
#   ./scripts/release_all.sh --yes                # بلا سؤال تأكيد
#   ./scripts/release_all.sh --from ios           # استئناف من مرحلة iOS
#   ./scripts/release_all.sh --skip-web           # تخطّي مرحلة (--skip-ios، --skip-apk)
#   ./scripts/release_all.sh --in-place           # البناء من الشجرة كما هي
#   ./scripts/release_all.sh --cancel-pending     # اسحب النسخة العالقة في المراجعة ثم أرسل
#   ./scripts/release_all.sh --upload-only        # iOS إلى TestFlight فقط، بلا مراجعة
#   ./scripts/release_all.sh --manual-release     # بعد موافقة Apple يبقى بانتظار زرّ «Release»
#   ./scripts/release_all.sh -- <وسائط>           # ما بعد -- يُمرَّر لسكربت iOS كما هو
# =====================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${YELLOW}$*${NC}"; }
ok()    { echo -e "${GREEN}$*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
fail()  { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
head1() { echo -e "${BLUE}$*${NC}"; }

# ── قراءة الوسائط ──
RUN_WEB=true
RUN_ANDROID=true
RUN_IOS=true
ASSUME_YES=false
IN_PLACE=false
IOS_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-web)                RUN_WEB=false; shift ;;
    --skip-android|--skip-apk) RUN_ANDROID=false; shift ;;
    --skip-ios)                RUN_IOS=false; shift ;;
    --from)
      case "${2:-}" in
        web)         ;;
        ios)         RUN_WEB=false ;;
        android|apk) RUN_WEB=false; RUN_IOS=false ;;
        *) fail "--from يقبل: web | ios | android" ;;
      esac
      shift 2 ;;
    --in-place) IN_PLACE=true; shift ;;
    # وسائطُ سكربت iOS، تُقبل هنا مباشرةً كما في نسخة الخادم
    --upload-only|--manual-release|--skip-precheck|--cancel-pending|--force-cancel)
                IOS_ARGS+=("$1"); shift ;;
    --yes|-y)   ASSUME_YES=true; shift ;;
    --)         shift; IOS_ARGS=("$@"); break ;;
    -h|--help)  sed -n '2,30p' "$0"; exit 0 ;;
    *) fail "وسيط غير معروف: $1 (استخدم --help)" ;;
  esac
done

[[ "$RUN_WEB" == true || "$RUN_ANDROID" == true || "$RUN_IOS" == true ]] \
  || fail "لم تبقَ أي مرحلة للتنفيذ"

cd "$(dirname "$0")/.."
HOME_FRONT="$(pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"

# نسخةٌ نصّية من وسائط iOS للفحص فقط (الاستدعاءُ الحقيقي يستعمل المصفوفة)
ios_args_str() {
  if [[ ${#IOS_ARGS[@]} -gt 0 ]]; then echo " ${IOS_ARGS[*]} "; else echo " "; fi
}

# --yes الخاص بنا يسري أيضاً على تأكيد سحب النسخة داخل سكربت iOS
if [[ "$ASSUME_YES" == true ]]; then
  case "$(ios_args_str)" in
    *" --yes "*|*" -y "*) ;;
    *) IOS_ARGS+=(--yes) ;;
  esac
fi

# ── سجلّ التشغيل — في هذه الشجرة، فيبقى بعد حذف النسخة النظيفة ──
LOG_DIR="$HOME_FRONT/.release-logs"
mkdir -p "$LOG_DIR"

# =====================================================================
# من أين يُبنى
# =====================================================================
COMMIT=$(git rev-parse --short HEAD)
BUILD_TMP=""
FRONT="$HOME_FRONT"

cleanup_checkout() {
  if [[ -n "$BUILD_TMP" ]]; then
    git -C "$REPO_ROOT" worktree remove --force "$BUILD_TMP/repo" >/dev/null 2>&1 || true
    rm -rf "$BUILD_TMP"
  fi
}

if [[ "$IN_PLACE" == false && -n "$(git status --porcelain -- . 2>/dev/null || true)" ]]; then
  BUILD_TMP=$(mktemp -d "${TMPDIR:-/tmp}/dayaa-release.XXXXXX")
  # من الآن: أيُّ خروجٍ — فحصٌ فشل قبل المراحل أيضاً — يحذف النسخة النظيفة
  trap cleanup_checkout EXIT
  info "▶ في frontend/ ما لم يُثبَّت — البناء من نسخةٍ نظيفة لـ ${COMMIT}"
  git -C "$REPO_ROOT" worktree add --quiet --detach "$BUILD_TMP/repo" HEAD
  FRONT="$BUILD_TMP/repo/frontend"

  # ما لا يحمله git ويحتاجه البناء أو الرفع
  for f in .env .env.dev scripts/asc_env.local.sh scripts/web_deploy.local.sh; do
    [[ -f "$HOME_FRONT/$f" ]] && cp "$HOME_FRONT/$f" "$FRONT/$f"
  done
  # حزمُ Swift المحلولة من قبل — نسخةٌ فورية (APFS) توفّر تنزيلها كلَّها من جديد
  if [[ -d "$HOME_FRONT/ios/DerivedData" ]]; then
    cp -cR "$HOME_FRONT/ios/DerivedData" "$FRONT/ios/DerivedData" 2>/dev/null || true
  fi
  ok "✓ النسخة النظيفة: $FRONT"
fi

cd "$FRONT"

FULL_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=${FULL_VERSION%+*}
VERSION_CODE=${FULL_VERSION#*+}
LOG_FILE="$LOG_DIR/release-${FULL_VERSION}-$(date +%Y%m%d-%H%M%S).log"
NOTES="fastlane/metadata/ar-SA/release_notes.txt"

# =====================================================================
# الفحوصات التمهيدية — كل ما قد يُفشل أي مرحلة، قبل أن نبدأ أياً منها
# =====================================================================
head1 "═══════════════════════════════════════════════════════"
head1 "  فحوصات تمهيدية — النسخة ${VERSION_NAME} (build ${VERSION_CODE}) من ${COMMIT}"
head1 "═══════════════════════════════════════════════════════"

command -v flutter >/dev/null || fail "flutter غير موجود في PATH"
[[ -f .env ]] || fail "frontend/.env غير موجود — البناء يحزمه"

# ما يُبنى ولم يُدفع لا يعرفه أحدٌ غير هذا الماك
if [[ -z "$(git -C "$REPO_ROOT" branch -r --contains HEAD 2>/dev/null || true)" ]]; then
  warn "${COMMIT} لم يُدفع إلى origin — ادفعه قبل الإصدار أو بعده مباشرة"
fi

if [[ "$RUN_WEB" == true ]]; then
  # release_web.sh بلا هذا الملف يبني ثم يخرج بنجاحٍ دون رفع — هنا يجب أن يكون فشلاً.
  # shellcheck source=/dev/null
  [[ -f scripts/web_deploy.local.sh ]] && source scripts/web_deploy.local.sh
  [[ -n "${WEB_HOST:-}" && -n "${WEB_ROOT:-}" ]] \
    || fail "لا WEB_HOST/WEB_ROOT في scripts/web_deploy.local.sh — الويب كان سيُبنى ولا يُرفع (أو --skip-web)"
  command -v rsync >/dev/null || fail "rsync غير موجود — مطلوب لرفع الويب"
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$WEB_HOST" "test -d '$(dirname "$WEB_ROOT")'" \
    || fail "لا وصول بـssh إلى $WEB_HOST:$(dirname "$WEB_ROOT")"
  ok "✓ الويب: يُبنى ويُرفع إلى $WEB_HOST:$WEB_ROOT"
fi

if [[ "$RUN_ANDROID" == true ]]; then
  # build_apk.sh يستعمل aapt2 في *نهاية* البناء للتحقق من النسخة؛ غيابُه فشلٌ بعد بناءٍ كامل
  ls "$HOME"/Library/Android/sdk/build-tools/*/aapt2 >/dev/null 2>&1 \
    || fail "aapt2 غير موجود في Android SDK build-tools — ثبّته من SDK Manager"
  ok "✓ أندرويد: aapt2 جاهز للتحقق من النسخة"
fi

if [[ "$RUN_IOS" == true ]]; then
  [[ "$(uname)" == Darwin ]] || fail "iOS يُبنى على الماك وحده — أو أضف --skip-ios"
  # shellcheck source=./asc_env.sh
  source scripts/asc_env.sh
  command -v fastlane >/dev/null || fail "fastlane غير مثبّت — brew install fastlane"
  require_ios_env || exit 1

  case "$(ios_args_str)" in
    *" --upload-only "*) ;;
    *)
      [[ -f "$NOTES" ]] || fail "ملف ملاحظات الإصدار مفقود: $NOTES"
      if grep -q '^###' "$NOTES"; then fail "لم تُكتب ملاحظات الإصدار بعد — عدّل $NOTES"; fi
      [[ -n "$(tr -d '[:space:]' < "$NOTES")" ]] || fail "ملاحظات الإصدار فارغة: $NOTES"
      # ملاحظاتٌ لم تتغيّر منذ آخر رفعٍ لرقم النسخة غالباً بقيت من الإصدار السابق. من git لا من
      # تاريخ الملف: النسخةُ النظيفة تكتب كلَّ ملفٍّ الآن.
      notes_at=$(git log -1 --format=%ct -- "$NOTES" 2>/dev/null || echo 0)
      bump_at=$(git log -1 --format=%ct -G'^version:' -- pubspec.yaml 2>/dev/null || echo 0)
      if [[ "${notes_at:-0}" -lt "${bump_at:-0}" ]]; then
        warn "ملاحظات الإصدار لم تتغيّر منذ رفع رقم النسخة — هل حدّثتها لـ ${VERSION_NAME}؟"
      fi
      ;;
  esac
  ok "✓ iOS: fastlane والمفتاح وملاحظات الإصدار جاهزة"

  # Apple تسمح بنسخةٍ واحدة «قيد الطريق» — فحصُها الآن يوفّر البناء كله
  case "$(ios_args_str)" in
    *" --cancel-pending "*)
      info "▶ iOS: سيُسحب طلب المراجعة الحالي لاحقاً (--cancel-pending) — تخطّي فحص الحالة" ;;
    *" --upload-only "*)
      info "▶ iOS: فحص مسار النسخة في TestFlight..."
      fastlane ios check_test_version version:"$VERSION_NAME" ;;
    *)
      info "▶ iOS: فحص حالة النسخة في App Store Connect..."
      fastlane ios check_version version:"$VERSION_NAME" ;;
  esac
fi

# ── خطة التنفيذ + تأكيد ──
echo ""
head1 "═══════════════════════════════════════════════════════"
head1 "  خطة الإصدار ${FULL_VERSION} — ${COMMIT}"
head1 "═══════════════════════════════════════════════════════"
if [[ "$RUN_WEB" == true ]]; then
  echo "  1) 🌐 الويب     → بناء + فحص + رفع إلى $WEB_HOST:$WEB_ROOT"
else
  echo "  1) 🌐 الويب     → (متخطّى)"
fi
if [[ "$RUN_IOS" == true ]]; then
  echo "  2) 🍎 iOS       → بناء IPA (prod) + $(case "$(ios_args_str)" in *" --upload-only "*) echo "رفع إلى TestFlight" ;; *) echo "إرسال للمراجعة" ;; esac)"
  if [[ ${#IOS_ARGS[@]} -gt 0 ]]; then echo "                    وسائط إضافية: ${IOS_ARGS[*]}"; fi
  case "$(ios_args_str)" in
    *" --upload-only "*) ;;
    *)
      echo ""
      echo "  ما الجديد (يُرسل لـ Apple):"
      sed 's/^/    │ /' "$NOTES"
      echo "" ;;
  esac
else
  echo "  2) 🍎 iOS       → (متخطّى)"
fi
if [[ "$RUN_ANDROID" == true ]]; then
  echo "  3) 🤖 أندرويد   → ~/Desktop/Dayaa-Staff-${VERSION_NAME}-prod.apk"
else
  echo "  3) 🤖 أندرويد   → (متخطّى)"
fi
echo ""
echo "  📄 السجلّ: ${LOG_FILE/#$HOME_FRONT\//}"
echo ""

if [[ "$ASSUME_YES" == false ]]; then
  [[ -t 0 ]] || fail "التشغيل غير تفاعلي — أضف --yes"
  read -r -p "اكتب yes للبدء: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || fail "أُلغيت العملية"
fi

# =====================================================================
# تشغيل المراحل
# =====================================================================
STAGE_LABELS=(); STAGE_STATES=(); STAGE_TIMES=()
RUN_START=$SECONDS
FAILED_STAGE=""
RESUME_HINT=""

fmt_dur() { printf '%02d:%02d:%02d' $(($1/3600)) $(($1%3600/60)) $(($1%60)); }

print_summary() {
  echo ""
  head1 "═══════════════════════════════════════════════════════"
  head1 "  ملخّص الإصدار ${FULL_VERSION} — ${COMMIT}"
  head1 "═══════════════════════════════════════════════════════"
  local i=0
  while [[ $i -lt ${#STAGE_LABELS[@]} ]]; do
    if [[ "${STAGE_STATES[$i]}" == "ok" ]]; then
      echo -e "  ${GREEN}✓${NC}  ${STAGE_LABELS[$i]}   $(fmt_dur "${STAGE_TIMES[$i]}")"
    else
      echo -e "  ${RED}✗${NC}  ${STAGE_LABELS[$i]}   $(fmt_dur "${STAGE_TIMES[$i]}")"
    fi
    i=$((i + 1))
  done
  echo -e "  ⏱   الإجمالي        $(fmt_dur $((SECONDS - RUN_START)))"
  echo "  📄  السجلّ: $LOG_FILE"
  if [[ -n "$FAILED_STAGE" ]]; then
    echo ""
    echo -e "${RED}✗ توقّف الإصدار عند: ${FAILED_STAGE}${NC}"
    echo -e "${YELLOW}  للاستئناف بعد الإصلاح:${NC}"
    echo -e "${YELLOW}  ${RESUME_HINT}${NC}"
  fi
  echo ""
}

on_exit() {
  print_summary
  cleanup_checkout
}
trap on_exit EXIT

run_stage() {
  local label="$1"; shift
  local start=$SECONDS
  echo ""
  head1 "───────────────────────────────────────────────────────"
  head1 "▶ ${label}"
  head1 "───────────────────────────────────────────────────────"
  { echo ""; echo "===== ${label} ====="; } >> "$LOG_FILE"

  set +e
  "$@" 2>&1 | tee -a "$LOG_FILE"
  local status=${PIPESTATUS[0]}   # لا تُدرج أي أمر قبل هذا السطر: PIPESTATUS يُستبدل
  set -e

  local dur=$((SECONDS - start))
  STAGE_LABELS+=("$label")
  STAGE_TIMES+=("$dur")
  if [[ $status -eq 0 ]]; then
    STAGE_STATES+=("ok")
    ok "✓ اكتملت: ${label} خلال $(fmt_dur "$dur")"
  else
    STAGE_STATES+=("fail")
    FAILED_STAGE="$label"
    echo -e "${RED}✗ فشلت: ${label} (رمز الخروج $status)${NC}" >&2
    return "$status"
  fi
}

if [[ "$RUN_WEB" == true ]]; then
  RESUME_HINT="./scripts/release_all.sh"
  run_stage "🌐 الويب      " ./scripts/release_web.sh || exit 1
fi

# iOS قبل الأندرويد عمداً: رفعُ البِلد يبدأ انتظار Apple، فكلّما بدأ أبكر انتهت المراجعة أبكر —
# وبناءُ الـ APK يجري والبِلد في طابورهم
if [[ "$RUN_IOS" == true ]]; then
  RESUME_HINT="./scripts/release_all.sh --from ios"
  run_stage "🍎 إصدار iOS  " ./scripts/release_ios.sh ${IOS_ARGS[@]+"${IOS_ARGS[@]}"} || exit 1
fi

if [[ "$RUN_ANDROID" == true ]]; then
  RESUME_HINT="./scripts/release_all.sh --from android"
  run_stage "🤖 بناء APK   " ./scripts/build_apk.sh || exit 1
fi

RESUME_HINT=""
echo ""
ok "🎉 تمّ الإصدار الكامل للنسخة ${VERSION_NAME} (build ${VERSION_CODE}) من ${COMMIT}"
[[ "$RUN_WEB" == true ]] && ok "   🌐 رُفع الويب إلى $WEB_HOST:$WEB_ROOT" || true
[[ "$RUN_IOS" == true ]] && ok "   🍎 App Store Connect — https://appstoreconnect.apple.com/apps" || true
[[ "$RUN_ANDROID" == true ]] && ok "   🤖 ~/Desktop/Dayaa-Staff-${VERSION_NAME}-prod.apk" || true
warn "الخادم لا يُنشر من هنا: ssh <prod> printing-deploy قبل أن يصل التطبيق إلى أحد"
