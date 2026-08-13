<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Customer\Models\CustomerComment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin CustomerComment
 */
class CustomerCommentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'body' => $this->body,

            // Who said it, always — a note nobody can be asked about is a rumour. The name is
            // sent alongside the id because every screen showing a note shows the name, and an
            // app that has to look one up per row is an app making N requests to render a list.
            'author' => [
                'id' => $this->user_id,
                'name' => $this->author?->name,
            ],

            'created_at' => $this->created_at?->toIso8601String(),

            // Null means «as it was written». What the app puts «عُدّلت» under.
            'edited_at' => $this->edited_at?->toIso8601String(),

            // **The authorization rule, decided here and read there.** «صاحبه أو مشرف» is
            // computed per reader and travels with the row, so the app draws the buttons without
            // holding a second copy of a rule that would drift the day it changes. Presentation
            // only: the endpoints refuse the request on their own — see CustomerCommentController.
            'can_edit' => $this->resource->isChangeableBy($request->user()),
            'can_delete' => $this->resource->isChangeableBy($request->user()),
        ];
    }
}
