<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\SocialLink;

use App\Application\Api\V1\Requests\Customer\StoreCustomerRequest;
use App\Domain\Customer\Models\Customer;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Exists;

/**
 * روابط التواصل يحفظها العميل من «حسابي» — المجموعة كلّها في كلّ حفظ.
 *
 * **قواعد نموذج الموظفين ورسائله نفسها** — {@see StoreCustomerRequest}: رابطُ ويبٍ، بلا تكرار،
 * وعشرةٌ على الأكثر. والفرق واحد: المفتاح **مطلوبٌ هنا** لأن هذا الطلب لا يقول شيئاً غيره، فطلبٌ
 * بلا قائمةٍ خطأٌ لا «احذفها كلّها». الحذف الكامل يُقال بقائمةٍ فارغة صريحة.
 */
class SaveClientSocialLinksRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'social_links' => ['present', 'array', 'max:10'],
            'social_links.*.id' => ['sometimes', 'integer', 'distinct', $this->linkBelongsToMe()],
            'social_links.*.url' => ['required', 'string', 'max:2048', 'url:http,https', 'distinct:ignore_case'],
        ];
    }

    /**
     * من روابط صاحب التوكن وحده، وغير المحذوف منها: رابطُ غيره 422 لا صفٌّ يُعدَّل.
     */
    private function linkBelongsToMe(): Exists
    {
        $customer = $this->user();

        assert($customer instanceof Customer);

        return Rule::exists('customer_social_links', 'id')
            ->where('customer_id', $customer->getKey())
            ->withoutTrashed();
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'social_links.present' => 'روابط التواصل مطلوبة',
            'social_links.array' => 'روابط التواصل يجب أن تكون قائمة',
            'social_links.max' => 'لا يمكن إضافة أكثر من 10 روابط',
            'social_links.*.id.exists' => 'الرابط المحدد غير موجود',
            'social_links.*.id.distinct' => 'الرابط مكرر',
            'social_links.*.url.required' => 'الرابط مطلوب',
            'social_links.*.url.string' => 'الرابط غير صحيح',
            'social_links.*.url.max' => 'الرابط طويل جداً',
            'social_links.*.url.url' => 'الرابط غير صحيح',
            'social_links.*.url.distinct' => 'الرابط مكرر',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'social_links' => 'روابط التواصل',
            'social_links.*.url' => 'الرابط',
        ];
    }
}
