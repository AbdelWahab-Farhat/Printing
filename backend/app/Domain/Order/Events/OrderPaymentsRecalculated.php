<?php

declare(strict_types=1);

namespace App\Domain\Order\Events;

use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Order\Actions\RecalculateOrderPayments;

/**
 * تغيّر ما حُصِّل من طلبية.
 *
 * يُطلق من {@see RecalculateOrderPayments} — **المكانُ الوحيد الذي
 * يُكتب فيه `orders.paid_amount`** — فيمرّ به كلُّ طريقٍ يحرّك مالَ طلبية: دفعةٌ تُسجَّل، ودفعةٌ
 * تُعكَس، ومبلغٌ يُشطب، وتسويةُ ناقل. وحدثٌ واحدٌ هناك يغني عن أربعةٍ عند كلٍّ منها، ولا يمكن أن
 * يُنسى في الخامس.
 *
 * ومن يستمع إليه في نطاق المستثمرين يحرّك **خزينة الصندوق**: النقدُ يدخل عند التحصيل لا عند
 * التسليم — {@see CashEntryType}.
 */
final class OrderPaymentsRecalculated
{
    public function __construct(public int $orderId) {}
}
