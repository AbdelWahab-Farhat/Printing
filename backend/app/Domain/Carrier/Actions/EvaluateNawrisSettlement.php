<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\DTOs\NawrisParcelTerms;
use App\Domain\Carrier\DTOs\NawrisSettlementLine;
use App\Domain\Carrier\DTOs\NawrisSettlementPreview;
use App\Domain\Carrier\DTOs\NawrisSettlementRow;
use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use App\Domain\Carrier\Enums\NawrisSettlementRejection;
use App\Domain\Carrier\Enums\NawrisSettlementWarning;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\TransitionField;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\TransitionFieldType;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use App\Domain\Order\Support\TransitionFields;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Support\DecimalText;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * ماذا سيحدث لكل طلبية في الملف — بلا كتابة حرف واحد.
 *
 * **المعاينة والتنفيذ يمرّان من هنا**، فلا تعد المعاينة بشيء ويفعل التنفيذ غيره.
 *
 * - **المستلم هو المرجع.** عمود «اسم المستلم» يحمل كود الطلبية — ما نرسله نحن في
 *   `BuildNawrisPayload` — والمركّب يُفصل على `+`، وكل طلبية تُعامَل وحدها.
 * - **كود النورس تنبيه لا شرط.** النورس يعيد إنشاء الطرد بكود جديد أحياناً، ورفض تلك الصفوف
 *   يوقف تسوية طلبيات سُلّمت فعلاً. إلا حين لا يصلح المستلم نفسه: عندها الكود هو ما بقي.
 * - **كل ما قد يرفضه `ChangeOrderStatus` يُقال هنا**، قبل أن يضغط أحد: لا `catch` في هذا
 *   المشروع، فرفضٌ أثناء التنفيذ يرجع الدفعة كلها.
 */
final class EvaluateNawrisSettlement
{
    /** النورس يكتب «تم التسوية»، وهكذا نسمّيها نحن أيضاً؛ «تمت» تأتي من القالب اليدوي. */
    private const SETTLED_LABELS = ['تم التسوية', 'تمت التسوية'];

    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  list<NawrisSettlementRow>  $rows
     * @param  bool  $withFields  بلا أسئلة الحسابات — أثقل ما هنا، ولا تلزم لمعرفة ما يُقفل
     */
    public function __invoke(array $rows, ?User $actor, bool $withFields = true): NawrisSettlementPreview
    {
        $plan = $this->plan($rows);
        $orders = $this->ordersFor($plan);
        $parcels = $this->parcelsOf($orders->pluck('id')->map(fn ($id): int => (int) $id)->all());
        $custody = $this->treasury->custodyOfMany($orders->pluck('id')->map(fn ($id): int => (int) $id)->all());
        $nawris = (int) $this->treasury->systemAccount(TreasuryAccount::NAWRIS)->getKey();

        $seen = [];
        $lines = [];

        foreach ($plan as $step) {
            $lines[] = $this->decide($step, $orders, $parcels, $custody, $nawris, $seen);
        }

        $shares = $this->feeShares($lines, $parcels);

        $lines = array_map(function (NawrisSettlementLine $line) use ($parcels, $custody, $nawris, $shares): NawrisSettlementLine {
            return $line->settles()
                ? $this->withMoney($line, $parcels, $custody[(int) $line->orderId] ?? [], $nawris, $shares)
                : $line;
        }, $lines);

        return new NawrisSettlementPreview(
            rowsCount: count($rows),
            lines: $lines,
            fields: $withFields ? $this->fieldsFor($lines, $actor) : [],
        );
    }

    /**
     * كل صف إلى خطوات: خطوة لكل جزء من المستلم.
     *
     * @param  list<NawrisSettlementRow>  $rows
     * @return list<array{row: NawrisSettlementRow, code: ?string, matched_by_code: bool}>
     */
    private function plan(array $rows): array
    {
        $byParcel = $this->orderCodesByParcelCode($rows);
        $plan = [];

        foreach ($rows as $row) {
            $parts = array_values(array_filter(
                array_map('trim', explode('+', $row->receiver)),
                fn (string $part): bool => $part !== '',
            ));

            $codes = array_map(fn (string $part): ?string => $this->orderCode($part), $parts);

            // المستلم كله لا يصلح: كود الطرد آخر ما يدلّ على طلبياته.
            if (array_filter($codes) === [] && $this->accepted($row)) {
                $fromParcel = $byParcel[$this->chainBase($row->code)] ?? [];

                if ($fromParcel !== []) {
                    foreach ($fromParcel as $code) {
                        $plan[] = ['row' => $row, 'code' => $code, 'matched_by_code' => true];
                    }

                    continue;
                }
            }

            // مستلم فارغ: سطر واحد كي لا يختفي الصف من التقرير.
            foreach ($codes === [] ? [null] : $codes as $code) {
                $plan[] = ['row' => $row, 'code' => $code, 'matched_by_code' => false];
            }
        }

        return $plan;
    }

