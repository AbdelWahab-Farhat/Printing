# إحصائيات المبيعات — connecting the Flutter app

> **Status: not started.** The backend is built, tested and green — see
> [SALES-STATISTICS.md](SALES-STATISTICS.md). Nothing in `frontend/` has been touched, by
> instruction.
>
> This file is the handover: what the endpoint answers, what to build against it, and the four
> traps that will otherwise be discovered on a phone.

---

## 0. Where the app stands today

The app has no notion of this report. There is no model, no use case, no repository method, no
route and no drawer link.

**Nothing is broken at runtime by that** — the endpoint is new, so nothing calls it and nothing
parses it. There is no contract test to go red here either: the reports feature has no equivalent
of `order_resource_contract_test.dart`, because until now it had a single response shape that
never changed.

The whole of the existing reports feature is one screen, and it is the shape to copy:

```
lib/features/reports/
├── models/profit_and_loss_summary.dart          (+ .freezed.dart, .g.dart)
├── usecases/get_profit_and_loss.dart
├── repositories/report_repository.dart | report_repository_impl.dart
└── presentation/
    ├── viewmodel/profit_and_loss_cubit.dart | profit_and_loss_state.dart
    └── views/profit_and_loss_page.dart
```

`ReportRepository` already exists and already has exactly one method. This adds a second — no new
repository, no new impl, no new DI block.

---

## 1. What the server returns

```
GET /api/v1/reports/sales-statistics?from=2026-08-01&to=2026-09-08     reports.sales.view
```

Both dates are **required** and `to` is inclusive of its whole day — the same rule, the same
Arabic 422 messages, and the same field keys (`from`, `to`) as `/reports/profit-loss`.

A real response, computed from production data as it stood on 2026-09-08:

```jsonc
{
  "period": { "from": "2026-08-01", "to": "2026-09-08" },
  "sales_value": { "plain": "5626.40", "printed": "8193.00", "total": "13819.40" },
  "by_type": [
    { "type": "أكياس الشحن",         "value": "9157.90", "weight_kg": "294.700",
      "plain_kg": "111.200", "printed_kg": "183.500", "pieces": 4150 },
    { "type": "أكياس شفافه -",       "value": "1960.00", "weight_kg": "40.000",
      "plain_kg": "40.000",  "printed_kg": "0.000",   "pieces": 0 },
    { "type": "أكياس يد خارجية -",   "value": "1469.00", "weight_kg": "27.300",
      "plain_kg": "3.000",   "printed_kg": "24.300",  "pieces": 620 },
    { "type": "أكياس يد داخلية -",   "value": "160.00",  "weight_kg": "3.300",
      "plain_kg": "0.000",   "printed_kg": "3.300",   "pieces": 100 },
    { "type": "أكياس ورقية عادية -", "value": "1072.50", "weight_kg": "0.000",
      "plain_kg": "0.000",   "printed_kg": "0.000",   "pieces": 400 }
  ],
  "weight_comparison": {
    "plain_kg": "154.200", "printed_kg": "211.100", "total_kg": "365.300",
    "printed_share_percent": "57.8", "weight_coverage_percent": "92.2"
  },
  "printed_pieces": { "count": 5270, "weight_kg": "211.100" },
  "orders_counted": 32
}
```

| Key | Type | Unit |
| --- | --- | --- |
| `sales_value.*` | `String`, 2 decimals | **د.ل** |
| `by_type[].value` | `String`, 2 decimals | **د.ل** |
| `by_type[].weight_kg`, `plain_kg`, `printed_kg` | `String`, 3 decimals | **كجم** |
| `by_type[].pieces` | `int` | **قطعة** |
| `weight_comparison.*_kg` | `String`, 3 decimals | **كجم** |
| `*_percent` | `String`, 1 decimal | **٪** |
| `printed_pieces.count` | `int` | **قطعة** |
| `orders_counted` | `int` | طلبية |

**Every key is always present.** The server builds this as a plain array rather than a Resource,
so there is no `whenLoaded` anywhere in it: nothing is nullable, and an empty period reads as
`'0.00'` / `'0.000'` / `0` rather than as a gap. `by_type` is `[]` in that case, never null.

**Money and weights are `String`s end to end**, exactly as in `ProfitAndLossSummary`, and for the
same reason: they are summed, and a `double` is where a figure stops being the one the server
printed. Parse only to compare, never to display.

---

## 2. Models

`lib/features/reports/models/sales_statistics.dart`, five freezed classes mirroring
`SalesStatisticsQuery::__invoke()`:

