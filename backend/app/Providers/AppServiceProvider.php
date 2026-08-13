<?php

namespace App\Providers;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Customer\Queries\CustomerOrderActivity;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Queries\OrderCustomerActivity;
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
        // The customer list asks about orders — who has never placed one, who has not placed one
        // for longest — through a port it declares itself, so the Customer module can be sorted
        // by the orders without depending on them. `Order` already points at `Customer`; the two
        // pointing at each other would be a cycle. This line is the only place the two meet.
        $this->app->bind(CustomerOrderActivity::class, OrderCustomerActivity::class);
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

        // Resetting somebody else's password — the administrator's alone, and a Gate for the
        // same reason as the line above rather than a weaker version of it.
        //
        // **This one is a takeover, not an edit.** Whoever sets a colleague's password can sign
        // in as them and act under their name in the audit trail, so it must not be a tick box
        // on the roles screen that somebody grants «to save the manager a phone call». Changing
        // one's *own* password is a different endpoint with a different guard: it asks for the
        // current password, because the account holder knows it and a stolen unlocked phone is
        // the risk there.
        Gate::define('users.password', fn (User $user) => $user->isAdmin());
    }
}
