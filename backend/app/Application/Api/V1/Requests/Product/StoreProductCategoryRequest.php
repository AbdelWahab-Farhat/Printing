<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductCategoryRequest extends FormRequest
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
            // `withoutTrashed` matches the partial unique index in the database: a category that
            // was deleted releases its name, and the rule has to agree with the constraint or
            // one of them produces a 500 where the other produces a message.
            'name' => [
                'required', 'string', 'min:2', 'max:100',
                Rule::unique('product_categories', 'name')->withoutTrashed(),
            ],

            'description' => ['sometimes', 'nullable', 'string', 'max:500'],

            // Optional because a category is offered the moment it is created; hiding one is a
            // later decision, taken from the list.
            'is_active' => ['sometimes', 'boolean'],

            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:9999'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'اسم التصنيف مطلوب',
            'name.min' => 'اسم التصنيف قصير جداً',
            'name.max' => 'اسم التصنيف طويل جداً',
            'name.unique' => 'التصنيف مسجّل مسبقاً',
            'description.max' => 'وصف التصنيف طويل جداً',
            'sort_order.integer' => 'الترتيب يجب أن يكون رقماً صحيحاً',
            'sort_order.min' => 'الترتيب لا يمكن أن يكون سالباً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'name' => 'اسم التصنيف',
            'description' => 'وصف التصنيف',
            'is_active' => 'الحالة',
            'sort_order' => 'الترتيب',
        ];
    }
}
