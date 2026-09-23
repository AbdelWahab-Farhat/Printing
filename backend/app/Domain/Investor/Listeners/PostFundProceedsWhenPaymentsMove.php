<?php

declare(strict_types=1);

namespace App\Domain\Investor\Listeners;

use App\Domain\Investor\Actions\PostFundProceedsForOrder;
use App\Domain\Order\Events\OrderPaymentsRecalculated;

/**
 * كلَّما تحرّك مالُ طلبية، أُعيد حسابُ ما في خزينة الصندوق منها.
 *
 * الفعلُ يصحّح نفسه بالمقارنة، فلا يضرّ أن يصل هذا الحدثُ مرّتين ولا أن يصل عن طلبيةٍ لا تخصّ
 * الصندوق أصلاً — وهو ما يجعل الاستماعَ إلى معبرٍ عامّ أرخصَ من أربعة أحداثٍ خاصّة.
 */
final class PostFundProceedsWhenPaymentsMove
{
    public function __construct(private readonly PostFundProceedsForOrder $post) {}

    public function handle(OrderPaymentsRecalculated $event): void
    {
        ($this->post)($event->orderId);
    }
}
