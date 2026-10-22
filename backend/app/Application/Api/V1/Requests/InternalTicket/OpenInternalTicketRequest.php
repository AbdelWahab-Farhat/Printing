<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\InternalTicket;

use App\Domain\InternalTicket\Enums\InternalTicketPriority;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «تذكرة جديدة» — حقولُ نموذج بريمولا بترتيبها. multipart حين تُرفق صور.
 */
class OpenInternalTicketRequest extends FormRequest
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
            /*
             * «مع مَن؟»: موظفٌ **نشط** غير الفاتح نفسه. تذكرةٌ إلى حسابٍ معطّل رسالةٌ لن تُقرأ، وإلى
             * النفس ليست محادثة — والجدولُ يرفض الثانية أيضاً.
             */
            'assignee_id' => [
                'required', 'integer',
                Rule::exists('users', 'id')->where('is_active', true)->withoutTrashed(),
                $this->notMe(),
            ],
            'title' => ['required', 'string', 'max:255'],
            // تصير أولى رسائل المحادثة.
            'description' => ['required', 'string', 'min:3', 'max:5000'],
            // اختياريّ. نوعٌ أُوقف لا يُفتح به، ويبقى على تذاكره القديمة.
            'category_id' => [
                'nullable', 'integer',
                Rule::exists('internal_ticket_categories', 'id')->where('is_active', true)->withoutTrashed(),
            ],
            'priority' => ['nullable', Rule::enum(InternalTicketPriority::class)],
            'customer_id' => ['nullable', 'integer', Rule::exists('customers', 'id')->withoutTrashed()],
            'order_id' => ['nullable', 'integer', Rule::exists('orders', 'id')->withoutTrashed()],
            // حتى أربع صور، كبريمولا. الصوتُ يُرسل من داخل المحادثة لا من هنا.
            'images' => ['nullable', 'array', 'max:'.config('media.internal_ticket_attachments.max_opening_images')],
            'images.*' => [
                'file',
                'mimetypes:image/jpeg,image/png,image/webp',
                'max:'.config('media.internal_ticket_attachments.image_max_kilobytes'),
            ],
        ];
    }

    /**
     * قاعدةٌ واحدة متغيّرة في دالّةٍ خاصة، كي يقرأ Scramble بقيّة المصفوفة — RULES §٧.
     */
    private function notMe(): mixed
    {
        return Rule::notIn([(int) $this->user()?->getKey()]);
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'assignee_id.required' => 'اختر الزميل الذي تفتح التذكرة معه',
            'assignee_id.exists' => 'هذا الموظف غير موجود أو حسابه معطّل',
            'assignee_id.not_in' => 'لا تُفتح تذكرة مع نفسك',
            'title.required' => 'عنوان التذكرة مطلوب',
            'description.required' => 'اكتب تفاصيل التذكرة',
            'description.min' => 'التفاصيل قصيرة جداً',
            'category_id.exists' => 'نوع المشكلة غير موجود',
            'customer_id.exists' => 'العميل غير موجود',
            'order_id.exists' => 'الطلبية غير موجودة',
            'images.max' => 'أربع صور على الأكثر',
            'images.*.mimetypes' => 'الصورة يجب أن تكون JPG أو PNG أو WEBP',
            'images.*.max' => 'الصورة لا يمكن أن تتجاوز '
                .(int) ((int) config('media.internal_ticket_attachments.image_max_kilobytes') / 1024).' ميغابايت',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'assignee_id' => 'الزميل',
            'title' => 'العنوان',
            'description' => 'التفاصيل',
            'category_id' => 'نوع المشكلة',
            'priority' => 'الأولوية',
            'customer_id' => 'العميل',
            'order_id' => 'الطلبية',
            'images' => 'الصور',
        ];
    }
}
