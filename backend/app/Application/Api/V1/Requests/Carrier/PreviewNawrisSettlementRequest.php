<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Carrier;

use Illuminate\Foundation\Http\FormRequest;

/**
 * تقرير النورس للمعاينة. الصلاحية على المسار (`orders.status.settled`).
 */
class PreviewNawrisSettlementRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** تقرير النورس كما هو، أو القالب بعد ملئه. */
            'file' => ['required', 'file', 'mimes:xlsx,xls', 'max:10240'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'file.required' => 'يجب إرفاق ملف الإكسل',
            'file.file' => 'المرفق ليس ملفاً صالحاً',
            'file.mimes' => 'صيغة الملف يجب أن تكون xlsx أو xls',
            'file.max' => 'حجم الملف يجب ألا يتجاوز 10 ميجابايت',
        ];
    }
}
