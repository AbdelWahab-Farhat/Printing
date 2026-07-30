<?php

use App\Support\ApiEnvelope;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // An unauthenticated API request must never redirect to a web login page — there
        // isn't one. Returning null makes Laravel throw AuthenticationException, which the
        // handler below renders as a 401 envelope.
        $middleware->redirectGuestsTo(fn (Request $request) => $request->is('api/*') ? null : '/login');
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        // Every API error leaves through the same envelope as a success, so a client has
        // exactly one response shape to parse. Most specific exception first.
        $exceptions->render(function (ValidationException $e, Request $request) {
            return $request->is('api/*')
                ? ApiEnvelope::fail('البيانات المدخلة غير صحيحة', 422, $e->errors())
                : null;
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            return $request->is('api/*')
                ? ApiEnvelope::fail('غير مصرح لك بالدخول', 401)
                : null;
        });

        $exceptions->render(function (AuthorizationException|AccessDeniedHttpException $e, Request $request) {
            return $request->is('api/*')
                ? ApiEnvelope::fail('ليس لديك صلاحية لتنفيذ هذا الإجراء', 403)
                : null;
        });

        $exceptions->render(function (ModelNotFoundException|NotFoundHttpException $e, Request $request) {
            return $request->is('api/*')
                ? ApiEnvelope::fail('العنصر المطلوب غير موجود', 404)
                : null;
        });

        $exceptions->render(function (TooManyRequestsHttpException $e, Request $request) {
            return $request->is('api/*')
                ? ApiEnvelope::fail('عدد المحاولات كبير، يرجى المحاولة لاحقاً', 429)
                : null;
        });

        // Anything else. A 4xx HTTP exception carries an actionable message, so keep it;
        // a 5xx must never leak internals unless we are debugging locally.
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            if ($e instanceof HttpExceptionInterface) {
                return ApiEnvelope::fail(
                    $e->getMessage() !== '' ? $e->getMessage() : ApiEnvelope::DEFAULT_ERROR_MESSAGE,
                    $e->getStatusCode(),
                );
            }

            return ApiEnvelope::fail(
                config('app.debug') ? $e->getMessage() : ApiEnvelope::DEFAULT_ERROR_MESSAGE,
                500,
            );
        });
    })->create();
