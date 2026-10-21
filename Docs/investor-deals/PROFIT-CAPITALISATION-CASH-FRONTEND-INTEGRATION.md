# «أرباح صارت رأس مال» — the Flutter side

> The app side of [CONTINUOUS-FUND-DESIGN.md §١٢](CONTINUOUS-FUND-DESIGN.md): «تحويل أرباح إلى رأس
> مال» now takes the money out of the fund cash, the same way «سحب أرباح» does.
>
> **Status (2026-10-21): done.** It was merged in PR #30 (`2aa7d53a`). The app change is one line,
> and **no new build is required**. The user-facing summary is
> [changes/PR-30-PROFIT-CAPITALISATION-CASH.md](../changes/PR-30-PROFIT-CAPITALISATION-CASH.md).

---

## 0. What changed, in one paragraph

Profit that is available but not yet withdrawn still sits in the fund cash, as a debt the
valuation subtracts. Turning it into capital used to clear the debt and leave the cash, which
raised the unit price for every partner and counted the money twice once it was subscribed. Now
every `profit_capitalisation` wallet entry writes a fund cash row of a **new type,
`profit_capitalised`**. The fix is entirely on the server. The app only meets the new row in one
list.

---

## 1. Endpoints

**No new endpoint and no new request field.**

| Verb | Path | What is new | Permission |
|---|---|---|---|
| `POST` | `/investors/{investor}/wallet` with `type: profit_capitalisation` | nothing in the request or the answer; the server now also writes the cash row | `investors.money.record` |
| `GET` | `/investment/fund/cash` («سجل الخزينة») | rows may carry `type: profit_capitalised` | `investors.view` |
| `GET` | the fund dashboard | the numbers are right; no new key | unchanged |

---

## 2. The new row in «سجل الخزينة»

Everything the row needs to read correctly comes from flags the server already sends.
[fund_breakdown.dart](../../frontend/lib/features/investment_fund/models/fund_breakdown.dart)
parses them, and none of them is new:

| Key | Value for `profit_capitalised` | What the row draws |
|---|---|---|
| `type_label` | «أرباح صارت رأس مال» | the title |
| `is_inflow` | `false` | an outgoing amount |
| `moves_through_an_account` | `false` | no treasury account |
| `moves_through_the_investors_wallet` | `true` | «إلى: محفظة المستثمر» |
| `notes` | null; the back-fill writes «تصحيح: تحويل أرباح إلى رأس مال سُجِّل قبل أن يخرج من نقد الصندوق» | as any note |

The **one** change in the app is the icon in
[fund_cash_row.dart](../../frontend/lib/features/investment_fund/presentation/widgets/fund_cash_row.dart):

```dart
'profit_payout' ||
'profit_capitalised' ||
'company_payout' ||
'capital_return' => AppIcons.fundWithdraw,
```

In 1.9.0 and older, the row falls to `_ => AppIcons.more` (the «⋯» icon), while the label,
direction and account line still read correctly. That is why no release is forced.

---

## 3. Reversal

Nothing new. Reversing the wallet entry (`POST /investors/{investor}/wallet/{entry}/reversal`)
also reverses its cash row on the server (`ReverseWalletEntry::undoCash`), and the list shows the
ordinary `reversal` row.

---

## 4. What the app must not do

- **Do not compute the fund's cash, value or unit price** from the rows. The dashboard figures come
  from `FundValuation` on the server, and this fix changes them there.
- **Do not hard-code the cash types elsewhere.** `fund_cash_row.dart` is the only place in `lib/`
  that names them. A future type falls to «⋯» and still reads correctly from the flags above.

---

## 5. After the deploy

Older conversions get their row from a one-off command,
`php artisan investment:post-capitalised-profit --apply`. Those rows are **dated the day the
command runs**, not the day of the conversion, so on that day «سجل الخزينة» will show a cluster
of «أرباح صارت رأس مال» rows carrying the «تصحيح: …» note. This is expected and is not an app
bug.

---

## 6. Tests

- Flutter: none. There is no contract test for the cash types, and the change is one icon.
- Backend: `tests/Feature/Investors/FundUnitsTest.php`. It checks that the money leaves once and
  comes back once with the unit price unchanged, that reversal restores it, and the command.
