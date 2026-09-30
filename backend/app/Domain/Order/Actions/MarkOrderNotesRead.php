<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Models\Order;

/**
 * يقدّم مؤشّر قراءة العميل لملاحظات طلبيته، كما يقدّم `MarkTicketRead` مؤشّره في الدعم.
 *
 * **إلى آخر ملاحظةٍ عُرضت عليه، لا إلى «الآن».** الشاشة تقرأ الملاحظات ثم يتحرّك المؤشّر؛
 * وملاحظةٌ كُتبت بين الاثنين لم تكن على الشاشة، فلا تُعلَّم مقروءة.
 *
 * **ولا يرجع إلى الوراء.** قراءةٌ أبطأ حملت ملاحظاتٍ أقل قد تصل بعد قراءةٍ أحدث، فلا تمحو ما قُرئ.
 *
 * **والقراءة ليست تعديلاً للطلبية**: تُحفظ بلا أحداث — فلا سطر في سجلّها — وبلا `updated_at`،
 * التي تعني عند الموظفين أن شيئاً في الطلبية تغيّر.
 */
final class MarkOrderNotesRead
{
    public function __invoke(Order $order, ?int $upToTransitionId): void
    {
        $before = $order->customer_read_transition_id;
        $after = max((int) $before, (int) $upToTransitionId);

        if ($after === 0 || $after === $before) {
            return;
        }

        Order::withoutTimestamps(
            fn () => $order->forceFill(['customer_read_transition_id' => $after])->saveQuietly(),
        );
    }
}
