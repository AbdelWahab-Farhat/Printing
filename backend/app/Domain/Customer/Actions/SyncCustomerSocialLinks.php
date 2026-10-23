<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\DTOs\CustomerSocialLinkData;
use App\Domain\Customer\Exceptions\SocialLinkDoesNotBelongToCustomer;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerSocialLink;
use Illuminate\Support\Facades\DB;

/**
 * يجعل روابط العميل مطابقةً للمجموعة المُرسَلة تماماً، كما تفعل {@see SyncCustomerShops} بمحلاته:
 * رابطٌ بمُعرِّفه يُعدَّل، وبلا مُعرِّف يُضاف، وما غاب عن المجموعة يُحذف حذفاً ناعماً.
 *
 * في معاملةٍ واحدة لأن العميل يحفظها من شاشته دفعةً واحدة: إمّا أن تُحفظ كلّها أو لا شيء. ونداؤها
 * من داخل معاملة `UpdateCustomer` نقطةُ حفظٍ داخلها لا معاملةٌ ثانية.
 */
final class SyncCustomerSocialLinks
{
    /**
     * @param  list<CustomerSocialLinkData>  $links
     */
    public function __invoke(Customer $customer, array $links): void
    {
        DB::transaction(function () use ($customer, $links): void {
            $keptIds = [];

            foreach ($links as $link) {
                if ($link->id !== null) {
                    // عبر العلاقة، فرابطُ عميلٍ آخر لا يُعثر عليه هنا أصلاً.
                    $existing = $customer->socialLinks()->whereKey($link->id)->first();

                    if ($existing === null) {
                        throw SocialLinkDoesNotBelongToCustomer::make($link->id, (int) $customer->getKey());
                    }

                    // رابطٌ لم يتغيّر لا يكتب شيئاً ولا يترك أثراً في السجل.
                    $existing->update(['url' => $link->url]);
                    $keptIds[] = $existing->getKey();

                    continue;
                }

                $keptIds[] = $customer->socialLinks()->create(['url' => $link->url])->getKey();
            }

            // واحداً واحداً لا حذفاً جماعياً: الحذف الجماعي لا يطلق أحداث النموذج، فيختفي الرابط
            // ولا يقول السجل إنه كان.
            $customer->socialLinks()
                ->whereKeyNot($keptIds)
                ->each(fn (CustomerSocialLink $link) => $link->delete());
        });
    }
}
