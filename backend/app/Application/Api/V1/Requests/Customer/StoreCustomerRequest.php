<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:255'],
            // Digits only, wide enough for both Libyan mobiles (0912345678) and
            // landlines (0213334444). One number identifies exactly one customer, so it is
            // unique here *and* in the database — validation gives a readable 422, the unique
            // index is what actually holds under concurrent requests.
            'phone' => ['required', 'string', 'regex:/^\d{9,15}$/', Rule::unique('customers', 'phone')->withoutTrashed()],
            'is_active' => ['sometimes', 'boolean'],

            // Shops are created together with the customer; the code never comes from here.
            'shops' => ['sometimes', 'array'],
            'shops.*.name' => ['required', 'string', 'max:255'],
            // الموقع as coordinates. Bounded to the real ranges so a swapped pair — latitude
            // holding a longitude — is rejected instead of silently placing the shop wrongly.
            'shops.*.latitude' => ['required', 'numeric', 'between:-90,90'],
            'shops.*.longitude' => ['required', 'numeric', 'between:-180,180'],
            'shops.*.page_url' => ['nullable', 'url', 'max:2048'],
            // مجال العمل. Optional — most shops on record have none — and `exists` keeps a
            // stale id from a client's cached list out of the database. Deactivated fields are
            // still accepted: a shop already recorded under one must survive being saved again.
            'shops.*.business_field_id' => ['nullable', 'integer', Rule::exists('business_fields', 'id')->withoutTrashed()],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'اسم العميل مطلوب',
            'name.min' => 'اسم العميل يجب أن يكون حرفين على الأقل',
            'phone.required' => 'رقم الهاتف مطلوب',
            'phone.regex' => 'رقم الهاتف يجب أن يكون أرقاماً فقط (من 9 إلى 15 رقماً)',
            'phone.unique' => 'رقم الهاتف مستخدم مسبقاً لعميل آخر',
            'is_active.boolean' => 'حالة التنشيط يجب أن تكون صحيحة أو خاطئة',
            'shops.array' => 'المحلات يجب أن تكون قائمة',
            'shops.*.name.required' => 'اسم المكان مطلوب',
            'shops.*.latitude.required' => 'خط العرض مطلوب',
            'shops.*.latitude.numeric' => 'خط العرض يجب أن يكون رقماً',
            'shops.*.latitude.between' => 'خط العرض يجب أن يكون بين -90 و 90',
            'shops.*.longitude.required' => 'خط الطول مطلوب',
            'shops.*.longitude.numeric' => 'خط الطول يجب أن يكون رقماً',
            'shops.*.longitude.between' => 'خط الطول يجب أن يكون بين -180 و 180',
            'shops.*.page_url.url' => 'رابط الصفحة غير صحيح',
            'shops.*.business_field_id.exists' => 'مجال العمل المختار غير موجود',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'name' => 'اسم العميل',
            'phone' => 'رقم الهاتف',
            'is_active' => 'الحالة',
            'shops' => 'المحلات',
            'shops.*.name' => 'اسم المكان',
            'shops.*.latitude' => 'خط العرض',
            'shops.*.longitude' => 'خط الطول',
            'shops.*.page_url' => 'رابط الصفحة',
            'shops.*.business_field_id' => 'مجال العمل',
        ];
    }
}
