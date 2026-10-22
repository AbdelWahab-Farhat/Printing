<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * ردٌّ يقتبس رسالةً من تذكرةٍ أخرى.
 *
 * **يُحرس في الفعل لا في `exists:`**: القاعدةُ تقول إن الرقم موجود، لا إنه في هذه المحادثة — ورقمٌ
 * من تذكرةٍ لا يراها الكاتب كان سيرسم له اقتباساً من كلامٍ لم يُوجَّه إليه.
 */
final class QuotedMessageNotInTicket extends DomainException
{
    public static function make(): self
    {
        return new self('الرسالة المقتبسة ليست في هذه التذكرة');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['reply_to_message_id' => [$this->getMessage()]];
    }
}
