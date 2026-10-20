<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Customer\Models\Customer;
use App\Domain\OnlinePayment\Enums\FeePayer;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\Order\Models\Order;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One attempt to top up a wallet online. Docs/payments/CUSTOMER-WALLET.md §٥.
 *
 * **Nothing here is fillable**: every column is the server's — the amounts its arithmetic, the
 * reference its own, the status its state machine ({@see IntentStatus}). The wallet row it
 * credited is unique, so an attempt credits once by a database constraint.
 *
 * @property array<string, mixed>|null $customer_info
 * @property array<string, mixed>|null $provider_response
 */
class PaymentIntent extends Model
{
    use Auditable, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'method' => OnlineMethod::class,
            'flow' => PaymentFlow::class,
            'status' => IntentStatus::class,
            'fee_payer' => FeePayer::class,
            'net_amount' => 'decimal:2',
            'order_amount' => 'decimal:2',
            'gross_amount' => 'decimal:2',
            'provider_fee' => 'decimal:2',
            'fee_rate' => 'decimal:6',
            'customer_info' => 'array',
            'provider_response' => 'array',
            'expires_at' => 'datetime',
            'otp_accepted_at' => 'datetime',
            'succeeded_at' => 'datetime',
            'failed_at' => 'datetime',
        ];
    }

    /** The public id — the app never sees the row number. */
    public function getRouteKeyName(): string
    {
        return 'uuid';
    }

    /** What the customer is charged beyond what reaches the wallet. */
    public function customerFee(): string
    {
        return bcsub((string) $this->gross_amount, (string) $this->net_amount, 2);
    }

    /**
     * EzonePay took the code and the payment is not yet clear — no code is asked for again, and
     * the app shows «نتحقق من الدفع» while the server asks.
     */
    public function isConfirming(): bool
    {
        return $this->status === IntentStatus::Pending && $this->otp_accepted_at !== null;
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * @return BelongsTo<CustomerWalletEntry, $this>
     */
    public function walletEntry(): BelongsTo
    {
        return $this->belongsTo(CustomerWalletEntry::class);
    }
}
