<?php

namespace Database\Factories;

use App\Domain\Treasury\Models\ExpenseCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ExpenseCategory>
 */
class ExpenseCategoryFactory extends Factory
{
    protected $model = ExpenseCategory::class;

    public function definition(): array
    {
        return [
            'name' => 'تصنيف '.fake()->unique()->numerify('###'),
            'requires_employee' => false,
            'is_active' => true,
            'sort_order' => 100,
        ];
    }
}
