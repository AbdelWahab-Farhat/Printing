#!/usr/bin/env bash
# =====================================================================
# إعدادات النشر إلى App Store Connect — مشتركة بين سكربت الإصدار و fastlane
# =====================================================================
# تُستدعى بـ `source` فقط، لا تُشغَّل مباشرة:
#   source "$(dirname "$0")/asc_env.sh"
#
# منقولٌ عن primula_client/scripts/asc_env.sh. **الفرق الوحيد:** هناك مجلد scripts/ كله خارج
# git، وهنا السكربتات في git — فمعرّفا المفتاح يُقرآن من `scripts/asc_env.local.sh` (خارج git)
# أو من البيئة، ولا يُكتبان هنا. المفتاح السرّي (.p8) في ~/.appstoreconnect/private_keys/.
#
# مثال asc_env.local.sh:
#   export ASC_KEY_ID="XXXXXXXXXX"
#   export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# =====================================================================

_ASC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
[[ -f "$_ASC_DIR/asc_env.local.sh" ]] && source "$_ASC_DIR/asc_env.local.sh"

# دور المفتاح في App Store Connect يجب أن يكون App Manager
# (دور Developer لا يملك صلاحية الإرسال للمراجعة).
export ASC_KEY_ID="${ASC_KEY_ID:-}"
export ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"
# نكهة prod — حزمة الإنتاج كما في Runner.xcodeproj (`ly.dayaa.app`). نكهة dev حزمتها `.dev`
# وليست مسجّلة في App Store Connect.
export ASC_APP_IDENTIFIER="${ASC_APP_IDENTIFIER:-ly.dayaa.app}"

# مسار المفتاح: المجلد المعياري أولاً، ثم جذر frontend/ (كلاهما خارج git)
_ASC_KEY_FILE="AuthKey_${ASC_KEY_ID}.p8"
if [[ -z "${ASC_KEY_PATH:-}" ]]; then
  if [[ -f "$HOME/.appstoreconnect/private_keys/$_ASC_KEY_FILE" ]]; then
    export ASC_KEY_PATH="$HOME/.appstoreconnect/private_keys/$_ASC_KEY_FILE"
  else
    export ASC_KEY_PATH="$(cd "$_ASC_DIR/.." && pwd)/$_ASC_KEY_FILE"
  fi
fi

export RELEASE_FLAVOR="${RELEASE_FLAVOR:-prod}"
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1

# يفشل مبكراً بدل أن يفشل fastlane بعد بناء كامل
require_ios_env() {
  local missing=()
  [[ -n "$ASC_KEY_ID" ]]         || missing+=("ASC_KEY_ID")
  [[ -n "$ASC_ISSUER_ID" ]]      || missing+=("ASC_ISSUER_ID")
  [[ -n "$ASC_APP_IDENTIFIER" ]] || missing+=("ASC_APP_IDENTIFIER")
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "✗ ينقص إعداد iOS: ${missing[*]}" >&2
    echo "  اكتبها في scripts/asc_env.local.sh (أو صدّرها في بيئتك) ثم أعد التشغيل" >&2
    return 1
  fi
  [[ -f "$ASC_KEY_PATH" ]] || { echo "✗ ملف مفتاح App Store Connect غير موجود: $ASC_KEY_PATH" >&2; return 1; }
}
