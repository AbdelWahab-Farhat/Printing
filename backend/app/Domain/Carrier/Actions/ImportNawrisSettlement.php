<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\DTOs\NawrisSettlementLine;
use App\Domain\Carrier\DTOs\NawrisSettlementMoney;
use App\Domain\Carrier\DTOs\NawrisSettlementPreview;
use App\Domain\Carrier\DTOs\NawrisSettlementRow;
use App\Domain\Carrier\DTOs\NawrisSettlementSubmission;
use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use App\Domain\Carrier\Enums\NawrisSettlementWarning;
use App\Domain\Carrier\Exceptions\NawrisSettlementRefused;
use App\Domain\Carrier\Models\NawrisSettlementImport;
use App\Domain\Carrier\Models\NawrisSettlementImportItem;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\OrderService;
use App\Domain\Order\Support\Money;
use App\Domain\Order\Support\TransitionFields;
use App\Support\DecimalText;
use Illuminate\Support\Facades\DB;

/**
 * «تنفيذ» — تُسوّى الطلبيات الصالحة، ويُتخطّى ما عداها، وتُحفظ الدفعة بأسطرها.
 *
 * **كل طلبية تمرّ من `ChangeOrderStatus` نفسها**، فلا مرآة تنحرف عنها: المال والربح والسجل كما لو
 * ضغط الموظف زر «تم التسوية» على كل واحدة. وعملية خزينة لكل طلبية، فتُعكس كل واحدة وحدها من
 * «تراجع عن التسوية». TREASURY-DESIGN §٢٥.
 *
 * **السطر المرفوض ليس عطلاً** — يُسجَّل ولا يوقف غيره. أما ما تغيّر منذ المعاينة فيوقف الدفعة كلها:
 * المبلغ المكتوب مكتوب لتلك الطلبيات، وتقسيمه على غيرها قيد خاطئ لا يراه أحد. وكل خطأ غير متوقع
 * يرجع كل شيء، فالدفعة كلها في معاملة واحدة.
 *
 * **الأقفال: الطلبيات بترتيب المعرّف، ثم الحسابات** — ترتيب كل مسار مال آخر، فلا قفل متعاكس.
 */
final class ImportNawrisSettlement
{
    public function __construct(
        private readonly EvaluateNawrisSettlement $evaluate,
        private readonly OrderService $orders,
    ) {}

    /**
     * @param  list<NawrisSettlementRow>  $rows
     */
    public function __invoke(array $rows, NawrisSettlementSubmission $submission, User $actor): NawrisSettlementImport
    {
        return DB::transaction(function () use ($rows, $submission, $actor): NawrisSettlementImport {
            // قفلٌ أولاً ثم قراءة: ما يُقرأ قبل القفل قد يكون تغيّر، فالتقييم الأول يعرف ما يُقفل
            // فقط، والثاني هو الذي يُحكم عليه.
            $lockable = ($this->evaluate)($rows, $actor, withFields: false)->settlingOrderIds();

            Order::query()->whereKey($lockable)->orderBy('id')->lockForUpdate()->get(['id']);

            // بعد القفل عمداً: الضغطة الثانية انتظرت الأولى هنا، وتجدها الآن.
            $replayed = NawrisSettlementImport::query()->where('client_token', $submission->clientToken)->first();

            if ($replayed !== null) {
                return $replayed;
            }

            $preview = ($this->evaluate)($rows, $actor);

            if (! hash_equals($preview->fingerprint(), $submission->fingerprint)) {
                throw NawrisSettlementRefused::stale();
            }

            // بعد البصمة: الترك قرار الموظف، لا تغيّرٌ في الملف.
            $preview = $this->leaveOut($preview, $submission);

            if ($preview->settling() === []) {
                throw NawrisSettlementRefused::nothingToSettle();
            }

            $this->checkAnswers($preview, $submission);

            $money = $this->money($preview, $submission);

            $import = $this->record($preview, $submission, $money, $actor);

            $this->settle($preview, $submission, $money, $import, $actor);

            $this->recordLines($preview, $money, $import);

            return $import;
        });
    }

    /**
     * ما لم يصل ماله لا يُسوّى: «تم التسوية» تعني أن المال رجع، وطلبيةٌ مسوّاة لا تحمل عهدة.
     * فالمتروكة تبقى «تم الاستلام» كأنها لم ترد في الملف، ومالها في عهدة النورس.
     */
    private function leaveOut(NawrisSettlementPreview $preview, NawrisSettlementSubmission $submission): NawrisSettlementPreview
    {
        $settling = $preview->settlingOrderIds();

        foreach ($submission->leftOut as $orderId) {
            if (! in_array($orderId, $settling, true)) {
                throw NawrisSettlementRefused::leftOutNotSettling($orderId);
            }
        }

        return $submission->leftOut === [] ? $preview : $preview->leaving($submission->leftOut);
    }

    private function money(NawrisSettlementPreview $preview, NawrisSettlementSubmission $submission): NawrisSettlementMoney
    {
        $total = $preview->totalHeld();
        $held = [];
        $known = [];

        foreach ($preview->settling() as $line) {
            $held[(int) $line->orderId] = $line->heldAmount;

            if (Money::normalize($line->knownFee) !== '0.00') {
                $known[(int) $line->orderId] = $line->knownFee;
            }
        }

        // لا مال عند النورس لها: دُفعت في المصرف، أو سُوّيت دفعاتها قبل الطلبية. لا مبلغ يُسأل عنه.
        if (bccomp($total, '0', Money::SCALE) <= 0) {
            return NawrisSettlementMoney::split($held, [], '0.00');
        }

        $received = $submission->receivedAmount
            ?? throw NawrisSettlementRefused::receivedMissing(DecimalText::trim($total));

        if (bccomp($received, $total, Money::SCALE) > 0) {
            throw NawrisSettlementRefused::receivedTooMuch(DecimalText::trim($received), DecimalText::trim($total));
        }

        $money = NawrisSettlementMoney::split($held, $known, $received);

        if (! $money->explained && $submission->differenceReason === null) {
            throw NawrisSettlementRefused::reasonMissing(DecimalText::trim($money->difference));
        }

        return $money;
    }