    /**
     * جزء المستلم إلى كود طلبية، أو null.
     *
     * تُزال علامات الترقيم من الطرفين فقط («1203.»)، ويُرفض كل ما سواها. **الحرف لا يُنظَّف**: في
     * بريمولا صارت «ودان(S16)» — مدينة انزاحت إلى العمود — الرقمَ 16 فسُوّيت طلبية لا علاقة لها
     * بالشحنة بلا أي خطأ. والفراغ في الوسط لا يُحذف كذلك: «1203 1204» طلبيتان لا 12031204.
     */
    private function orderCode(string $part): ?string
    {
        $part = strtr($part, array_combine(
            ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'],
            ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
        ));

        $digits = preg_replace('/^[^\p{L}\d]+|[^\p{L}\d]+$/u', '', $part) ?? '';

        return preg_match('/^\d+$/', $digits) === 1 ? $digits : null;
    }

    private function accepted(NawrisSettlementRow $row): bool
    {
        $status = trim(preg_replace('/\s+/u', ' ', $row->status) ?? $row->status);

        return in_array($status, self::SETTLED_LABELS, true);
    }

    /** إعادة الإرسال تُلحق N بالكود (4097115N ثم 4097115NN) — والطرد واحد. */
    private function chainBase(string $code): string
    {
        return rtrim(trim($code), 'N');
    }

    /**
     * @param  list<NawrisSettlementRow>  $rows
     * @return array<string, list<string>>
     */
    private function orderCodesByParcelCode(array $rows): array
    {
        $wanted = [];

        foreach ($rows as $row) {
            if (trim($row->code) !== '') {
                $wanted[trim($row->code)] = true;
                $wanted[$this->chainBase($row->code)] = true;
            }
        }

        if ($wanted === []) {
            return [];
        }

        $links = DB::table('nawris_parcel_orders as l')
            ->join('nawris_parcels as p', 'p.id', '=', 'l.nawris_parcel_id')
            ->join('orders as o', 'o.id', '=', 'l.order_id')
            ->whereIn('p.code', array_map('strval', array_keys($wanted)))
            ->whereNull('l.deleted_at')
            ->whereNull('p.deleted_at')
            ->orderBy('o.id')
            ->get(['p.code', 'o.code as order_code']);

        $map = [];

        foreach ($links as $link) {
            $map[$this->chainBase((string) $link->code)][] = (string) $link->order_code;
        }

        return $map;
    }

    /**
     * كل الطلبيات دفعة واحدة، بالمحذوفة منها كي تُميَّز «محذوفة» عن «غير موجودة». والحيّة تغلب.
     *
     * @param  list<array{row: NawrisSettlementRow, code: ?string, matched_by_code: bool}>  $plan
     * @return Collection<string, Order>
     */
    private function ordersFor(array $plan): Collection
    {
        $codes = array_values(array_unique(array_filter(array_column($plan, 'code'))));

        if ($codes === []) {
            return collect();
        }

        return Order::query()
            ->withTrashed()
            ->whereIn('code', $codes)
            ->orderByRaw('deleted_at IS NULL')
            ->get()
            ->keyBy(fn (Order $order): string => (string) $order->code);
    }

    /**
     * طرود كل طلبية، الأحدث أولاً. الروابط الحيّة وحدها: طلبية فُكّت من طرد لم تعد فيه.
     *
     * @param  list<int>  $orderIds
     * @return array<int, list<object>>
     */
    private function parcelsOf(array $orderIds): array
    {
        if ($orderIds === []) {
            return [];
        }

        return DB::table('nawris_parcel_orders as l')
            ->join('nawris_parcels as p', 'p.id', '=', 'l.nawris_parcel_id')
            ->whereIn('l.order_id', $orderIds)
            ->whereNull('l.deleted_at')
            ->whereNull('p.deleted_at')
            ->orderByDesc('l.id')
            ->get([
                'l.order_id', 'l.nawris_parcel_id', 'l.amount_to_collect', 'p.code', 'p.carrier_fee',
                'p.shipment_on_sender', 'p.sync_failed_at', 'p.closed_at', 'p.conflict_raised_at',
                'p.conflict_resolved_at',
            ])
            ->groupBy('order_id')
            ->map(fn (Collection $rows): array => $rows->all())
            ->all();
    }

