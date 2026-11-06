<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\EmployeeWallet\AdjustEmployeeWalletRequest;
use App\Application\Api\V1\Requests\EmployeeWallet\CreditEmployeeWalletRequest;
use App\Application\Api\V1\Requests\EmployeeWallet\MoveEmployeeMoneyRequest;
use App\Application\Api\V1\Requests\EmployeeWallet\ReverseEmployeeWalletEntryRequest;
use App\Application\Api\V1\Resources\EmployeeWalletEntryResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\EmployeeWallet\DTOs\EmployeeCreditData;
use App\Domain\EmployeeWallet\DTOs\EmployeeMoneyData;
use App\Domain\EmployeeWallet\EmployeeWalletService;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Support\Money;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * محافظ الموظفين
 *
 * «محفظة الموظف» لمن يديرها — Docs/employees/EMPLOYEE-WALLET-DESIGN.md. محفظةٌ واحدة لكل موظف:
 * تُودَع فيها الأموال ويُسجَّل فيها ما له، ويُسحب منها لمن يملك الصلاحية. كل سطرٍ يُكتب مرة ولا
 * يُعدَّل، والخطأ يُعكس بسطرٍ ثانٍ. ولا أحد يحرّك محفظته بنفسه إلا المدير.
 */
class EmployeeWalletController extends Controller
{
    use ReadsAuditTrail;

    public function __construct(private readonly EmployeeWalletService $wallet) {}

    /**
     * محفظة موظف
     *
     * الرصيد وأحدث السطور، و`can_move` يقول هل يحرّكها هذا القارئ. و`salary` يقترح مبلغ الراتب،
     * ولا يصل إلا لمن يملك `users.salary` — غيابُه «لا يحقّ لك» وهو غير الصفر.
     */
    public function show(Request $request, User $user): JsonResponse
    {
        /** @var User $viewer */
        $viewer = $request->user();

        return $this->success([
            'user_id' => $user->id,
            'balance' => $this->wallet->balanceOf((int) $user->id),
            'can_move' => $this->wallet->mayMove($viewer, (int) $user->id),
            ...($viewer->can(PermissionName::ManageUserSalaries->value) ? ['salary' => $user->salary] : []),
            'recent' => EmployeeWalletEntryResource::collection(
                $this->wallet->entriesOf((int) $user->id, [], 5)->getCollection(),
            ),
        ]);
    }

    /**
     * كشف محفظة موظف
     *
     * الأحدث أولاً، مقسَّماً إلى صفحات. و`balance` في `meta` هو الرصيد كما هو الآن. `type=adjustment`
     * يجمع التعديل بالزيادة والنقص.
     */
    public function entries(Request $request, User $user): JsonResponse
    {
        return $this->successWithPagination(
            EmployeeWalletEntryResource::collection(
                $this->wallet->entriesOf((int) $user->id, $this->filters($request), $this->perPage($request)),
            ),
            extraMeta: ['balance' => $this->wallet->balanceOf((int) $user->id)],
        );
    }

    /**
     * حركات محافظ الموظفين
     *
     * سطور كل المحافظ في صفحة، الأحدث أولاً. `q` يطابق اسم الموظف أو هاتفه أو رمزه.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $this->filters($request) + $request->validate([
            'user_id' => ['nullable', 'integer'],
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        return $this->successWithPagination(
            EmployeeWalletEntryResource::collection($this->wallet->allEntries($filters, $this->perPage($request))),
        );
    }

    /**
     * إيداع
     *
     * مالٌ سلّمه الموظف. ينزل في الحساب الذي تختاره الخزينة للطريقة أو الذي اختير، وتصير الشركة مدينةً
     * به. والحوالة تتطلب واصلها.
     */
    public function deposit(MoveEmployeeMoneyRequest $request, User $user): JsonResponse
    {
        $entry = $this->wallet->deposit(
            (int) $user->id,
            EmployeeMoneyData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->written($entry, 'تم الإيداع');
    }

    /**
     * تسجيل مستحق
     *
     * راتبٌ أو مكافأة صارت على الشركة. يظهر في «المصاريف» بتصنيفه، ولا كاش يتحرك حتى يسحب الموظف.
     */
    public function credit(CreditEmployeeWalletRequest $request, User $user): JsonResponse
    {
        $entry = $this->wallet->credit(
            (int) $user->id,
            EmployeeCreditData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->written($entry, 'تم تسجيل المستحق');
    }

    /**
     * سحب
     *
     * مالٌ قبضه الموظف. لا يتجاوز الرصيد، ويخرج من الحساب الذي تختاره الخزينة أو الذي اختير، ويُرفض
     * إن لم يكن فيه ما يكفي ما دام «منع الرصيد السالب» مفعّلاً. والحوالة تتطلب واصلها.
     */
    public function withdraw(MoveEmployeeMoneyRequest $request, User $user): JsonResponse
    {
        $entry = $this->wallet->withdraw(
            (int) $user->id,
            EmployeeMoneyData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->written($entry, 'تم السحب');
    }

    /**
     * تعديل الرصيد
     *
     * تصحيحٌ باليد بسبب، أو رصيدٌ افتتاحي. لا مال يتحرك، والنقص لا ينزل بالمحفظة تحت الصفر.
     */
    public function adjust(AdjustEmployeeWalletRequest $request, User $user): JsonResponse
    {
        $token = trim((string) $request->validated('client_token'));

        $entry = $this->wallet->adjust(
            (int) $user->id,
            Money::normalize($request->validated('amount')),
            $request->validated('direction') === 'credit',
            (string) $request->validated('reason'),
            $token !== '' ? $token : null,
            $this->actor($request),
        );

        return $this->written($entry, 'تم تعديل الرصيد');
    }

    /**
     * عكس سطر
     *
     * حركةٌ كُتبت خطأً، والخزينة تعكس ما كتبته معها. يُرفض حين سُحب المال، فيُعكس السحب أولاً.
     */
    public function reverse(ReverseEmployeeWalletEntryRequest $request, EmployeeWalletEntry $entry): JsonResponse
    {
        $reversal = $this->wallet->reverse($entry, (string) $request->validated('reason'), $this->actor($request));

        return $this->written($reversal, 'تم عكس الحركة');
    }

    /** تاريخُ السطر — خلف `logs.view` كبقيّة السجلّات. */
    public function logs(ActivityLogFilterRequest $request, EmployeeWalletEntry $entry, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $entry, $audit);
    }

    /**
     * الإعادةُ بالرمز نفسه تُجاب ٢٠٠ بالسطر الأول، لتعرف الشاشة أن شيئاً لم يُكتب هذه المرة.
     */
    private function written(EmployeeWalletEntry $entry, string $message): JsonResponse
    {
        $data = [
            'entry' => new EmployeeWalletEntryResource(
                $entry->load(['recorder', 'treasuryAccount', 'category', 'reversal', 'reversedEntry']),
            ),
            'balance' => $this->wallet->balanceOf((int) $entry->user_id),
        ];

        return $entry->wasRecentlyCreated
            ? $this->created($data, $message)
            : $this->success($data, 'هذه الحركة مسجَّلة من قبل');
    }

    /**
     * @return array{type?: ?string, from?: ?string, to?: ?string}
     */
    private function filters(Request $request): array
    {
        return $request->validate([
            'type' => ['nullable', Rule::in(EmployeeWalletEntryType::filterValues())],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);
    }

    private function perPage(Request $request): int
    {
        return min(max((int) $request->integer('per_page', 20), 1), 100);
    }

    private function actor(Request $request): User
    {
        /** @var User $actor */
        $actor = $request->user();

        return $actor;
    }
}
