<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class UploadProductImageRequest extends FormRequest
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
            // `image` on top of the mime list: it verifies the file really is an image rather
            // than trusting a renamed extension or a client-supplied content type.
            'image' => [
                'required',
                'file',
                'image',
                'mimes:jpeg,jpg,png,webp',
                'max:'.config('media.product_images.max_kilobytes'),
            ],
            'alt_text' => ['nullable', 'string', 'max:255'],
            'is_primary' => ['sometimes', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'image.required' => 'الصورة مطلوبة',
            'image.image' => 'الملف المرفوع ليس صورة صالحة',
            'image.mimes' => 'الصيغ المسموحة: jpeg، jpg، png، webp',
            'image.max' => 'حجم الصورة أكبر من الحد المسموح',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'image' => 'الصورة',
            'alt_text' => 'النص البديل',
            'is_primary' => 'الصورة الرئيسية',
        ];
    }
}
