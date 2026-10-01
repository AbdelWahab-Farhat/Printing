<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Exceptions\EntryCannotBeReversed;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * يعكس مصروفاً على صفقةٍ أو على الصندوق — بصفٍّ عكسيّ يحمل مبلغَه كما هو، لا بتعديله ولا بحذفه.
 *
 * ## ثلاثةُ دفاتر كتب فيها المصروف، فعكسُه يعكسها الثلاثة
 *
 * ```
 * الخزينة         ←  مرآةُ حركته على الحساب الذي دفع
 * محافظُ الشركاء  ←  ما حُمِّلوه يرجع إليهم
 * نقدُ الصندوق     ←  ما خرج منه يعود إليه — مصروفُ الصندوق وحده
 * ```
 *
 * بأبوابها هي: {@see TreasuryService::reverseSource()}، و{@see PostDealShare} بصفر كما يفعل
 * {@see UnwindDealEarningsForOrder}، و{@see RecordCashEntry::reverse()}.
 *
 * **والفتراتُ على قاعدتها:** عكسُ ما حُمِّل للشركاء يقع في فترة المصروف ما دامت تقبل القيد، وإلا
 * في المفتوحة اليوم — {@see PostDealShare} يمرّ بـ`PeriodForEntry::floorOf()`، وحارسُ
 * `InvestorWalletEntry` يمنع أيّ صفٍّ في فترةٍ أُقفلت.
 *
 * **والزوجُ يسقط من كل مجموع:** `InvestorDealExpense::isDeducted()` لا يعدّ عكساً ولا ما عُكس،
 * و`CloseInvestmentPeriod::expensesOf()` كذلك.
 *
 * ولا يُعكس العكس، ولا يُعكس مصروفٌ مرّتين (والفهرسُ الفريد على `reverses_expense_id` حارسٌ أخير)،
 * ولا مصروفٌ داخل تكلفة البضاعة — لم يُحمَّل على أحد ولم يخرج به مال — ولا مصروفٌ على صفقةٍ انتهت.
 */
final class ReverseDealExpense
{
    public function __construct(
        private readonly PostDealShare $postShare,
        private readonly RecordCashEntry $cash,
        private readonly TreasuryService $treasury,
    ) {}

    /**
     * @throws EntryCannotBeReversed
     */
    public function __invoke(
        InvestorDealExpense $expense,
        string $reason,
        ?int $actorId,
    ): InvestorDealExpense {
        return DB::transaction(function () use ($expense, $reason, $actorId): InvestorDealExpense {
            // الصفقةُ أولاً ثم الصفّ — ترتيبُ الأقفال الواحد في هذا السياق.
            $deal = InvestorDeal::query()
                ->whereKey($expense->investor_deal_id)
                ->lockForUpdate()
                ->firstOrFail();
            $original = InvestorDealExpense::query()
                ->whereKey($expense->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            $this->guard($deal, $original);

            $reversal = new InvestorDealExpense([
                'kind' => $original->kind,
                'name' => $original->name,
                'amount' => (string) $original->amount,
                // يومُ التصحيح لا يومُ الخطأ: التصحيحُ حدثٌ وقع الآن.
                'incurred_on' => now()->toDateString(),
                'notes' => $reason,
            ]);

            $reversal->investor_deal_id = $deal->getKey();
            $reversal->is_landed = false;
            $reversal->reverses_expense_id = $original->getKey();
            $reversal->recorded_by = $actorId;
            // الحسابُ الذي دفع، فالمالُ يعود إليه. ومصروفٌ من قبل الخزينة لا حسابَ له: احتُسب
            // مالُه في الرصيد الافتتاحي، فيعود إلى الخزنة (TREASURY-DESIGN §١١).
            $reversal->treasury_account_id = $original->treasury_account_id
                ?? $this->treasury->accountFor('cash', null, incoming: false)->getKey();
            $reversal->save();

            $this->returnTheMoney($original, $reversal, $reason, $actorId);
            $this->returnTheFundCash($original, $reason, $actorId);

            // ما حُمِّل للشركاء يرجع: الهدفُ صفر، و`PostDealShare` يعكس كلَّ صفٍّ قائمٍ لمصدره.
            ($this->postShare)(
                $deal,
                '0.00',
                AuditSubject::InvestorDealExpense->value,
                (int) $original->getKey(),
                'عكس مصروف: '.$reason,
            );

            return $reversal;
        });
    }

    /**
     * @throws EntryCannotBeReversed
     */
    private function guard(InvestorDeal $deal, InvestorDealExpense $original): void
    {
        if ($original->isReversal()) {
            throw EntryCannotBeReversed::make(
                'هذا الصفّ عكسٌ لمصروف — يُعكس المصروفُ الأصلي لا عكسُه'
            );
        }

        if ($original->isReversed()) {
            throw EntryCannotBeReversed::make('هذا المصروف معكوسٌ من قبل');
        }

        if ($original->is_landed) {
            throw EntryCannotBeReversed::make(
                'هذا المصروف داخل تكلفة البضاعة — لم يُحمَّل على أحد ولم يخرج به مال'
            );
        }

        if ($deal->status->isFinished()) {
            throw EntryCannotBeReversed::make(
                "الصفقة {$deal->code} «{$deal->status->label()}» ولا تقبل حركات مالية جديدة"
            );
        }
    }

    /** مرآةُ ما خرج من الحساب — أو، لمصروفٍ من قبل الخزينة، حركةٌ تعيده إلى الخزنة. */
    private function returnTheMoney(
        InvestorDealExpense $original,
        InvestorDealExpense $reversal,
        string $reason,
        ?int $actorId,
    ): void {
        $mirrored = $this->treasury->reverseSource(
            $original->getMorphClass(),
            (int) $original->getKey(),
            $reason,
            $actorId,
        );

        if ($mirrored !== [] || $original->treasury_account_id !== null) {
            return;
        }

        $this->treasury->post(new MovementData(
            accountId: (int) $reversal->treasury_account_id,
            direction: MovementDirection::In,
            kind: MovementKind::Expense,
            amount: (string) $reversal->amount,
            occurredAt: now(),
            sourceType: $reversal->getMorphClass(),
            sourceId: (int) $reversal->getKey(),
            notes: $reason,
            recordedBy: $actorId,
        ));
    }

    /** صفُّ نقد الصندوق الذي كتبه المصروف — مصروفُ الصندوق وحده يكتبه. */
    private function returnTheFundCash(
        InvestorDealExpense $original,
        string $reason,
        ?int $actorId,
    ): void {
        $standing = InvestmentCashEntry::query()
            ->where('source_type', AuditSubject::InvestorDealExpense->value)
            ->where('source_id', $original->getKey())
            ->whereDoesntHave('reversedBy')
            ->get();

        foreach ($standing as $entry) {
            $this->cash->reverse($entry, $actorId, $reason);
        }
    }
}
