<?php

declare(strict_types=1);

namespace App\Domain\Identity\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Enums\EmployeeServiceType;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * صفٌّ من «خدمات الموظفين»: سعرٌ مقترح لموظف في خدمة. Docs/employees/SERVICE-PAY-DESIGN.md §٢.
 *
 * **لا يحدد شيئاً بنفسه**: يظهر في الحقل على التذكرة، وما يُكتب هناك هو ما يُدفع.
 *
 * يُكتب ويُقرأ من `AccessService`، لأن قيد «مَن يقدّم هذه الخدمة» يسكن هناك مرّة واحدة.
 */
#[Fillable(['suggested_price'])]
class EmployeeServicePrice extends Model implements HasAuditTrail
{
    use Auditable, SoftDeletes;

    protected $table = 'employee_services';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'service' => EmployeeServiceType::class,
            'suggested_price' => 'decimal:2',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function employee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
