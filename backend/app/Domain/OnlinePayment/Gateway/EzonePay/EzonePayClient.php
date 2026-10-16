<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway\EzonePay;

use App\Domain\OnlinePayment\Exceptions\GatewayRejected;
use App\Domain\OnlinePayment\Exceptions\GatewayUnavailable;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Every HTTP call to EzonePay, and nothing else — with `EzonePayGateway`, the only two files that
 * know EzonePay's shapes. Built from Primula's integration before our sandbox was reachable: when
 * reality differs, these two change and the domain does not.
 *
 * - **Signed in once**, the access token cached until shortly before it expires and renewed with
 *   the refresh token; a lock makes one request renew it while the rest wait (no stampede).
 * - **A 401 is retried once**, after forgetting the token: a revoked token must not keep failing
 *   until the cache expires (Primula's gap).
 * - **IPv4 forced**: EzonePay's host answered slowly over IPv6 in Primula, which cost 30-second
 *   timeouts.
 * - **Only reads are retried.** A request that creates a payment is never sent twice by us.
 * - **No `try`/`catch`** (RULES §5): a status is read and a domain exception thrown; a transport
 *   failure is a `ConnectionException`, rendered as 503 by the handler.
 * - **Logged to its own channel**, with the password, tokens, card numbers and OTPs masked.
 */
final class EzonePayClient
{
    private const ACCESS = 'ezone:access_token';

    private const REFRESH = 'ezone:refresh_token';

    private const MASKED = ['Password', 'password', 'RefreshToken', 'refreshToken', 'accessToken', 'otp', 'secretKey', 'SecretKey'];

    /**
     * @param  array<string, mixed>  $config
     */
    public function __construct(private readonly array $config) {}

    /** The email and the password — the shop is optional (see [shopId()]). */
    public function isConfigured(): bool
    {
        return trim((string) ($this->config['email'] ?? '')) !== ''
            && trim((string) ($this->config['password'] ?? '')) !== '';
    }

    /**
     * `EZONE_PAY_SHOP_ID`, or null — and null is left out of the request: EzonePay then uses the
     * merchant's default shop (its API docs: «If not provided, uses merchant's default shop»).
     */
    public function shopId(): ?int
    {
        $id = $this->config['shop_id'] ?? null;

        return is_numeric($id) && (int) $id > 0 ? (int) $id : null;
    }

    /**
     * @param  array<string, mixed>  $body
     * @return array<string, mixed>
     */
    public function post(string $path, array $body, string $field = 'payment'): array
    {
        return $this->send('post', $path, $body, $field);
    }

    /**
     * @return array<string, mixed>
     */
    public function get(string $path, string $field = 'payment'): array
    {
        return $this->send('get', $path, [], $field);
    }

    /** Forgets both tokens — the next call signs in afresh. */
    public function forgetTokens(): void
    {
        Cache::forget(self::ACCESS);
        Cache::forget(self::REFRESH);
    }

    /**
     * @param  array<string, mixed>  $body
     * @return array<string, mixed>
     */
    private function send(string $method, string $path, array $body, string $field, bool $retried = false): array
    {
        if (! $this->isConfigured()) {
            throw GatewayUnavailable::notConfigured();
        }

        $this->log('request', $path, $body);

        $request = $this->http()->withToken($this->accessToken());

        // Reads only: a lost answer to a GET is asked again; a POST that may have created a
        // payment is not.
        if ($method === 'get') {
            $request = $request->retry(2, 300, throw: false);
        }

        $response = $method === 'get' ? $request->get($path) : $request->post($path, $body);

        $this->log('response', $path, ['status' => $response->status(), 'body' => $this->decode($response)]);

        if ($response->status() === 401 && ! $retried) {
            Cache::forget(self::ACCESS);

            return $this->send($method, $path, $body, $field, retried: true);
        }

        return $this->unwrap($response, $field);
    }

    /**
     * The token in the cache, or a new one — renewed once even when many requests ask at once.
     */
    private function accessToken(): string
    {
        $cached = Cache::get(self::ACCESS);

        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        return Cache::lock('ezone:auth', 10)->block(5, function (): string {
            $cached = Cache::get(self::ACCESS);

            // Another request renewed it while this one waited.
            if (is_string($cached) && $cached !== '') {
                return $cached;
            }

            $refresh = Cache::get(self::REFRESH);
            $answer = is_string($refresh) && $refresh !== '' ? $this->authenticate('/Auth/refresh', ['RefreshToken' => $refresh]) : null;
            $answer ??= $this->authenticate('/Auth/login', [
                'Email' => (string) $this->config['email'],
                'Password' => (string) $this->config['password'],
            ]);

            if ($answer === null) {
                throw GatewayUnavailable::authFailed();
            }

            $ttl = max((int) ($answer['expiresIn'] ?? 3600) - (int) ($this->config['token_buffer_seconds'] ?? 60), 60);
            Cache::put(self::ACCESS, (string) $answer['accessToken'], $ttl);

            if (is_string($answer['refreshToken'] ?? null) && $answer['refreshToken'] !== '') {
                // EzonePay does not say how long a refresh token lives; thirty days is assumed.
                Cache::put(self::REFRESH, $answer['refreshToken'], now()->addDays(30));
            }

            return (string) $answer['accessToken'];
        });
    }

    /**
     * Signs in or renews. Null when EzonePay said no — a refresh token that expired falls back to
     * signing in, and a sign-in that fails is the caller's 503.
     *
     * @param  array<string, string>  $body
     * @return ?array<string, mixed>
     */
    private function authenticate(string $path, array $body): ?array
    {
        $this->log('request', $path, $body);

        $response = $this->http()->post($path, $body);
        $decoded = $this->decode($response);

        $this->log('response', $path, ['status' => $response->status(), 'body' => $decoded]);

        $data = isset($decoded['data']) && is_array($decoded['data']) ? $decoded['data'] : $decoded;

        return $response->successful() && is_string($data['accessToken'] ?? null) ? $data : null;
    }

    private function http(): PendingRequest
    {
        return Http::baseUrl((string) $this->config['base_url'])
            ->acceptJson()
            ->asJson()
            ->connectTimeout((int) ($this->config['connect_timeout'] ?? 3))
            ->timeout((int) ($this->config['timeout'] ?? 12))
            // The IPv6 route to EzonePay was slow enough to time out PHP in Primula.
            ->withOptions(['force_ip_resolve' => 'v4']);
    }

    /**
     * The payload, or EzonePay's reason for refusing — a 4xx is the customer's to read (422),
     * a 5xx is ours to wait out (503).
     *
     * @return array<string, mixed>
     */
    private function unwrap(Response $response, string $field): array
    {
        $decoded = $this->decode($response);

        if ($response->serverError()) {
            throw GatewayUnavailable::make();
        }

        if ($response->clientError() || ($decoded['isSuccess'] ?? true) === false) {
            throw GatewayRejected::make($this->reason($decoded), $field);
        }

        return isset($decoded['data']) && is_array($decoded['data']) ? $decoded['data'] : $decoded;
    }

    /**
     * @return array<string, mixed>
     */
    private function decode(Response $response): array
    {
        $decoded = $response->json();

        return is_array($decoded) ? $decoded : [];
    }

    /**
     * EzonePay's own explanation: `message`, then the ASP.NET `errors` flattened, then `title`.
     *
     * @param  array<string, mixed>  $decoded
     */
    private function reason(array $decoded): ?string
    {
        if (is_string($decoded['message'] ?? null) && trim($decoded['message']) !== '') {
            return trim($decoded['message']);
        }

        if (isset($decoded['errors']) && is_array($decoded['errors'])) {
            $messages = [];

            array_walk_recursive($decoded['errors'], function (mixed $value) use (&$messages): void {
                if (is_string($value) && trim($value) !== '') {
                    $messages[] = trim($value);
                }
            });

            if ($messages !== []) {
                return implode(' — ', $messages);
            }
        }

        return is_string($decoded['title'] ?? null) ? $decoded['title'] : null;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function log(string $stage, string $path, array $payload): void
    {
        Log::channel('ezone')->info("{$stage} {$path}", $this->mask($payload));
    }

    /**
     * Passwords, tokens and OTPs out; a card number kept to its last four.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function mask(array $payload): array
    {
        foreach ($payload as $key => $value) {
            if (is_array($value)) {
                $payload[$key] = $this->mask($value);
            } elseif (in_array($key, self::MASKED, true)) {
                $payload[$key] = '***';
            } elseif ($key === 'cardNumber' && is_string($value)) {
                $payload[$key] = '****'.substr($value, -4);
            }
        }

        return $payload;
    }
}
