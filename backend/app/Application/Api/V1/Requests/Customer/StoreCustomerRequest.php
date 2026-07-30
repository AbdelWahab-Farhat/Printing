<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

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
            'primary_phone' => ['required', 'string', 'regex:/^\d{9,15}$/', 'unique:customers,primary_phone'],
            'is_active' => ['sometimes', 'boolean'],

            // Shops are created together with the customer; the code never comes from here.
            'shops' => ['sometimes', 'array'],
            'shops.*.name' => ['required', 'string', 'max:255'],
            'shops.*.location' => ['required', 'string', 'max:255'],
            'shops.*.page_url' => ['nullable', 'url', 'max:2048'],
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
            'primary_phone.required' => 'رقم الهاتف مطلوب',
            'primary_phone.regex' => 'رقم الهاتف يجب أن يكون أرقاماً فقط (من 9 إلى 15 رقماً)',
            'primary_phone.unique' => 'رقم الهاتف مستخدم مسبقاً لعميل آخر',
            'is_active.boolean' => 'حالة التنشيط يجب أن تكون صحيحة أو خاطئة',
            'shops.array' => 'المحلات يجب أن تكون قائمة',
            'shops.*.name.required' => 'اسم المكان مطلوب',
            'shops.*.location.required' => 'الموقع مطلوب',
            'shops.*.page_url.url' => 'رابط الصفحة غير صحيح',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'name' => 'اسم العميل',
            'primary_phone' => 'رقم الهاتف',
            'is_active' => 'الحالة',
            'shops' => 'المحلات',
            'shops.*.name' => 'اسم المكان',
            'shops.*.location' => 'الموقع',
            'shops.*.page_url' => 'رابط الصفحة',
        ];
    }
}
