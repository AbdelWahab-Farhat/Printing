<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * What an investor sees when he signs in, and the whole of it.
 *
 * Four figures and his deals. **No order, no customer, no unit cost, and no other investor's
 * share** — «لا يستطيع فعل أي شيء آخر» is enforced by there being exactly one endpoint he can
 * reach and this being everything on it.
 *
 * The two profit figures are kept apart on purpose, because they answer different questions.
 * `profit_in_deals` is what his running deals have earned him so far and it moves with every
 * delivery; `profit_available` is what has been released to his wallet by a deal closing, and it
 * is the only money he can actually ask for. Showing one number for both would either promise
 * him money he cannot have yet or hide money he has already made.
 *
 * @mixin \stdClass
 */
class InvestorPortfolioResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var array<string, mixed> $data */
        $data = $this->resource;

        return [
            'investor' => $data['investor'],

            // His money with the company, not yet committed to anything.
            'capital_in_wallet' => $data['capital_in_wallet'],
            // His money currently financing goods on a shelf.
            'capital_in_deals' => $data['capital_in_deals'],
            'capital_total' => $data['capital_total'],

            // **الأرقامُ الثلاثة — §٠.٨، ثلاثُ بوّاباتٍ متتابعة.** الأوّلُ لطلبياتٍ بلغت «جاهزة» ولم
            // تُسلَّم: محسوبٌ بالقسمة التي سيقيّده بها التسليم، ولا صفَّ له. ومعه عددُ طلبياته.
            'profit_awaiting_delivery' => $data['profit_awaiting_delivery'],
            'orders_awaiting_delivery' => $data['orders_awaiting_delivery'],
            // سُلِّمت فقُيِّد — له، ولا يُسحب حتى تنقضي فترتُها وتُحصَّل طلبيتُها.
            'profit_in_deals' => $data['profit_in_deals'],
            // اجتمع شرطاه فأُفرِج عنه، ويُسحب.
            'profit_available' => $data['profit_available'],
            'profit_withdrawn' => $data['profit_withdrawn'],

            'deals' => $data['deals'],

            // **الشريحة ٨**: شريكُ الصندوق لا صفَّ له في `deals` — نصيبُه وحداتٌ في دفترٍ
            // آخر. وبدونه كان يفتح البوابةَ فيرى صفراً وماله في الصندوق.
            'fund' => $data['fund'],
        ];
    }
}
