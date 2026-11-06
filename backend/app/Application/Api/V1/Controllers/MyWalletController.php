<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Resources\MyWalletEntryResource;
use App\Application\Controller;
use App\Domain\EmployeeWallet\EmployeeWalletService;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\Identity\Models\User;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * محفظتي
 *
 * الموظف يقرأ محفظته هو، قراءةً فقط وبلا صلاحية — كما يقرأ حسابه في الخزينة. EMPLOYEE-WALLET-DESIGN §١٠.
 */
class MyWalletController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly EmployeeWalletService $wallet) {}

    /**
     * رصيد محفظتي
     *
     * الرصيد وأحدث السطور.
     */
    public function show(Request $request): JsonResponse
    {
        $userId = $this->userId($request);

        return $this->success([
            'balance' => $this->wallet->balanceOf($userId),
            'recent' => MyWalletEntryResource::collection(
                $this->wallet->entriesOf($userId, [], 5)->getCollection(),
            ),
        ]);
    }

    /**
     * كشف محفظتي
     *
     * الأحدث أولاً، مقسَّماً إلى صفحات. و`balance` في `meta` هو الرصيد كما هو الآن.
     */
    public function entries(Request $request): JsonResponse
    {
        $userId = $this->userId($request);

        $filters = $request->validate([
            'type' => ['nullable', Rule::in(EmployeeWalletEntryType::filterValues())],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        return $this->successWithPagination(
            MyWalletEntryResource::collection(
                $this->wallet->entriesOf($userId, $filters, min(max((int) $request->integer('per_page', 20), 1), 100)),
            ),
            extraMeta: ['balance' => $this->wallet->balanceOf($userId)],
        );
    }

    private function userId(Request $request): int
    {
        /** @var User $user */
        $user = $request->user();

        return (int) $user->getKey();
    }
}
