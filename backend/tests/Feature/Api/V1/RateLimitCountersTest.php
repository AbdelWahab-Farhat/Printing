<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use Illuminate\Support\Facades\Route;
use Tests\TestCase;

/**
 * Every rate limit counts on its own.
 *
 * Laravel keys `throttle:N,1` by the signed-in user — or, signed out, the IP — and **not by the
 * route**. Two limits without a name therefore share one count: a customer's card-page poll used up
 * the ten a minute of starting a top-up, and sixty realtime sign-ins used up the six announcements.
 * The third argument names the counter; this holds every route to having one, and to its own.
 */
class RateLimitCountersTest extends TestCase
{
    public function test_every_throttled_route_names_a_counter_of_its_own(): void
    {
        // Arrange
        $owners = [];
        $unnamed = [];

        foreach (Route::getRoutes() as $route) {
            foreach ($route->gatherMiddleware() as $middleware) {
                if (! is_string($middleware) || ! str_starts_with($middleware, 'throttle:')) {
                    continue;
                }

                $arguments = explode(',', substr($middleware, strlen('throttle:')));
                $label = implode('|', $route->methods()).' '.$route->uri();

                if (count($arguments) < 3 || trim($arguments[2]) === '') {
                    $unnamed[] = $label;

                    continue;
                }

                $owners[$arguments[2]][] = $label;
            }
        }

        // Assert
        $this->assertSame([], $unnamed, 'A throttle without a counter of its own shares the user\'s count with every other one.');

        foreach ($owners as $counter => $routes) {
            $this->assertCount(1, $routes, "«{$counter}» counts for more than one route: ".implode(', ', $routes));
        }
    }
}
