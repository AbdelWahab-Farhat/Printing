<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Investor\Support\Money;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * بضاعةُ الصندوق التي ما زالت على الرفّ — رقمُ اللوحة، وموادُّه التي يتكوّن منها.
 *
 * «بضاعة على الرفّ أريد معرفة ماهي هذه البضاعة» — طلبُ المالك 2026-09-24. الرقمُ وحده لا يقول
 * أهو ألفُ كيسٍ أم طنُّ رول، ومن يقرأ «١٢٬٢١٦» يحتاج أن يعرف ماذا يملك الصندوق ليبيعه.
 *
 * **والرقمُ والقائمةُ من الطبقات نفسِها** ({@see batches()}): {@see FundValuation} يجمعها،
 * والقائمةُ تجمعها مادّةً مادّة، فلا تبلغ القائمةُ غيرَ ما في اللوحة.
 *
 * **بالتكلفة المجمّدة يوم وصلت** (`unit_cost` على الطبقة) — كلُّ أصلٍ في الصندوق يدخل بتكلفته.
 */
final class FundShelfStock
{
    /**
     * ما يساويه الرفُّ بالتكلفة — بندُ اللوحة.
     *
     * @param  int|null  $dealId  صفقةٌ بعينها، أو كلُّ ما موّله مستثمرون
     */
    public function value(?int $dealId = null): string
    {
        return (string) ($this->batches($dealId)->sum(DB::raw('b.quantity_remaining * b.unit_cost')) ?? '0');
    }

    /**
     * الرفُّ مادّةً مادّة: كمّيتُها ووحدتُها وتكلفتُها، الأغلى أوّلاً.
     *
     * **والمجموعُ يُقرأ من {@see value()} لا من جمع الصفوف.** الكمّيةُ بثلاث خاناتٍ والتكلفةُ
     * بثلاث، فحاصلُ ضربهما بستٍّ — وتقريبُ كلِّ مادّةٍ وحدها ثم جمعُها قد يبتعد قرشاً عن تقريب
     * المجموع. فالمجموعُ هو رقمُ اللوحة بعينه، والصفوفُ مقرَّبةٌ كلٌّ لنفسه.
     *
     * @return array{total: string, materials: list<array<string, mixed>>}
     */
    public function __invoke(): array
    {
        $rows = $this->batches(null)
            ->leftJoin('stock_items as si', 'si.id', '=', 'b.stock_item_id')
            // طبقةٌ فرغت لا تساوي شيئاً على الرفّ؛ وسالبةٌ — لو وُجدت — تبقى، فالمجموعُ يحسبها.
            ->where('b.quantity_remaining', '<>', 0)
            ->groupBy('b.stock_item_id', 'si.code', 'si.name', 'si.unit')
            ->orderByRaw('sum(b.quantity_remaining * b.unit_cost) desc')
            ->orderBy('si.name')
            ->get([
                'b.stock_item_id',
                'si.code',
                'si.name',
                'si.unit',
                DB::raw('sum(b.quantity_remaining) as quantity'),
                DB::raw('sum(b.quantity_remaining * b.unit_cost) as value'),
                DB::raw('count(*) as batches'),
            ]);

        $materials = [];

        foreach ($rows as $row) {
            $unit = PricingUnit::tryFrom((string) $row->unit);

            $materials[] = [
                'stock_item_id' => $row->stock_item_id === null ? null : (int) $row->stock_item_id,
                'code' => $row->code === null ? null : (string) $row->code,
                'name' => $row->name === null ? null : (string) $row->name,
                'unit' => $unit?->value,
                'unit_label' => $unit?->label(),
                'quantity' => (string) $row->quantity,
                'value' => Money::round((string) $row->value),
                'batches' => (int) $row->batches,
            ];
        }

        return [
            'total' => Money::round($this->value()),
            'materials' => $materials,
        ];
    }

    /** طبقاتُ المستثمرين القائمة — ما موّله الصندوقُ أو صفقةٌ قديمة. */
    private function batches(?int $dealId): Builder
    {
        return DB::table('stock_batches as b')
            ->whereNotNull('b.investor_deal_id')
            ->when($dealId !== null, fn ($q) => $q->where('b.investor_deal_id', $dealId))
            ->whereNull('b.deleted_at');
    }
}
