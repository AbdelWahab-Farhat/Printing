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

            // The heading this one sits under. Null — or absent — makes it a heading in its
            // own right.
            //
            // **`whereNull('parent_id')` is the one-level rule**, stated where it can be
            // explained: a category may only be filed under a *root*, so «أكياس ورقية» cannot
            // itself acquire children. Nothing in the catalogue is three deep, and a tree of
            // arbitrary depth costs every screen a recursive render for a shape nobody asked for.
            'parent_id' => [
                'sometimes', 'nullable', 'integer',
                Rule::exists('product_categories', 'id')
                    ->whereNull('deleted_at')
                    ->whereNull('parent_id'),
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
            'parent_id.exists' => 'التصنيف الرئيسي غير موجود، أو هو نفسه تصنيف فرعي',
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
            'parent_id' => 'التصنيف الرئيسي',
            'description' => 'وصف التصنيف',
            'is_active' => 'الحالة',
            'sort_order' => 'الترتيب',
        ];
    }
}