    /**
     * @param  array{row: NawrisSettlementRow, code: ?string, matched_by_code: bool}  $step
     * @param  Collection<string, Order>  $orders
     * @param  array<int, list<object>>  $parcels
     * @param  array<int, array<int, string>>  $custody
     * @param  array<int, true>  $seen  ما تقرّرت تسويته في هذا الملف
     */
    private function decide(array $step, Collection $orders, array $parcels, array $custody, int $nawris, array &$seen): NawrisSettlementLine
    {
        $row = $step['row'];

        if (! $this->accepted($row)) {
            return $this->rejected(
                $row,
                NawrisSettlementRejection::StatusNotSettled,
                'حالة الصف في الملف ليست «تم التسوية».',
            );
        }

        if ($step['code'] === null) {
            return $this->rejected(
                $row,
                NawrisSettlementRejection::ReceiverNotUsable,
                'عمود المستلم لا يحمل رقم طلبية صالحاً، ولا يدلّ كود الطرد على طلبية.',
            );
        }

        $order = $orders->get($step['code']);

        if ($order === null) {
            return $this->rejected(
                $row,
                NawrisSettlementRejection::OrderNotFound,
                "لا توجد طلبية بالرقم {$step['code']}.",
            );
        }

        $id = (int) $order->getKey();

        $warnings = [
            ...$this->codeWarnings($row->code, $parcels[$id] ?? []),
            ...($step['matched_by_code'] ? [[
                'code' => NawrisSettlementWarning::MatchedByCode,
                'message' => 'عمود المستلم لا يصلح — عُرفت الطلبية من كود الطرد.',
            ]] : []),
        ];

        $known = fn (NawrisSettlementOutcome $outcome, ?NawrisSettlementRejection $rejection = null, ?string $reason = null) => new NawrisSettlementLine(
            row: $row,
            outcome: $outcome,
            orderId: $id,
            orderCode: (string) $order->code,
            previousStatus: $order->status,
            rejection: $rejection,
            reason: $reason,
            warnings: $warnings,
        );

        if ($order->trashed()) {
            return $known(NawrisSettlementOutcome::Rejected, NawrisSettlementRejection::OrderDeleted, "الطلبية {$order->code} محذوفة.");
        }

        if ($order->status === OrderStatus::Settled) {
            return $known(NawrisSettlementOutcome::AlreadySettled, reason: 'الطلبية مسوّاة سلفاً.');
        }

        if (isset($seen[$id])) {
            return $known(NawrisSettlementOutcome::AlreadySettled, reason: 'مكررة في الملف — تُسوّى في سطر سابق.');
        }

        if ($order->status !== OrderStatus::Delivered) {
            return $known(
                NawrisSettlementOutcome::Rejected,
                NawrisSettlementRejection::OrderNotDelivered,
                "الطلبية في حالة «{$order->status->label()}» — لا تُسوّى إلا من «تم الاستلام».",
            );
        }

        if ($order->paymentStatus()->isOutstanding()) {
            $remaining = DecimalText::trim($order->remainingAmount());

            return $known(
                NawrisSettlementOutcome::Rejected,
                NawrisSettlementRejection::OrderHasBalance,
                "باقٍ على الطلبية {$remaining} د.ل.",
            );
        }

        if (($parcels[$id] ?? []) === [] && ! isset($custody[$id][$nawris])) {
            return $known(
                NawrisSettlementOutcome::Rejected,
                NawrisSettlementRejection::NotANawrisOrder,
                'لا طرد لهذه الطلبية ولا مال لها عند النورس.',
            );
        }

        $seen[$id] = true;

        return $known(NawrisSettlementOutcome::Settled);
    }

    private function rejected(NawrisSettlementRow $row, NawrisSettlementRejection $rejection, string $reason): NawrisSettlementLine
    {
        return new NawrisSettlementLine($row, NawrisSettlementOutcome::Rejected, rejection: $rejection, reason: $reason);
    }

