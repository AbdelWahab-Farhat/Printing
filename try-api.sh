#!/usr/bin/env bash
# Quick manual tester for the Printing API.
#
#   ./try-api.sh              run a full guided tour of every endpoint
#   ./try-api.sh token        print just a bearer token (to paste into Swagger)
#   ./try-api.sh get  /v1/products?search=shipping
#   ./try-api.sh post /v1/products/1/quote '{"variant_id":1,"quantity":300}'
#   ./try-api.sh put  /v1/products/1 '{...}'
#   ./try-api.sh upload /v1/products/1/images /path/to/photo.jpg
#
set -euo pipefail

BASE="${BASE:-http://127.0.0.1:8000/api}"
LOGIN="${LOGIN:-0910000000}"
PASSWORD="${PASSWORD:-password}"

pretty() { php -r '$i=stream_get_contents(STDIN); $j=json_decode($i,true); echo $j===null ? $i : json_encode($j, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES); echo "\n";'; }
hr()     { printf '\n\033[1;36m── %s\033[0m\n' "$1"; }

get_token() {
  curl -s -H 'Accept: application/json' -H 'Content-Type: application/json' \
    -d "{\"login\":\"$LOGIN\",\"password\":\"$PASSWORD\"}" \
    "$BASE/v1/auth/login" \
  | php -r '$r=json_decode(stream_get_contents(STDIN),true); echo $r["data"]["token"] ?? "";'
}

TOKEN="${TOKEN:-$(get_token)}"
[ -n "$TOKEN" ] || { echo "Login failed. Is the server running? (cd backend && php artisan serve)"; exit 1; }

api() { # method path [body]
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    curl -s -X "$method" -H 'Accept: application/json' -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $TOKEN" -d "$body" "$BASE$path"
  else
    curl -s -X "$method" -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN" "$BASE$path"
  fi
}

case "${1:-tour}" in
  token)  echo "$TOKEN"; exit 0 ;;
  get)    api GET    "$2" | pretty; exit 0 ;;
  post)   api POST   "$2" "${3:-}" | pretty; exit 0 ;;
  put)    api PUT    "$2" "${3:-}" | pretty; exit 0 ;;
  patch)  api PATCH  "$2" "${3:-}" | pretty; exit 0 ;;
  delete) api DELETE "$2" | pretty; exit 0 ;;
  upload)
    curl -s -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN" \
      -F "image=@$3" "$BASE$2" | pretty; exit 0 ;;
esac

# ── guided tour ───────────────────────────────────────────────────────────────
hr "health (public — no token needed)"
curl -s "$BASE/v1/health" | pretty

hr "who am I"
api GET /v1/auth/me | pretty

hr "catalogue: slug, unit, mode, minimum"
api GET '/v1/products?per_page=20' | php -r '
$r=json_decode(stream_get_contents(STDIN),true);
foreach ($r["data"] as $p) {
  printf("  #%-2d %-26s %-9s %-16s min=%-8s sizes=%d\n",
    $p["id"], $p["slug"], $p["pricing_unit"], $p["pricing_mode"], $p["min_order_quantity"], count($p["variants"]));
}'

hr "sizes and price breaks for shipping-bag (#1)"
api GET /v1/products/1 | php -r '
$p=json_decode(stream_get_contents(STDIN),true)["data"];
foreach ($p["variants"] as $v) {
  printf("  variant #%-3d %-8s  %s\n", $v["id"], $v["label"],
    implode("   ", array_map(fn($t)=>$t["min_quantity"]."+ → ".$t["unit_price"], $v["price_tiers"])));
}'

hr "quoting the same size at different quantities"
for q in 250 300 1000; do
  printf "  qty %-5s " "$q"
  api POST /v1/products/1/quote "{\"variant_id\":1,\"quantity\":$q}" | php -r '
  $r=json_decode(stream_get_contents(STDIN),true);
  if (!isset($r["data"])) { echo "refused: ", $r["errors"]["quantity"][0] ?? $r["message"], "\n"; exit; }
  $d=$r["data"];
  echo $d["unit_price"], " each  →  total ", $d["total"];
  echo $d["next_tier"] ? "   (".$d["next_tier"]["quantity_to_reach"]." more → ".$d["next_tier"]["unit_price"].")" : "   (best rate)";
  echo "\n";'
done

hr "below the minimum is refused"
api POST /v1/products/1/quote '{"variant_id":1,"quantity":50}' | pretty

hr "a quote-only product refuses to invent a price"
api POST /v1/products/6/quote '{"variant_id":21,"quantity":500}' | pretty

hr "per-kilo product: 2.5 kg"
api POST /v1/products/7/quote '{"variant_id":22,"quantity":2.5}' | pretty

hr "customers"
api GET /v1/customers | php -r '
$r=json_decode(stream_get_contents(STDIN),true);
echo "  total: ", $r["meta"]["total"], "\n";
foreach ($r["data"] as $c) printf("  %-4s %-16s %s\n", $c["code"], $c["phone"], $c["name"]);'

hr "done — token for Swagger:"
echo "$TOKEN"
