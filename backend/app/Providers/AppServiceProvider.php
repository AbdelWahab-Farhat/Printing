<?php

namespace App\Providers;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Polymorphic columns store a short alias — 'product' — instead of a PHP class name.
        // Registered before anything else because it changes how Eloquent both writes *and*
        // matches every morph column in the schema: the audit trail's subject and causer,
        // Sanctum's tokenable, and Spatie's model_has_roles. See AuditSubject for why, and the
        // migration that rewrote the rows written before it.
        AuditSubject::register();

        // Turns three silent classes of bug into loud exceptions everywhere except
        // production: lazy-loaded relations (N+1), reading an attribute that was never
        // selected, and assigning an attribute the model does not have. Off in production so
        // a newly-introduced N+1 degrades performance rather than returning a 500.
        Model::shouldBeStrict(! $this->app->isProduction());

        // An administrator passes every authorization check, always — no permission has to be
        // granted to them and none can be forgotten.
        //
        // `null` rather than `false` for everyone else: returning false here would be a final
        // verdict that short-circuits the real policies and permission checks. Returning null
        // means "no opinion", letting the normal rules decide.
        Gate::before(fn (User $user) => $user->isAdmin() ? true : null);

        // Creating a staff account is the administrator's alone — **for now**.
        //
        // A Gate ability rather than a {@see PermissionName} case, and that is the entire point:
        // a permission is a tick box on the roles screen, so "administrators only" would last
        // exactly until somebody ticked it onto «محاسب». Nothing can grant this one. It is not
        // in the catalogue, so it never appears on that screen, and the rule is here in the one
        // file that already says what an administrator is.
        //
        // Delegating it later is one deliberate edit: delete this line and add a case to
        // PermissionName. The route does not change — it already reads `can:users.create`, the
        // same as every other guarded route in api.php, and starts meaning the permission.
        Gate::define('users.create', fn (User $user) => $user->isAdmin());
    }
}
