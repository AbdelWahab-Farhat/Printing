<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Client;

use App\Application\Api\V1\Resources\Client\ClientBusinessFieldResource;
use App\Application\Controller;
use App\Domain\Customer\Queries\BusinessFieldsOnOffer;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * Business fields
 *
 * مجالات العمل المعروضة — ما يختار منه العميل «مجال العمل» لمتجره، كما يختار منه الموظف.
 */
class BusinessFieldController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly BusinessFieldsOnOffer $onOffer) {}

    /**
     * Business fields on offer
     *
     * المعروضة وحدها، بترتيب المتجر ثم بالاسم، وبلا صفحات: قائمة منتقٍ لا يُقلَّب.
     */
    public function index(): JsonResponse
    {
        return $this->success(ClientBusinessFieldResource::collection(($this->onOffer)()));
    }
}
