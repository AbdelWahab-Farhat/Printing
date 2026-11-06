<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * تحرّكت محفظتك — لصاحبها وحده.
 *
 * **بلا مبلغ**: الدفعُ يُقرأ على شاشةٍ مقفلة، وما في محفظة موظف ليس شأن من يقف بجانب هاتفه. الرقمُ
 * في «محفظتي» بعد الفتح، كما تفعل {@see DesignTicketCommentPosted} بنصّ التعليق.
 */
final readonly class EmployeeWalletMovedForYou implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::user((int) ($payload['employee_id'] ?? 0));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $added = (bool) ($payload['is_credit'] ?? false);

        return new RenderedNotification(
            title: match ((string) ($payload['type'] ?? '')) {
                'withdrawal' => 'تم سحب مبلغ من محفظتك',
                'reversal' => 'أُلغيت حركة على محفظتك',
                default => $added ? 'أُضيف مبلغ إلى محفظتك' : 'خُصم مبلغ من محفظتك',
            },
            body: 'اضغط لعرض رصيدك',
            route: '/my-wallet',
        );
    }

    /** مَن حرّك محفظته بنفسه — المدير — لا يحتاج أن يُخبَر بما فعل. */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
