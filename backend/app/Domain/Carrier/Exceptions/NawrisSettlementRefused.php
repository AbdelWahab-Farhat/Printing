<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * لماذا لا يُقرأ ملف التسوية أو لا يُنفَّذ. كل رفض يسمّي حقله كي تضعه الشاشة تحته.
 *
 * الطلبية التي لا تصلح ليست من هنا: سطرٌ مرفوض لا يوقف غيره. هذا لما يمنع الدفعة كلها.
 */
final class NawrisSettlementRefused extends DomainException
{
    private function __construct(string $message, private readonly string $field, private readonly int $status = 422)
    {
        parent::__construct($message);
    }

    public static function unreadable(): self
    {
        return new self('تعذّرت قراءة الملف — تأكد أنه ملف إكسل صالح (xlsx أو xls).', 'file');
    }

    public static function missingHeaders(): self
    {
        return new self(
            'لم أجد في الملف ورقةً تحمل الأعمدة المطلوبة: «الحالة» و«الكود» و«اسم المستلم». ارفع تقرير النورس كما هو، أو حمّل القالب واملأه.',
            'file',
        );
    }

    public static function tooManyRows(int $limit): self
    {
        return new self("الملف يتجاوز {$limit} صف — قسّمه إلى ملفات أصغر.", 'file');
    }

    public static function noRows(): self
    {
        return new self('الملف لا يحتوي أي صف بيانات.', 'file');
    }

    public static function nothingToSettle(): self
    {
        return new self('لا طلبية في هذا الملف تصلح للتسوية.', 'file');
    }

    /** 409 لا 422: الطلب سليم، لكن ما بُني عليه تغيّر. */
    public static function stale(): self
    {
        return new self(
            'تغيّرت الطلبيات أو ما عند النورس منذ المعاينة، ولم يُنفَّذ شيء — أعد المعاينة.',
            'fingerprint',
            409,
        );
    }

    public static function receivedMissing(string $held): self
    {
        return new self("أدخل المبلغ المستلم من النورس (عنده {$held} د.ل لهذه الطلبيات).", 'received_amount');
    }

    public static function receivedTooMuch(string $received, string $held): self
    {
        return new self(
            "المبلغ المستلم ({$received}) أكبر مما عند النورس لهذه الطلبيات ({$held}). أدخل نصيب الطلبيات التي ستُسوّى وحدها.",
            'received_amount',
        );
    }

    public static function reasonMissing(string $difference): self
    {
        return new self("المستلم أقل مما عند النورس بـ{$difference} — اكتب سبب الفرق.", 'difference_reason');
    }

    public static function accountMissing(string $key, string $label): self
    {
        return new self("اختر {$label}", "fields.{$key}");
    }

    public static function accountNotOffered(string $key, string $label): self
    {
        return new self("الحساب المختار ليس مما يُختار في «{$label}»", "fields.{$key}");
    }

    public static function leftOutNotSettling(int $orderId): self
    {
        return new self("الطلبية رقم {$orderId} ليست مما يُسوّى في هذا الملف، فلا تُترك.", 'left_out');
    }

    public static function fieldNotAsked(string $key): self
    {
        return new self('هذا الحقل غير مطلوب في هذه الدفعة', "fields.{$key}");
    }

    public function httpStatus(): int
    {
        return $this->status;
    }

    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
