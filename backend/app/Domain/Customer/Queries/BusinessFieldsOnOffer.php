<?php

declare(strict_types=1);

namespace App\Domain\Customer\Queries;

use App\Domain\Customer\Models\BusinessField;
use Illuminate\Database\Eloquent\Collection;

/**
 * مجالات العمل المعروضة للاختيار حين يُسجَّل متجر — ما يقدّمه منتقي «مجال العمل» في تطبيق العميل.
 *
 * **ليست {@see BusinessFieldListQuery}.** تلك شاشة إدارةٍ تُقلَّب صفحاتها وتعدّ متاجر كل مجال، وهذا
 * منتقٍ لا يُقلَّب ولا يعرض عدداً — فعدُّ المتاجر فيه استعلامٌ لا يقرؤه أحد. والترتيب ترتيبها نفسه:
 * ترتيب المتجر ثم الاسم، فيرى العميل القائمة كما يراها الموظف.
 */
final class BusinessFieldsOnOffer
{
    /**
     * @return Collection<int, BusinessField>
     */
    public function __invoke(): Collection
    {
        return BusinessField::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();
    }
}
