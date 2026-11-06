<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

/**
 * صفّ كما ورد في الملف، قبل فصل المستلم وتنظيفه.
 */
final readonly class NawrisSettlementRow
{
    public function __construct(
        /** رقمه بعد الترويسة — ليجد الموظف السطر في ملفه. */
        public int $number,
        public string $status,
        public string $code,
        public string $receiver,
    ) {}
}
