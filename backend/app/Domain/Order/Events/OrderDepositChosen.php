<?php

declare(strict_types=1);

namespace App\Domain\Order\Events;

use Illuminate\Foundation\Events\Dispatchable;

/**
 * اختار العميلُ عربونَ طلبيةٍ قُبلت بعد المراجعة — في المكتب، أو دفعه من محفظته (2026-10-19).
 *
 * **حدثٌ لا انتقالٌ وحده.** {@see OrderStatusChanged} يُطلَق أيضاً، لكن «انتظار العربون» و«عربون
 * مدفوع» صامتان هناك عمداً (حركتا المكتب على شاشته). هذه حركةُ العميل، والموظفون لا يرونها إلا إن
 * قيل لهم — فلها حدثُها، يعلن ولا يعرف من يسمع، كجيرانه.
 */
final readonly class OrderDepositChosen
{
    use Dispatchable;

    public function __construct(public int $orderId) {}
}
