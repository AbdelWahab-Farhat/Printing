<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Exceptions\DesignTicketPayIsNotYours;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * يكتب «أجر التصميم» أو يمحوه — SERVICE-PAY-DESIGN §٣.
 *
 * **تحت قفل التذكرة**، القفلِ نفسه الذي يأخذه الاعتماد: لا يُكتب الأجر والتذكرة تُغلق، فلا يكتمل بمبلغٍ
 * ويُعرض مبلغٌ غيره. وبعد الإغلاق لا يتغيّر: ما دخل المحفظة يُصحَّح من المحفظة.
 */
final class SetDesignTicketPay
{
    /**
     * @throws DesignTicketIsClosed
     * @throws DesignTicketPayIsNotYours
     */
    public function __invoke(DesignTicket $ticket, ?string $pay, User $actor): DesignTicket
    {
        return DB::transaction(function () use ($ticket, $pay, $actor): DesignTicket {
            DesignTicket::query()->whereKey($ticket->getKey())->lockForUpdate()->firstOrFail();

            $ticket->refresh();

            if (! $ticket->isOpen()) {
                throw DesignTicketIsClosed::make($ticket->status);
            }

            if (! $ticket->mayWritePay($actor)) {
                throw DesignTicketPayIsNotYours::make();
            }

            $ticket->forceFill(['designer_pay' => $pay])->save();

            return $ticket;
        });
    }
}
