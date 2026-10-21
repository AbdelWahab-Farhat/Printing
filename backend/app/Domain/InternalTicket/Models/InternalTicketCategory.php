<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use Database\Factories\InternalTicketCategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * «نوع المشكلة» في نموذج «تذكرة جديدة».
 *
 * **جدولٌ لا تعداد**، بخلاف الأولوية: قائمةٌ يملكها صاحبُ المحل، وتُبذر بأنواعٍ أولى في الترحيل
 * وتُدار من شاشةٍ لاحقاً. نوعٌ أُوقف (`is_active`) يبقى على تذاكره ويغيب عن النموذج.
 */
#[UseFactory(InternalTicketCategoryFactory::class)]
#[Fillable(['name', 'is_active', 'sort_order'])]
class InternalTicketCategory extends Model
{
    /** @use HasFactory<InternalTicketCategoryFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }
}
