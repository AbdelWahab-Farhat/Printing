<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Treasury\SaveExpenseCategoryRequest;
use App\Application\Api\V1\Resources\ExpenseCategoryResource;
use App\Application\Controller;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExpenseCategoryController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly TreasuryService $treasury) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user?->can(PermissionName::RecordTreasuryOperations->value)
            && ! $user?->can(PermissionName::ManageTreasury->value)) {
            throw new AuthorizationException('لا تملك صلاحية عرض تصنيفات المصروفات');
        }

        return $this->success(ExpenseCategoryResource::collection(
            $this->treasury->categories($request->boolean('active_only')),
        ));
    }

    public function store(SaveExpenseCategoryRequest $request): JsonResponse
    {
        return $this->created(
            new ExpenseCategoryResource($this->treasury->saveCategory(null, $request->values())),
            'تمت إضافة التصنيف',
        );
    }

    public function update(SaveExpenseCategoryRequest $request, ExpenseCategory $category): JsonResponse
    {
        $saved = $this->treasury->saveCategory($category, $request->values());

        return $this->success(
            new ExpenseCategoryResource($saved),
            'تم حفظ التصنيف',
        );
    }
}
