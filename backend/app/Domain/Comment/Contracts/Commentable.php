<?php

declare(strict_types=1);

namespace App\Domain\Comment\Contracts;

use App\Domain\Comment\Concerns\HasComments;
use App\Domain\Comment\Models\Comment;
use Illuminate\Database\Eloquent\Relations\MorphMany;

/**
 * A record staff may leave notes on, and the one question that differs between them: **is the
 * conversation still open?**
 *
 * A customer's notes are never finished — the customer is still a customer, and the next thing
 * learned about them is worth writing down years later. A design ticket's are: the ticket ends,
 * and «بعد الاعتماد لا يوجد مزيد». One interface, because the controller serving both must be
 * able to ask without knowing which it is holding, and because a `Comment`'s `commentable` is
 * typed as a bare `Model` — this is what makes asking it a question the type system allows.
 *
 * {@see HasComments} answers all three the open way, so joining in is still one `use` line plus
 * this name in the `implements` list; a record that ends overrides the two it needs.
 */
interface Commentable
{
    /**
     * @return MorphMany<Comment, $this>
     */
    public function comments(): MorphMany;

    /** Whether anything may still be written, rewritten or removed here. */
    public function acceptsComments(): bool;

    /**
     * Why it is closed, in the record's own words — «اعتُمد التصميم وأُغلقت المحادثة».
     *
     * Null while it is open. It is the record that says this rather than the comments feature,
     * because «مغلقة» on its own leaves a designer wondering whether their last message landed,
     * and only the ticket knows which of its two endings it reached.
     */
    public function commentsClosedNote(): ?string;
}
