<?php

namespace App\Providers;

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
    }
}
