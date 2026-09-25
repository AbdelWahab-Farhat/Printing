<?php

declare(strict_types=1);

namespace App\Domain\Support\Actions;

use App\Domain\Customer\Actions\UploadCustomerDesign;
use App\Domain\Support\Enums\AttachmentKind;
use App\Domain\Support\Models\SupportTicket;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

/**
 * يضع ملفَّ رسالةٍ على القرص، ويُرجع ما يُختم به على الرسالة.
 *
 * على طريقة {@see UploadCustomerDesign}، وللأسباب نفسها:
 *
 * 1. **النوع من البايتات** بـfinfo، لا من `getClientMimeType()` ولا من الامتداد — كلاهما
 *    يختاره المرسل.
 * 2. **الاسم على القرص يولّده الخادم.** عميلان يرسلان «logo.pdf» لا يتصادمان، ولا يختار أحدٌ
 *    مساراً؛ والاسم الذي سمّاه صاحبه يُحفظ للعرض وحده.
 * 3. **الملف يُكتب قبل الصف**، والفعل الذي يكتب الرسالة يستدعي هذا خارج معاملته عمداً: صفٌّ
 *    فشل إدراجه يترك ملفاً يتيماً يكلّف مساحة، والعكس يترك رسالةً تشير إلى لا شيء.
 *
 * لا يلمس قاعدة البيانات؛ يُرجع الأعمدة فقط، والرسالة تُكتب مرةً واحدة بكل ما فيها.
 */
final class StoreTicketAttachment
{
    /**
     * @return array<string, mixed>
     */
    public function __invoke(SupportTicket $ticket, UploadedFile $file): array
    {
        $mimeType = (string) $file->getMimeType();
        $kind = AttachmentKind::fromMimeType($mimeType);
        $disk = (string) config('media.ticket_attachments.disk');

        $path = $file->storeAs(
            "ticket-attachments/{$ticket->getKey()}",
            Str::uuid()->toString().'.'.$file->extension(),
            ['disk' => $disk],
        );

        [$width, $height] = $this->dimensionsOf($file, $kind);

        return [
            'attachment_disk' => $disk,
            'attachment_path' => $path,
            'attachment_filename' => $file->getClientOriginalName(),
            'attachment_mime_type' => $mimeType,
            'attachment_kind' => $kind,
            'attachment_size_bytes' => $file->getSize(),
            'attachment_width_px' => $width,
            'attachment_height_px' => $height,
        ];
    }

    /**
     * @return array{0: int|null, 1: int|null}
     */
    private function dimensionsOf(UploadedFile $file, AttachmentKind $kind): array
    {
        // ملفُّ PDF له صفحات لا بكسلات.
        if ($kind !== AttachmentKind::Image) {
            return [null, null];
        }

        $size = @getimagesize($file->getRealPath());

        return $size === false ? [null, null] : [$size[0], $size[1]];
    }
}