```dart
@freezed
abstract class SalesStatistics with _$SalesStatistics {
  const factory SalesStatistics({
    required StatisticsPeriod period,
    @JsonKey(name: 'sales_value') required SalesValue salesValue,
    @JsonKey(name: 'by_type') required List<BagTypeRow> byType,
    @JsonKey(name: 'weight_comparison') required WeightComparison weightComparison,
    @JsonKey(name: 'printed_pieces') required PrintedPieces printedPieces,
    @JsonKey(name: 'orders_counted') required int ordersCounted,
  }) = _SalesStatistics;
  ...
}
```

`StatisticsPeriod` is the same two-`String` echo as `PnlPeriod` — **hold the days as `String`s,
never as `DateTime`s.** Round-tripping a plain day through a `DateTime` is how it grows a
timezone offset it never had. Copy `PnlPeriod.label` («من … إلى …») verbatim.

### The one thing that differs from الأرباح والخسائر

`ProfitAndLossSummary`'s docblock warns at length that its parts **need not add up** — three cost
figures from one table, a total from another. **This report is the opposite, deliberately:**
every figure is folded up from one grouped row set, so

* `by_type[].value` sums exactly to `sales_value.total`
* `by_type[].weight_kg` sums exactly to `weight_comparison.total_kg`
* `plain_kg` + `printed_kg` = `total_kg`, per row and overall

You may therefore render the type table under the totals without a caveat. **Still do not compute
one from the other** — take every figure from the key that carries it. The guarantee is that they
agree, not that the client should be the one doing the arithmetic. `printed_share_percent` in
particular is the server's own division and must not be recomputed.

---

## 3. Use case and repository

One new use case beside `GetProfitAndLoss`, carrying the same rule — **it normalises nothing**.
Both values come from a picker or a preset, so there is no keyboard to correct for, and a `to`
before `from` is sent anyway so the server can answer in its own Arabic under the right field.

```dart
class GetSalesStatistics {
  const GetSalesStatistics(this._repository);
  final ReportRepository _repository;

  Future<Either<Failure, SalesStatistics>> call({
    required String from,
    required String to,
  }) => _repository.salesStatistics(from: from, to: to);
}
```

A second method on the **existing** `ReportRepository`, and in `ReportRepositoryImpl` a second
`safeRequest` — not `safePaginatedRequest`: the endpoint answers one object and sends no `meta`,
so asking for page numbers would report «الرد لا يحتوي على بيانات الصفحات» for a perfectly
correct response.

---

## 4. Wiring — five one-line edits

| File | Edit |
| --- | --- |
| `core/network/api_endpoints.dart` | `static const String salesStatistics = '/reports/sales-statistics';` in `ReportEndpoints` |
| `core/permissions/app_permission.dart` | `viewSalesStatisticsReport('reports.sales.view', 'عرض إحصائيات المبيعات'),` |
| `core/di/injector.dart` | in `_registerReports()`: lazy singleton `GetSalesStatistics`, **factory** `SalesStatisticsCubit` — the screen owns its Cubit because the chosen period lives on it |
| `core/router/app_router.dart` | `Routes.salesStatistics = '/reports/sales-statistics'` + a `GoRoute` with the same `redirect` guard the P&L route uses |
| `features/root/.../root_page.dart` | a `PermissionGate` + `_DrawerLink` beside «الأرباح والخسائر» |

The permission is **separate from `reports.pnl.view`** and the guard must use the new one. This
board shows no cost and no margin, so it can be given to the press and the warehouse without
showing them what the shop earns — that is the whole point of it being its own grant, and reusing
the P&L permission in the router would quietly undo it.

---

## 5. The Cubit

Copy `ProfitAndLossCubit` almost exactly — `from`/`to` on the Cubit rather than in the state, so
the pickers survive a 422; `load()` on every period change; `refresh()` keeping the last good
figures on failure; the `isClosed` guard before `emit`. Copy `ProfitAndLossState` and its
`fromError` / `toError` / `hasUnrenderedErrors` extension unchanged — the field keys are the same
two.

**One addition: the presets.** The API takes only `from`/`to`; «اليوم / هذا الأسبوع / هذا الشهر»
are resolved on the client.

```dart
enum StatisticsPeriodPreset { today, week, month, custom }
```

* **The week starts Saturday.** `DateTime.saturday == 6` and Dart's `weekday` runs Monday=1…
  Sunday=7, so the offset is `(date.weekday + 1) % 7` days back from the start of the week.
* **One `DateTime.now()` per preset calculation**, for the reason `ProfitAndLossCubit._` already
  documents: read twice, a screen opened as the clock crosses midnight takes its two halves from
  different days.
