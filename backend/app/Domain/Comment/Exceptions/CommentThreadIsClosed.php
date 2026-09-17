<?php

declare(strict_types=1);

namespace App\Domain\Comment\Exceptions;

use App\Domain\Comment\Contracts\Commentable;
use App\Support\Exceptions\DomainException;

/**
 * Something was written on a conversation that has ended.
 *
 * **The record says why, not this class.** «مغلقة» on its own leaves a designer wondering whether
 * their last message landed; «اعتُمد التصميم وأُغلقت المحادثة» says both what happened and that
 * nothing was lost. The sentence comes from {@see Commentable::commentsClosedNote()}, so a second
 * kind of record that ends brings its own words rather than inheriting a ticket's.
 *
 * 422 rather than 403: nobody was refused for who they are. The moderator holding every grant in
 * the system meets this too — it is the state of the record that is being stated.
 */
final class CommentThreadIsClosed extends DomainException
{
    public static function make(?string $because): self
    {
        return new self($because ?? 'أُغلقت المحادثة على هذا السجل');
    }
}
