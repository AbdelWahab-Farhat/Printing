<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Domain\Investor\Enums\CashEntryType;
use App\Support\Exceptions\DomainException;

/**
 * مالٌ يُطلب من الصندوق أكثر ممّا في خزينته.
 *
 * **والفرقُ بين النقد والقيمة هو كلُّ المسألة.** الصندوقُ قد «يساوي» مئةَ ألف وفي درجه عشرةٌ
 * فقط: البقيةُ بضاعةٌ على رفٍّ وطلبياتٌ سُلِّمت ولم تُحصَّل. فالشراءُ والسحبُ يقرآن الدرج،
 * والقسمةُ تقرأ القيمة — {@see CashEntryType}.
 *
 * والرسالةُ تقول الرقمين معاً، لأن من يقرأ «لا يكفي» وهو يرى على الشاشة قيمةً كبيرة سيظنّ
 * النظامَ مخطئاً.
 */
final class FundHasNotGotTheCash extends DomainException
{
    public static function make(string $requested, string $available): self
    {
        return new self(
            "المطلوب {$requested} د.ل ونقدُ الصندوق {$available} د.ل — الباقي بضاعةٌ ومستحقّاتٌ لم تُحصَّل"
        );
    }
}