* Default on open: **هذا الشهر**, matching the P&L screen.
* Picking a custom range switches the preset to `custom`; picking a preset overwrites both ends.

> **The day boundary is the server's, and it is UTC.** `PnlPeriod`'s docblock spells this out and
> it applies here identically: an order delivered just after midnight in طرابلس sits inside the
> month there and outside it here. The presets are computed from the phone's clock, the window is
> echoed back by the server, and **the echo is what the figures must be labelled with** — never
> the values the app sent.

---

## 6. The screen

`/reports/sales-statistics`, four blocks down one column, in this order:

1. **The period selector** — four chips, plus the two `showDatePicker` tiles from the P&L page
   (`_PickerTile`) revealed for «فترة مخصصة». Same `firstDate`/`lastDate` bounds, same plain
   `YYYY-MM-DD` formatting.
2. **قيمة المبيعات** — three tiles: الإجمالي, السادة, المطبوع, in **د.ل**. Use
   `groupedDecimal()` from `core/utils/digits.dart`, as `grossProfitLabel` does.
3. **السادة مقابل المطبوع** — the two weights in **كجم** with `printed_share_percent` stated,
   plus **عدد الأكياس المطبوعة** in **قطعة** as its own tile. Keep the piece count visually
   apart from the weights: it is a different unit answering a different question, and it is the
   figure the printing engineer's share will be computed from.
4. **مبيعات الأكياس حسب النوع** — the table, heaviest first as the server sorts it. Columns:
   النوع · الوزن (كجم) · سادة · مطبوع · القيمة (د.ل).

**Every figure carries its unit.** د.ل on money, كجم on weight, قطعة on the piece count — the
acceptance criteria name this explicitly, and this screen puts three units on one page.

### Four traps

**A row with real value and zero weight is correct, not a bug.** أكياس ورقية عادية is stocked by
the piece, so it earns money and weighs nothing. Do not hide the row and do not render `0.000` as
«—»: its value is part of the total above it, and dropping it would make the table stop adding up.

**Show the coverage line only when it is below 100.** `weight_coverage_percent` says how much of
the period's *value* has a weight behind it. At 100 it is noise; below it, it is the difference
between «باعوا قليلاً» and «ما وزنوهش», and without it the kg figures look wrong beside their own
dinars. Production sits at ~92% today.

**`orders_counted == 0` is a real period, not an empty state.** Say so in words rather than
painting five blocks of zeroes — `ProfitAndLossSummary.hasRecognisedOrders` is the existing
precedent and this model wants the same getter.

**The type labels are untidy, and the app must not tidy them.** Four of the five read
«أكياس شفافه -», «أكياس يد خارجية -» with a trailing dash, because those shelves were
auto-created from product names. Trimming it in Dart would hide a naming problem that also shows
on the inventory screens; the fix belongs in the data. Render what the server sends.

---

## 7. Tests to add

Mirroring `test/features/reports/`:

* Model — `fromJson` over the §1 payload; `by_type: []` parses to an empty list.
* Cubit — the four presets produce the expected `from`/`to` (**including the Saturday week
  start**, and a week straddling a month boundary); `setRange` does not re-fetch when neither end
  moved; a failed `refresh` keeps the loaded figures; a 422 leaves `from`/`to` on the Cubit.
* Widget — the coverage line is absent at `'100.0'` and present at `'92.2'`; a zero-weight row
  still renders its value; `orders_counted == 0` shows the empty-period wording.

Minimum Cubit coverage per `frontend/RULES.md` §9.

---

## 8. Checklist

- [ ] `sales_statistics.dart` + `dart run build_runner build --delete-conflicting-outputs`
- [ ] `GetSalesStatistics`
- [ ] `ReportRepository.salesStatistics` + impl
- [ ] `ReportEndpoints.salesStatistics`
- [ ] `AppPermission.viewSalesStatisticsReport`
- [ ] `_registerReports()` — use case + Cubit factory
- [ ] `Routes.salesStatistics` + guarded `GoRoute`
- [ ] Drawer link behind `PermissionGate`
- [ ] `SalesStatisticsCubit` + state + presets (**week starts Saturday**)
- [ ] `SalesStatisticsPage` + the four blocks
- [ ] Tests
- [ ] `flutter analyze`

---

## 9. Before the screen ships

Grant `reports.sales.view` to whichever roles should see it, from **الأدوار والصلاحيات**. The
backend adds the permission on deploy (`permissions:sync`) but assigns it to nobody — only the
administrator satisfies it by rule until somebody hands it out.
