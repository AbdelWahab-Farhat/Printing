<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use App\Domain\Order\DTOs\TransitionField;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Support\Money;

/**
 * قرار الملف كله، بلا كتابة حرف واحد. المعاينة تعرضه، والتنفيذ يعيد حسابه تحت القفل ويقارنه.
 */
final readonly class NawrisSettlementPreview
{
    /**
     * @param  list<NawrisSettlementLine>  $lines
     * @param  list<TransitionField>  $fields  ما تسأله شاشة «تم التسوية» عن هذه الطلبيات مجتمعة
     */
    public function __construct(
        public int $rowsCount,
        public array $lines,
        public array $fields = [],
    ) {}

    /**
     * @return list<NawrisSettlementLine>
     */
    public function settling(): array
    {
        return array_values(array_filter($this->lines, fn (NawrisSettlementLine $line) => $line->settles()));
    }

    /**
     * بترتيب المعرّف: ترتيب القفل في كل مسار مال، وعليه يقوم عدم تعارض دفعتين.
     *
     * @return list<int>
     */
    public function settlingOrderIds(): array
    {
        $ids = array_map(fn (NawrisSettlementLine $line) => (int) $line->orderId, $this->settling());
        sort($ids);

        return $ids;
    }

    /**
     * المعاينة نفسها بعد أن ترك الموظف [$orderIds].
     *
     * تُحسب البصمة قبل هذا لا بعده: الترك قرار الموظف، والبصمة تقول ما وعد به الملف. والسطر المكرر
     * يُترك مع أصله، وإلا قال «تُسوّى في سطر سابق» عن طلبية لن تُسوّى.
     *
     * @param  list<int>  $orderIds
     */
    public function leaving(array $orderIds): self
    {
        return new self(
            rowsCount: $this->rowsCount,
            lines: array_map(function (NawrisSettlementLine $line) use ($orderIds): NawrisSettlementLine {
                $mine = in_array($line->orderId, $orderIds, true);

                return $mine && $line->previousStatus !== OrderStatus::Settled ? $line->leftOut() : $line;
            }, $this->lines),
            fields: $this->fields,
        );
    }

    public function count(NawrisSettlementOutcome $outcome): int
    {
        return count(array_filter($this->lines, fn (NawrisSettlementLine $line) => $line->outcome === $outcome));
    }

    public function warningsCount(): int
    {
        return count(array_filter($this->lines, fn (NawrisSettlementLine $line) => $line->warnings !== []));
    }

    public function totalHeld(): string
    {
        return Money::sum('0', ...array_map(fn (NawrisSettlementLine $line) => $line->heldAmount, $this->settling()));
    }

    public function knownFees(): string
    {
        return Money::sum('0', ...array_map(fn (NawrisSettlementLine $line) => $line->knownFee, $this->settling()));
    }

    /** الرقم الذي تفتح به خانة «المبلغ المستلم»: ما عند النورس بعد أجرته المعروفة. */
    public function expectedReceived(): string
    {
        return Money::round(bcsub($this->totalHeld(), $this->knownFees(), 8));
    }

    /**
     * بصمة ما وعدت به المعاينة: أيّ الطلبيات تُسوّى وكم عند النورس لكلٍّ منها.
     *
     * المبلغ الذي يكتبه الموظف مكتوب لهذه المجموعة تحديداً، فإن تغيّرت بين المعاينة والتنفيذ
     * صار تقسيم الفرق على طلبيات لم يرها، ويُرفض التنفيذ.
     */
    public function fingerprint(): string
    {
        $parts = array_map(
            fn (NawrisSettlementLine $line) => $line->orderId.':'.$line->heldAmount,
            $this->settling(),
        );

        sort($parts);

        return hash('sha256', implode('|', $parts));
    }
}
