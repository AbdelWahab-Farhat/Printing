<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use Database\Factories\NawrisSettlementImportFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * رفعة واحدة من تقرير النورس: مَن نفّذها، وكم وصل، وأسطرها كاملة.
 *
 * **لا شيء هنا قابل للتعبئة** — كل عمود يحسبه الخادم، وعدّادٌ يأتي من طلب كذبةٌ في سجل مال.
 */
#[UseFactory(NawrisSettlementImportFactory::class)]
#[Fillable([])]
class NawrisSettlementImport extends Model
{
    /** @use HasFactory<NawrisSettlementImportFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'rows_count' => 'integer',
            'orders_count' => 'integer',
            'settled_count' => 'integer',
            'skipped_count' => 'integer',
            'rejected_count' => 'integer',
            'warnings_count' => 'integer',
            'total_held' => 'decimal:2',
            'received_amount' => 'decimal:2',
            'fee_total' => 'decimal:2',
        ];
    }

    /** ما يُكتب على حركات الخزينة، فيُعرف من كشف الحساب أن هذه السطور تحويل واحد. */
    public function label(): string
    {
        return 'دفعة النورس #'.$this->getKey();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function importer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'imported_by');
    }

    /**
     * @return HasMany<NawrisSettlementImportItem, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(NawrisSettlementImportItem::class);
    }
}