    /**
     * @param  list<object>  $parcels
     * @return list<array{code: NawrisSettlementWarning, message: string}>
     */
    private function codeWarnings(string $rawCode, array $parcels): array
    {
        $rawCode = trim($rawCode);

        if ($rawCode === '') {
            return [];
        }

        $ours = array_values(array_filter(array_map(fn (object $parcel): string => (string) $parcel->code, $parcels)));

        if ($ours === []) {
            return [[
                'code' => NawrisSettlementWarning::CodeMissing,
                'message' => "الملف يذكر الكود {$rawCode} ولا طرد لهذه الطلبية عندنا.",
            ]];
        }

        foreach ($ours as $code) {
            if ($this->chainBase($code) === $this->chainBase($rawCode)) {
                return [];
            }
        }

        // لاحقة أخرى (4306969R، النصف الراجع من تسليم جزئي) طردٌ غير طردنا: يُطابَق بأرقامه وينبَّه.
        $digits = preg_replace('/\D+$/', '', $rawCode) ?? $rawCode;

        if ($digits !== $rawCode && in_array($digits, $ours, true)) {
            return [[
                'code' => NawrisSettlementWarning::CodeSuffix,
                'message' => "طوبق الكود {$rawCode} بعد تجاهل لاحقته — كود الطرد عندنا {$digits}.",
            ]];
        }

        return [[
            'code' => NawrisSettlementWarning::CodeMismatch,
            'message' => "كود الملف {$rawCode} يخالف كود الطرد عندنا ".implode('، ', $ours).'.',
        ]];
    }

    /**
     * أجرة كل طلبية من طردها الأحدث، حين تكون علينا.
     *
     * الأجرة للطرد لا للطلبية، فالطرد المشترك يقسمها بنسبة مبلغ كل طلبية فيه، وما تبقّى من القروش
     * على الأكبر.
     *
     * @param  list<NawrisSettlementLine>  $lines
     * @param  array<int, list<object>>  $parcels
     * @return array<int, string>
     */
    private function feeShares(array $lines, array $parcels): array
    {
        $latest = [];

        foreach ($lines as $line) {
            $parcel = $line->settles() ? ($parcels[(int) $line->orderId][0] ?? null) : null;

            if ($parcel !== null && $this->weOweTheFee($parcel) && $parcel->carrier_fee !== null) {
                $latest[(int) $parcel->nawris_parcel_id] = $parcel;
            }
        }

        if ($latest === []) {
            return [];
        }

        $members = DB::table('nawris_parcel_orders')
            ->whereIn('nawris_parcel_id', array_keys($latest))
            ->whereNull('deleted_at')
            ->orderBy('order_id')
            ->get(['nawris_parcel_id', 'order_id', 'amount_to_collect'])
            ->groupBy('nawris_parcel_id');

        $shares = [];

        foreach ($latest as $parcelId => $parcel) {
            $rows = $members->get($parcelId, collect());
            $total = Money::sum('0', ...$rows->map(fn (object $row): string => (string) $row->amount_to_collect)->all());
            $fee = Money::normalize($parcel->carrier_fee);
            $assigned = '0.00';
            $largest = null;

            foreach ($rows as $row) {
                $amount = (string) $row->amount_to_collect;
                $share = bccomp($total, '0', Money::SCALE) > 0
                    ? bcdiv(bcmul($fee, $amount, 8), $total, Money::SCALE)
                    : '0.00';

                $shares[(int) $row->order_id] = $share;
                $assigned = bcadd($assigned, $share, Money::SCALE);

                if ($largest === null || bccomp($amount, (string) $largest->amount_to_collect, Money::SCALE) > 0) {
                    $largest = $row;
                }
            }

            if ($largest !== null) {
                $id = (int) $largest->order_id;
                $shares[$id] = bcadd($shares[$id], bcsub($fee, $assigned, Money::SCALE), Money::SCALE);
            }
        }

        return $shares;
    }

    private function weOweTheFee(object $parcel): bool
    {
        return (int) $parcel->shipment_on_sender === NawrisParcelTerms::SENDER_PAYS;
    }

