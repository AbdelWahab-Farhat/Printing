<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * System
 *
 * Unauthenticated endpoints used to check that the API is reachable.
 */
class HealthController extends Controller
{
    use ResponseTrait;

    /**
     * Health check
     *
     * Confirms the API is up and that it can reach the database. Handy as the very first
     * request to try from the docs UI, and as a smoke test from the Flutter app.
     */
    public function __invoke(): JsonResponse
    {
        $databaseConnected = true;

        try {
            DB::connection()->getPdo();
        } catch (\Throwable) {
            $databaseConnected = false;
        }

        $payload = [
            'application' => config('app.name'),
            'environment' => config('app.env'),
            'api_version' => 'v1',
            'database_connected' => $databaseConnected,
        ];

        return $databaseConnected
            ? $this->success($payload)
            : $this->error('تعذر الاتصال بقاعدة البيانات', 503);
    }
}