    /**
     * ما يتحقق منه `ChangeOrderStatusRequest` للطلبية المفردة، هنا لأن القائمة لا تُعرف إلا بعد
     * قراءة الملف. لا شيء لم يُسأل عنه، ولا سؤال بلا جواب، ولا حساب من خارج ما عُرض.
     */
    private function checkAnswers(NawrisSettlementPreview $preview, NawrisSettlementSubmission $submission): void
    {
        $asked = [];

        foreach ($preview->fields as $field) {
            $asked[$field->key] = true;
            $answer = $submission->fields[$field->key] ?? null;

            if ($answer === null) {
                if ($field->required) {
                    throw NawrisSettlementRefused::accountMissing($field->key, $field->label);
                }

                continue;
            }

            if (! in_array((string) $answer, array_map(fn (array $option): string => (string) $option['value'], $field->options), true)) {
                throw NawrisSettlementRefused::accountNotOffered($field->key, $field->label);
            }
        }

        foreach (array_keys($submission->fields) as $key) {
            if (! isset($asked[$key])) {
                throw NawrisSettlementRefused::fieldNotAsked((string) $key);
            }
        }
    }

    private function record(
        NawrisSettlementPreview $preview,
        NawrisSettlementSubmission $submission,
        NawrisSettlementMoney $money,
        User $actor,
    ): NawrisSettlementImport {
        $import = new NawrisSettlementImport;

        $import->forceFill([
            'file_name' => mb_substr($submission->fileName, 0, 255),
            'client_token' => $submission->clientToken,
            'imported_by' => $actor->getKey(),
            'rows_count' => $preview->rowsCount,
            'orders_count' => count($preview->lines),
            'settled_count' => $preview->count(NawrisSettlementOutcome::Settled),
            'skipped_count' => $preview->count(NawrisSettlementOutcome::AlreadySettled),
            'rejected_count' => $preview->count(NawrisSettlementOutcome::Rejected),
            'left_out_count' => $preview->count(NawrisSettlementOutcome::LeftOut),
            'warnings_count' => $preview->warningsCount(),
            'total_held' => $preview->totalHeld(),
            'received_amount' => Money::round(bcsub($preview->totalHeld(), $money->difference, 8)),
            'fee_total' => $money->difference,
            // السبب لما لا تشرحه الأجور المعروفة، ويُحفظ ولو كان اختيارياً إن كتبه الموظف.
            'difference_reason' => Money::normalize($money->difference) === '0.00' ? null : $submission->differenceReason,
        ])->save();

        return $import;
    }

    private function settle(
        NawrisSettlementPreview $preview,
        NawrisSettlementSubmission $submission,
        NawrisSettlementMoney $money,
        NawrisSettlementImport $import,
        User $actor,
    ): void {
        $lines = $preview->settling();

        usort($lines, fn (NawrisSettlementLine $a, NawrisSettlementLine $b) => $a->orderId <=> $b->orderId);

        foreach ($lines as $line) {
            $id = (int) $line->orderId;
            $fields = $submission->fields;

            // كما تفعل الشاشة: «استُلم المال في» لا يُسأل عنها إلا من له مال في عهدة.
            if (! $line->holdsCustody) {
                unset($fields[TransitionFields::SETTLEMENT_ACCOUNT]);
            }

            if (isset($money->fees[$id]) && Money::normalize($money->fees[$id]) !== '0.00') {
                $fields[TransitionFields::SETTLEMENT_FEE] = $money->fees[$id];
            }

            // نموذج واحد لا مجموعة: الوضع الصارم يرفض التحميل الكسول من نموذج جاء في مجموعة.
            $this->orders->changeStatus(
                Order::query()->findOrFail($id),
                OrderStatus::Settled,
                "تسوية جماعية من ملف «{$import->file_name}»",
                $actor,
                $fields,
                batch: $import->label(),
            );
        }
    }

    private function recordLines(NawrisSettlementPreview $preview, NawrisSettlementMoney $money, NawrisSettlementImport $import): void
    {
        foreach ($preview->lines as $line) {
            $item = new NawrisSettlementImportItem;

            $item->forceFill([
                'nawris_settlement_import_id' => $import->getKey(),
                'row_number' => $line->row->number,
                'raw_status' => $line->row->status,
                'raw_code' => $line->row->code,
                'raw_receiver' => $line->row->receiver,
                'order_id' => $line->orderId,
                'order_code' => $line->orderCode,
                'previous_status' => $line->previousStatus?->value,
                'outcome' => $line->outcome,
                'reason_code' => $line->rejection?->value,
                'reason' => $line->reason,
                'warnings' => $line->warnings === [] ? null : array_map(
                    fn (array $warning): array => self::warning($warning['code'], $warning['message']),
                    $line->warnings,
                ),
                'held_amount' => $line->heldAmount,
                'fee_amount' => $line->settles() ? ($money->fees[(int) $line->orderId] ?? '0.00') : '0.00',
            ])->save();
        }
    }

    /**
     * @return array{code: string, message: string}
     */
    private static function warning(NawrisSettlementWarning $code, string $message): array
    {
        return ['code' => $code->value, 'message' => $message];
    }
}
