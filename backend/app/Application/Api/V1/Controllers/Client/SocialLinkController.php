<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Client;

use App\Application\Api\V1\Requests\Client\SocialLink\SaveClientSocialLinksRequest;
use App\Application\Api\V1\Resources\Client\ClientSocialLinkResource;
use App\Application\Controller;
use App\Domain\Customer\Actions\SyncCustomerSocialLinks;
use App\Domain\Customer\DTOs\CustomerSocialLinkData;
use App\Domain\Customer\Models\Customer;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * My social links
 *
 * روابط التواصل للعميل — صفحاته على فيسبوك وإنستغرام وغيرها — يقرؤها ويحفظها من «حسابي».
 *
 * **لا مُعرِّفَ عميلٍ في أيّ مسار.** الروابط روابطُ صاحب التوكن، ومُعرِّف رابطٍ لغيره يردّه
 * {@see SaveClientSocialLinksRequest} قبل أن يصل إلى المزامنة.
 */
class SocialLinkController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly SyncCustomerSocialLinks $syncLinks) {}

    /**
     * My social links
     *
     * بترتيب إضافتها، وبلا صفحات — عشرةٌ على الأكثر.
     */
    public function index(Request $request): JsonResponse
    {
        return $this->success(ClientSocialLinkResource::collection($this->customer($request)->socialLinks));
    }

    /**
     * Save my social links
     *
     * المجموعة كلّها: رابطٌ بمُعرِّفه يُعدَّل، وبلا مُعرِّف يُضاف، وما غاب يُحذف. وقائمةٌ فارغة تحذفها كلّها.
     */
    public function update(SaveClientSocialLinksRequest $request): JsonResponse
    {
        $customer = $this->customer($request);

        /** @var array<int, array<string, mixed>> $links */
        $links = $request->validated('social_links');

        ($this->syncLinks)($customer, CustomerSocialLinkData::listFromArray($links));

        return $this->success(
            ClientSocialLinkResource::collection($customer->socialLinks()->get()),
            'تم حفظ الروابط',
        );
    }

    /**
     * The signed-in customer, narrowed from the guard's contract to the model. The route group's
     * `auth:customer` middleware is what makes the assertion true.
     */
    private function customer(Request $request): Customer
    {
        $customer = $request->user();

        assert($customer instanceof Customer);

        return $customer;
    }
}
