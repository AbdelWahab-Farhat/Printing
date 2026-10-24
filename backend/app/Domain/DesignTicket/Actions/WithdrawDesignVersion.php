<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Exceptions\DesignVersionAlreadyReviewed;
use App\Domain\DesignTicket\Exceptions\OnlyTheUploaderWithdrawsAVersion;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * «سحب النسخة» — **المصمّم رفع ملفاً خطأً، فيصلحه بنفسه بلا انتظار المراجِع.**
 *
 * **يسحب نسختَه هو، ما دامت بانتظار المراجعة.** نسخةٌ حُكم عليها لا تُسحب: الحكمُ سببُ النسخة
 * التالية، ومحوُه يمحو السجلّ. ونسخةُ غيره لا تُسحب بيده.
 *
 * **تعود التذكرة إلى حيث كانت قبل الرفع**: «تعديل مطلوب» إن كانت نسخةٌ سابقة طُلب تعديلها — فالطلبُ
 * ما زال قائماً — وإلا «قيد التصميم». ومن كلتيهما يرفع الملفّ الصحيح نسخةً تالية.
 *
 * **لا شيء يُحذف**: النسخةُ تبقى في السجلّ برقمها وعلامة «سحبها المصمّم»، فلا يعود رقمها لملفٍّ
 * آخر — قاعدةُ {@see SubmitDesignVersion} نفسها. وسجلُّ التدقيق يحفظ مَن سحبها ومتى.
 *
 * **ولا جرس**: صاحبُ التذكرة يُبلَّغ حين يصل الملفّ الصحيح، لا حين يُسحب الخطأ.
 *
 * **والمراجِعُ الذي يحكم في اللحظة نفسها**: صفُّ التذكرة مقفل، والسحبُ يكتب حالةَ النسخة بشرط أنها
 * ما زالت «بانتظار المراجعة» — فإن سبقه الحكمُ رُفض السحب، ولا تُكتب حالتان.
 */
final class WithdrawDesignVersion
{
    /**
     * @throws DesignTicketIsClosed
     * @throws DesignVersionAlreadyReviewed
     * @throws OnlyTheUploaderWithdrawsAVersion
     */
    public function __invoke(DesignTicket $ticket, DesignTicketFile $version, User $designer): DesignTicketFile
    {
        if ((int) $version->uploaded_by_user_id !== (int) $designer->getKey()) {
            throw OnlyTheUploaderWithdrawsAVersion::make();
        }

        return DB::transaction(function () use ($ticket, $version): DesignTicketFile {
            $locked = DesignTicket::query()->whereKey($ticket->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->isOpen()) {
                throw DesignTicketIsClosed::make($locked->status);
            }

            $fresh = $version->fresh();

            if ($fresh === null || $fresh->status !== DesignSubmissionStatus::Proposed) {
                throw DesignVersionAlreadyReviewed::make((int) $version->version, $fresh?->status ?? $version->status);
            }

            $fresh->forceFill(['status' => DesignSubmissionStatus::Withdrawn])->save();

            $locked->forceFill(['status' => $this->statusBeforeTheUpload($locked, $fresh)])->save();

            return $fresh->refresh();
        });
    }

    /** «تعديل مطلوب» إن كان آخرُ حكمٍ قبلها طلبَ تعديل، وإلا «قيد التصميم». */
    private function statusBeforeTheUpload(DesignTicket $ticket, DesignTicketFile $withdrawn): DesignTicketStatus
    {
        $lastVerdict = $ticket->versions()
            ->where('version', '<', $withdrawn->version)
            ->where('status', '!=', DesignSubmissionStatus::Withdrawn)
            ->reorder('version', 'desc')
            ->value('status');

        return $lastVerdict === DesignSubmissionStatus::ChangesRequested
            ? DesignTicketStatus::ChangesRequested
            : DesignTicketStatus::InProgress;
    }
}
