<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Client;

use App\Application\Api\V1\Requests\Client\Shop\SaveClientShopRequest;
use App\Application\Api\V1\Resources\Client\ClientShopResource;
use App\Application\Controller;
use App\Domain\Customer\Actions\AddCustomerShop;
use App\Domain\Customer\Actions\RemoveCustomerShop;
use App\Domain\Customer\Actions\UpdateCustomerShop;
use App\Domain\Customer\DTOs\CustomerShopData;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * My shops
 *
 * متاجر العميل — يضيف منها ما يشاء، ومنها تختار السلةُ وجهةَ الطلبية.
 *
 * **لا مُعرِّفَ عميلٍ في أيّ مسار، ولا يُبحث عن متجرٍ بمُعرِّفه وحده.** {@see self::ownedShop()} يمرّ
 * بمتاجر صاحب التوكن، فمتجر غيره 404 لا صفٌّ يُفحص بعد جلبه — الضمان نفسه الذي يعطيه `scoped()`
 * لمسارات الموظفين، ولا جزءَ أبٍ في المسار هنا يُقيَّد به.
 */
class ShopController extends Controller
{
    use ResponseTrait;

    /** المجال والمدينة والمنطقة تُرسَل أسماؤها مع كل متجر، فتُحمَّل معه لا متجراً متجراً. */
    private const PLACE = ['businessField', 'city', 'region'];

    public function __construct(
        private readonly AddCustomerShop $addShop,
        private readonly UpdateCustomerShop $updateShop,
        private readonly RemoveCustomerShop $removeShop,
    ) {}

    /**
     * My shops
     *
     * بترتيب إضافتها: الأول هو الذي فُتح به الحساب. بلا صفحات — متاجر العميل بضعةٌ لا مئات.
     */
    public function index(Request $request): JsonResponse
    {
        $shops = $this->customer($request)->shops()->with(self::PLACE)->orderBy('id')->get();

        return $this->success(ClientShopResource::collection($shops));
    }

    /**
     * Add a shop
     *
     * يُضاف بجانب ما عند العميل ولا يحلّ محلّه.
     */
    public function store(SaveClientShopRequest $request): JsonResponse
    {
        $shop = ($this->addShop)(
            $this->customer($request),
            CustomerShopData::fromArray($request->validated()),
        );

        return $this->created(new ClientShopResource($shop->load(self::PLACE)), 'تمت إضافة المتجر');
    }

    /**
     * Edit a shop
     *
     * المتجر كاملاً كما يعرضه النموذج: الاسم ومجال العمل والمدينة والمنطقة ورابط الصفحة. والإحداثيات
     * وحدها تبقى كما هي، لأن التطبيق لا يرسلها.
     */
    public function update(SaveClientShopRequest $request, int $shop): JsonResponse
    {
        $updated = ($this->updateShop)(
            $this->ownedShop($request, $shop),
            CustomerShopData::fromArray($request->validated()),
        );

        return $this->success(new ClientShopResource($updated->load(self::PLACE)), 'تم تعديل المتجر');
    }

    /**
     * Remove a shop
     *
     * يُخفى من القائمة، والطلبيات التي ذهبت إليه تبقى تسمّيه.
     */
    public function destroy(Request $request, int $shop): JsonResponse
    {
        ($this->removeShop)($this->ownedShop($request, $shop));

        return $this->successMessage('تم حذف المتجر');
    }

    /**
     * متجرٌ من متاجر *هذا* العميل، أو 404 — عبر علاقته لا بالمُعرِّف وحده.
     */
    private function ownedShop(Request $request, int $shopId): CustomerShop
    {
        /** @var CustomerShop */
        return $this->customer($request)->shops()->findOrFail($shopId);
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
