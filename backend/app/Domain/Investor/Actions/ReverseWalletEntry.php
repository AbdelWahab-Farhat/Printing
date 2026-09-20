<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\UnitEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\EntryCannotBeReversed;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\PeriodForEntry;
use Illuminate\Support\Facades\DB;

/**
 * يُبطل حركةً في محفظة مستثمر — **وكلَّ ما تبعها**.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٠ب. الصلاحيةُ
 * ومؤشّرُ `can_be_reversed` كانا معرَّفَين منذ البداية بلا مسارٍ خلفهما: يظهر الزرُّ على الشاشة
 * ولا يفعل شيئاً.
 *
 * ## ثلاثةُ دفاتر يُبطَل فيها، أو لا يُبطَل شيء
 *
 * إيداعٌ واحد يكتب في ثلاثة ({@see DepositToFund})، فإبطالُه يبطلها الثلاثة:
 *
 * ```
 * المحفظة  ←  reversal   يحمل مبلغَ الأصل كما هو
 * الخزينة  ←  reversal   نقدٌ لم يدخل بعد كل شيء
 * الوحدات  ←  reversal   ونسبتُه ترجع كما كانت
 * ```
 *
 * **والوحداتُ هي الخطر.** إبطالُ الإيداع بلا إبطال وحداته يترك رجلاً استُرجع مالُه وبقيت نسبتُه
 * تقاسم ربحاً لا يموّله — ولا يظهر في رصيدٍ واحد: كلُّ رقمٍ يبقى «صحيحاً» ويُقسَّم الربحُ على
 * قاسمٍ كاذب.
 *
 * ## وأيّها يُعكس
 *
 * {@see InvestorWalletEntry::isReversible()} وحدها تقرّر — «ما يُكتب بيدٍ يُعكس بيد». الربحُ
 * والخسارةُ يُبطلهما تغيُّرُ الطلبية التي صنعتهما ({@see PostDealShare})، فلا يُبطَلان من شاشة:
 * الدفترُ والطلبيةُ لا يجوز أن يقولا شيئين.
 *
 * ## وفي أيّ فترةٍ يقع
 *
 * في فترة الأصل ما دامت مفتوحة، وإلا ففي المفتوحة اليوم — {@see PeriodForEntry::floorOf()}.
 * فسبتمبرُ المغلق لا تدخله حركةٌ، وتصحيحُه يقع على الحاضر كما تفعل المحاسبةُ في كل مكان.
 */
final class ReverseWalletEntry
{
    public function __construct(
        private readonly PeriodForEntry $periodFor,
        private readonly RecordCashEntry $cash,
    ) {}

    /**
     * @throws EntryCannotBeReversed
     */
    public function __invoke(InvestorWalletEntry $entry, ?int $actorId, ?string $notes = null): InvestorWalletEntry
    {
        return DB::transaction(function () use ($entry, $actorId, $notes): InvestorWalletEntry {
            $locked = InvestorWalletEntry::query()->whereKey($entry->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->type === WalletEntryType::Reversal) {
                throw EntryCannotBeReversed::make('عكسُ عكسٍ متاهةٌ بلا أرضية — الحركةُ الأصلية هي التي تُعكَس');
            }

            if (! $locked->type->isRecordableByHand()) {
                throw EntryCannotBeReversed::make(
                    'هذه الحركة يكتبها النظام عند تسليم الطلبيات أو عند إقفال الفترة، وتُبطَل بتغيير ما صنعها'
                );
            }

            if ($locked->isReversed()) {
                throw EntryCannotBeReversed::make('هذه الحركة أُبطلت من قبل');
            }

            $reversal = new InvestorWalletEntry([
                'amount' => (string) $locked->amount,
                'occurred_at' => now(),
                'notes' => $notes,
            ]);

            $reversal->investor_id = $locked->investor_id;
            $reversal->investor_deal_id = $locked->investor_deal_id;
            $reversal->investment_period_id = $this->periodFor->floorOf(
                $locked->investment_period_id === null ? null : (int) $locked->investment_period_id
            );
            $reversal->type = WalletEntryType::Reversal;
            $reversal->reverses_entry_id = $locked->getKey();
            $reversal->recorded_by = $actorId;
            $reversal->save();

            $this->undoCash($locked, $actorId, $notes);
            $this->undoUnits($locked, $actorId);

            return $reversal;
        });
    }

    /** الصفُّ الذي دخل الخزينة بسبب هذا الصفّ — إن دخل. */
    private function undoCash(InvestorWalletEntry $entry, ?int $actorId, ?string $notes): void
    {
        $cashRows = InvestmentCashEntry::query()
            ->where('source_type', AuditSubject::InvestorWalletEntry->value)
            ->where('source_id', $entry->getKey())
            ->whereDoesntHave('reversedBy')
            ->get();

        foreach ($cashRows as $row) {
            $this->cash->reverse($row, $actorId, $notes ?? 'إبطال حركة محفظة');
        }
    }

    /** والوحداتُ التي اشتراها أو ألغاها — الطرفُ الذي لا يُرى في أيّ رصيد. */
    private function undoUnits(InvestorWalletEntry $entry, ?int $actorId): void
    {
        $rows = InvestmentUnit::query()
            ->where('source_type', AuditSubject::InvestorWalletEntry->value)
            ->where('source_id', $entry->getKey())
            ->whereDoesntHave('reversedBy')
            ->get();

        foreach ($rows as $row) {
            $reversal = new InvestmentUnit;
            $reversal->investor_id = $row->investor_id;
            $reversal->investment_period_id = $row->investment_period_id;
            $reversal->type = UnitEntryType::Reversal;
            $reversal->units = (string) $row->units;
            $reversal->unit_price = (string) $row->unit_price;
            $reversal->amount = (string) $row->amount;
            $reversal->reverses_unit_entry_id = $row->getKey();
            $reversal->occurred_at = now();
            $reversal->recorded_by = $actorId;
            $reversal->save();
        }
    }
}