    /**
     * @param  array<int, list<object>>  $parcels
     * @param  array<int, string>  $held  حساب العهدة => ما فيه لهذه الطلبية
     * @param  array<int, string>  $shares
     */
    private function withMoney(NawrisSettlementLine $line, array $parcels, array $held, int $nawris, array $shares): NawrisSettlementLine
    {
        $id = (int) $line->orderId;
        $amount = $held[$nawris] ?? '0.00';
        $parcel = $parcels[$id][0] ?? null;
        $warnings = [];

        // لا تزيد الأجرة على ما عنده: `SettleCustody` يرفض ما يفوق العهدة.
        $fee = $shares[$id] ?? '0.00';
        $fee = bccomp($fee, $amount, Money::SCALE) > 0 ? $amount : $fee;

        if ($parcel !== null && $this->weOweTheFee($parcel) && $parcel->carrier_fee === null) {
            $warnings[] = [
                'code' => NawrisSettlementWarning::FeeUnknown,
                'message' => 'الأجرة على الشركة ولا نعرف قدرها — راجع المبلغ المستلم.',
            ];
        }

        if (array_diff_key($held, [$nawris => true]) !== []) {
            $warnings[] = [
                'code' => NawrisSettlementWarning::OtherCustody,
                'message' => 'للطلبية مال عند سائق أيضاً، وستنقله التسوية معها.',
            ];
        }

        if ($parcel !== null && $parcel->closed_at === null && $parcel->sync_failed_at !== null) {
            $warnings[] = [
                'code' => NawrisSettlementWarning::MoneyOutOfSync,
                'message' => 'آخر تعديل على المبلغ لم يصل النورس.',
            ];
        }

        if ($parcel !== null && $parcel->conflict_raised_at !== null && $parcel->conflict_resolved_at === null) {
            $warnings[] = [
                'code' => NawrisSettlementWarning::OpenConflict,
                'message' => 'على الطرد تعارض تسليم لم يُحسم.',
            ];
        }

        return $line->withMoney($amount, $fee, $held !== [], $warnings);
    }

    /**
     * ما تسأله شاشة «تم التسوية» عن هذه الطلبيات مجتمعة.
     *
     * **القائمة نفسها التي تسألها عن كل طلبية وحدها**، مجموعة بالمفتاح: فما يُفرض على الطلبية
     * المفردة يُفرض على الدفعة، ومفتاحٌ جديد في «إعدادات المالية» يصل إلى هنا بلا تعديل. وبدون
     * هذا كانت الدفعة تذهب إلى الحساب التلقائي بصمت، وهي التي يُفترض أن يُسأل عنها أكثر.
     *
     * @param  list<NawrisSettlementLine>  $lines
     * @return list<TransitionField>
     */
    private function fieldsFor(array $lines, ?User $actor): array
    {
        $merged = [];

        foreach ($lines as $line) {
            if (! $line->settles()) {
                continue;
            }

            // واحدة واحدة لا بمجموعة: `TransitionFields` يقرأ علاقات الطلبية، والوضع الصارم يرفض
            // ذلك من نموذج جاء ضمن مجموعة — وهذا مسار معاينة يُقرأ مرة لا مسار قائمة.
            $order = Order::query()->findOrFail((int) $line->orderId);

            foreach (TransitionFields::for($order, OrderStatus::Settled, $actor) as $field) {
                if ($field->type !== TransitionFieldType::TreasuryAccount) {
                    continue;
                }

                $entry = $merged[$field->key] ?? [
                    'field' => $field, 'required' => false, 'options' => [], 'values' => [], 'orders' => 0,
                ];

                $entry['required'] = $entry['required'] || $field->required;
                $entry['orders']++;
                $entry['values'][(string) $field->value] = true;

                foreach ($field->options as $option) {
                    $entry['options'][(string) $option['value']] = $option;
                }

                $merged[$field->key] = $entry;
            }
        }

        return array_values(array_map(function (array $entry): TransitionField {
            /** @var TransitionField $field */
            $field = $entry['field'];

            // اقتراح واحد يُفتح عليه؛ واختلافها يعني أن الاختيار للموظف.
            $agreed = count($entry['values']) === 1 ? array_key_first($entry['values']) : null;

            return TransitionField::treasuryAccount(
                key: $field->key,
                label: $field->label,
                accounts: array_values($entry['options']),
                hint: "تخصّ {$entry['orders']} طلبية",
                value: $agreed === null || $agreed === '' ? null : (string) $agreed,
                required: $entry['required'],
            );
        }, $merged));
    }
}
