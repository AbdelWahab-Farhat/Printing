<?php

declare(strict_types=1);

namespace App\Domain\Support\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Support\Enums\AttachmentKind;
use Database\Factories\TicketMessageFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * One thing somebody said in a ticket.
 *
 * **Only `body` is fillable, and that is the model's one rule** — the same rule `Comment` keeps
 * and for the same reason. The author is stamped by the action that writes the row, from the
 * authenticated party, and has no path to change afterwards; a mass assignment from a request
 * body can never sign somebody else's name to a sentence.
 *
 * Exactly one of `user_id` and `customer_id` is set, enforced by a `CHECK` on the table rather
 * than only here — an unsigned message is a sentence nobody can be asked about.
 *
 * **والملف ليس قابلاً للتعبئة أيضاً.** أعمدة `attachment_*` يختمها `StoreTicketAttachment` مما
 * قرأه من الملف نفسه، ولا يصل إليها جسمُ طلب: نوعٌ أو مسارٌ يختاره المرسل هو بالضبط ما يُمنع.
 * وكذلك `client_token`، يختمه الفعلُ الذي يكتب الرسالة.
 */
#[UseFactory(TicketMessageFactory::class)]
#[Fillable(['body'])]
class TicketMessage extends Model
{
    /** @use HasFactory<TicketMessageFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, mixed>
     */
    protected function casts(): array
    {
        return [
            'attachment_kind' => AttachmentKind::class,
            'attachment_size_bytes' => 'integer',
            'attachment_width_px' => 'integer',
            'attachment_height_px' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<SupportTicket, $this>
     */
    public function ticket(): BelongsTo
    {
        return $this->belongsTo(SupportTicket::class, 'support_ticket_id');
    }

    /**
     * The member of staff who wrote it, when staff did.
     *
     * @return BelongsTo<User, $this>
     */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /** Whether the customer wrote this, rather than the shop. */
    public function isFromCustomer(): bool
    {
        return $this->customer_id !== null;
    }

    public function hasAttachment(): bool
    {
        return $this->attachment_path !== null;
    }

    /**
     * رابطُ الملف، يُبنى عند كل طلب ولا يُخزَّن.
     *
     * **القرص خاص**، فالرابط في الإنتاج موقَّعٌ ينتهي — على نسق `CustomerDesign::url()`، والقدرة
     * تُسأل للقرص ولا تُفترض. ولهذا يحفظه التطبيق بمفتاح الرسالة لا بالرابط: الرابط يتغيّر مع كل
     * قراءة، والملف خلفه لا يتغيّر أبداً.
     */
    public function attachmentUrl(): ?string
    {
        if ($this->attachment_path === null || $this->attachment_disk === null) {
            return null;
        }

        $disk = Storage::disk($this->attachment_disk);

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl(
                $this->attachment_path,
                now()->addMinutes((int) config('media.temporary_url_minutes')),
            )
            : $disk->url($this->attachment_path);
    }

    /**
     * ما يُقال عن هذه الرسالة في سطرٍ واحد تحت عنوان التذكرة.
     *
     * نصُّها إن كان لها نص؛ وإلا فالملف: «صورة»، أو اسمُ ملف الـPDF — وهو ما يبحث عنه صاحبه،
     * لا «ملف» لا يميّز رسالةً من أخرى.
     */
    public function previewText(): string
    {
        if ($this->body !== null && $this->body !== '') {
            return $this->body;
        }

        return match ($this->attachment_kind) {
            AttachmentKind::Image => AttachmentKind::Image->label(),
            AttachmentKind::Pdf => $this->attachment_filename ?? 'ملف PDF',
            null => '',
        };
    }
}
