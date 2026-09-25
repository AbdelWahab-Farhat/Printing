<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Shop;

use App\Application\Api\V1\Requests\Customer\StoreCustomerRequest;
use App\Domain\Customer\Actions\UpdateCustomerShop;
use App\Domain\Delivery\Models\Region;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * متجرٌ يضيفه العميل من التطبيق أو يعدّله — والطلبان بالقواعد نفسها، لأن التعديل يرسل المتجر كاملاً
 * كما ترسله الإضافة.
 *
 * **حقول نموذج الموظفين الأربعة، بقواعدها ورسائلها** — {@see StoreCustomerRequest}: الاسم، ومجال
 * العمل، والمدينة والمنطقة، ورابط الصفحة. وما يغيب مقصود: `customer_id` من التوكن لا من الجسم،
 * والإحداثيات لا يسأل عنها أحد، فلا يمسّها تعديلٌ من الهاتف — انظر {@see UpdateCustomerShop}.
 */
class SaveClientShopRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            // مجال العمل. اختياري، والموقوف مقبول كما عند الموظفين: متجرٌ سُجّل تحت مجالٍ أُوقف بعدها
            // يجب أن ينجو من حفظه ثانيةً.
            'business_field_id' => ['nullable', 'integer', Rule::exists('business_fields', 'id')->withoutTrashed()],
            // الخريطة نفسها التي تُوجَّه منها الطلبيات، فالمتجر والطلبية الذاهبة إليه يتكلّمان عن
            // المكان بلغةٍ واحدة. ومدينةٌ أُخرجت من الخريطة لا يُختار عليها متجرٌ جديد.
            'city_id' => ['required', 'integer', Rule::exists('cities', 'id')->withoutTrashed()],
            // اختياريةٌ كما هي في نموذج الموظفين: أكثر المدن بلا مناطق. وكونها داخل المدينة
            // المختارة يُفحص في `withValidator()`.
            'region_id' => ['nullable', 'integer', Rule::exists('regions', 'id')->withoutTrashed()],
            'page_url' => ['nullable', 'url', 'max:2048'],
        ];
    }

    /**
     * المنطقة يجب أن تكون داخل المدينة المختارة — `exists` وحده يقبل منطقةً حقيقيةً من مدينةٍ أخرى.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $cityId = $this->input('city_id');
            $regionId = $this->input('region_id');

            // أحد النصفين غائب: ذلك شأن القواعد الأخرى، ورسالةٌ ثانية عن الحقل نفسه تدفن الأولى.
            if ($cityId === null || $regionId === null || $regionId === ''
                || $validator->errors()->hasAny(['city_id', 'region_id'])) {
                return;
            }

            $isInThatCity = Region::query()
                ->whereKey($regionId)
                ->where('city_id', $cityId)
                ->exists();

            if (! $isInThatCity) {
                $validator->errors()->add('region_id', 'المنطقة المختارة ليست ضمن المدينة المحددة');
            }
        });
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'اسم المكان مطلوب',
            'name.max' => 'اسم المكان طويل جداً',
            'business_field_id.exists' => 'مجال العمل المختار غير موجود',
            'city_id.required' => 'مدينة المحل مطلوبة',
            'city_id.exists' => 'المدينة المختارة غير موجودة',
            'region_id.exists' => 'المنطقة المختارة غير موجودة',
            'page_url.url' => 'رابط الصفحة غير صحيح',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'name' => 'اسم المكان',
            'business_field_id' => 'مجال العمل',
            'city_id' => 'المدينة',
            'region_id' => 'المنطقة',
            'page_url' => 'رابط الصفحة',
        ];
    }
}
