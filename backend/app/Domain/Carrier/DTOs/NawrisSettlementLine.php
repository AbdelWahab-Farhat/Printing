<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use App\Domain\Carrier\Enums\NawrisSettlementRejection;
use App\Domain\Carrier\Enums\NawrisSettlementWarning;
use App\Domain\Order\Enums\OrderStatus;

/**
 * قرار طلبية واحدة. الصف المركّب يصير عدة أسطر، لكلٍّ نتيجته ورقم صفه نفسه.
 */
final readonly class NawrisSettlementLine
{
    /**
     * @param  list<array{code: NawrisSettlementWarning, message: string}>  $warnings
     */
    public function __construct(
        public NawrisSettlementRow $row,
        public NawrisSettlementOutcome $outcome,
        public ?int $orderId = null,
        public ?string $orderCode = null,
        public ?OrderStatus $previousStatus = null,
        public ?NawrisSettlementRejection $rejection = null,
        public ?string $reason = null,
        public array $warnings = [],
        /** ما عند النورس لهذه الطلبية — صفر لغير ما سيُسوّى. */
        public string $heldAmount = '0.00',
        /** أجرة النورس المعروفة عليها، حين تكون الأجرة علينا. */
        public string $knownFee = '0.00',
        /** لها مال في عهدةٍ ما — ما يُسأل عنه «استُلم المال في» على شاشة الطلبية. */
        public bool $holdsCustody = false,
    ) {}

    public function settles(): bool
    {
        return $this->outcome === NawrisSettlementOutcome::Settled;
    }

    /** تركها الموظف. يبقى ما عند النورس لها ظاهراً في السطر، ولا يدخل مجموع ما يُسوّى. */
    public function leftOut(): self
    {
        return new self(
            row: $this->row,
            outcome: NawrisSettlementOutcome::LeftOut,
            orderId: $this->orderId,
            orderCode: $this->orderCode,
            previousStatus: $this->previousStatus,
            reason: 'مالها لم يصل بعد — تبقى «تم الاستلام» وعهدتها عند النورس.',
            warnings: $this->warnings,
            heldAmount: $this->heldAmount,
            knownFee: $this->knownFee,
            holdsCustody: $this->holdsCustody,
        );
    }

    /**
     * @param  list<array{code: NawrisSettlementWarning, message: string}>  $warnings
     */
    public function withMoney(string $held, string $knownFee, bool $holdsCustody, array $warnings): self
    {
        return new self(
            row: $this->row,
            outcome: $this->outcome,
            orderId: $this->orderId,
            orderCode: $this->orderCode,
            previousStatus: $this->previousStatus,
            rejection: $this->rejection,
            reason: $this->reason,
            warnings: [...$this->warnings, ...$warnings],
            heldAmount: $held,
            knownFee: $knownFee,
            holdsCustody: $holdsCustody,
        );
    }
}
