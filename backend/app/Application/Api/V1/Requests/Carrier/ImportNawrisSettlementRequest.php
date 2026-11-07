<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Carrier;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «تنفيذ» — الملف نفسه، وما قاله الموظف عن المال.
 *
 * الصلاحية على المسار. وما يتوقف على محتوى الملف — هل يلزم مبلغ أو سبب أو حساب — لا يُعرف إلا بعد
 * قراءته، فيرفضه `ImportNawrisSettlement` تحت الحقل نفسه.
 */
class ImportNawrisSettlementRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** الملف نفسه الذي عوين. */
            'file' => ['required', 'file', 'mimes:xlsx,xls', 'max:10240'],
            /** يولّده التطبيق مرة لكل معاينة: ضغطتان بالرمز نفسه دفعة واحدة. */
            'client_token' => ['required', 'uuid'],
            /** `fingerprint` من ردّ المعاينة. */
            'fingerprint' => ['required', 'string', 'size:64'],
            /** ما وصل فعلاً من النورس لهذه الطلبيات. لازم حين `total_held` أكبر من صفر. */
            'received_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999.99'],
            /** لازم حين لا تشرح أجور النورس المعروفة الفرق. */
            'difference_reason' => ['nullable', 'string', 'max:500'],
            /** أجوبة `fields` من ردّ المعاينة: مفتاح الحقل => الحساب. */
            'fields' => ['sometimes', 'array'],
            'fields.*' => ['nullable', 'integer'],
            /** طلبيات صالحة لم يصل مالها: تبقى «تم الاستلام» ومالها في عهدة النورس. */
            'left_out' => ['sometimes', 'array'],
            'left_out.*' => ['integer', 'distinct'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'file' => 'الملف',
            'received_amount' => 'المبلغ المستلم',
            'difference_reason' => 'سبب الفرق',
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
