<?php

declare(strict_types=1);

namespace App\Domain\Identity\Enums;

/**
 * خدمةٌ يقدّمها موظف بمقابل — Docs/employees/SERVICE-PAY-DESIGN.md §٢.
 *
 * **خدمةٌ جديدة حالةٌ هنا ولا migration لها**، ثم يُقرَّر مكانها وطريقة عرضها. والصلاحية هي القيد: مَن
 * لا يملكها لا تُكتب له الخدمة، وقراءته `null`. وصلاحيةٌ لا اسمُ دور، للسبب الذي تعطيه قائمة المصممين:
 * الدور يُعاد تسميته أو يُقسم، والصلاحية هي ما يفحصه الكود.
 */
enum EmployeeServiceType: string
{
    case Design = 'design';

    public function label(): string
    {
        return match ($this) {
            self::Design => 'التصميم',
        };
    }

    /** ما يجعل الموظف مؤهلاً لهذه الخدمة. */
    public function permission(): PermissionName
    {
        return match ($this) {
            self::Design => PermissionName::AcceptDesignTickets,
        };
    }
}
