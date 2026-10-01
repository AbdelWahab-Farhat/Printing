<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\Exceptions\AccountChangeRefused;
use App\Domain\Treasury\Models\ExpenseCategory;

/**
 * Adds or edits an expense category.
 *
 * The categories code relies on (`carrier_fee`, `advance`) may be renamed but not switched off,
 * and «سلفة موظف» keeps demanding its employee — settlement and the advance form both depend on
 * finding them as they are.
 */
final class SaveExpenseCategory
{
    /**
     * @param  array{name?: string, requires_employee?: bool, is_active?: bool, sort_order?: int}  $values
     */
    public function __invoke(?ExpenseCategory $category, array $values): ExpenseCategory
    {
        $category ??= new ExpenseCategory(['is_active' => true, 'requires_employee' => false]);

        if ($category->isSystem()) {
            if (($values['is_active'] ?? true) === false) {
                throw new AccountChangeRefused("تصنيف «{$category->name}» يعتمد عليه النظام ولا يُعطَّل", 'is_active');
            }

            unset($values['requires_employee']);
        }

        $category->fill($values)->save();

        return $category->refresh();
    }
}
