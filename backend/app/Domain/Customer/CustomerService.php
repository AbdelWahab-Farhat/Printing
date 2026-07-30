<?php

declare(strict_types=1);

namespace App\Domain\Customer;

use App\Domain\Customer\Actions\CreateCustomer;
use App\Domain\Customer\Actions\UpdateCustomer;
use App\Domain\Customer\DTOs\CustomerData;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Queries\CustomerFilters;
use App\Domain\Customer\Queries\CustomerListQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The Customer module's public front door.
 *
 * Other modules (Orders, Production, …) talk to customers *only* through this class — they
 * never query the Customer model directly. That is what keeps the dependency one-way and
 * lets the module's internals change without a ripple. Within the module, work still lives
 * in the individual Actions and Queries; this is the seam, not a place for logic.
 */
class CustomerService
{
    public function __construct(
        private readonly CreateCustomer $createCustomer,
        private readonly UpdateCustomer $updateCustomer,
        private readonly CustomerListQuery $listQuery,
    ) {}

    /**
     * @return LengthAwarePaginator<int, Customer>
     */
    public function paginate(CustomerFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->listQuery)($filters, $perPage);
    }

    public function create(CustomerData $data): Customer
    {
        return ($this->createCustomer)($data);
    }

    public function update(Customer $customer, CustomerData $data): Customer
    {
        return ($this->updateCustomer)($customer, $data);
    }

    /**
     * Customers are deactivated rather than deleted, so their history survives.
     */
    public function setActive(Customer $customer, bool $isActive): Customer
    {
        $customer->update(['is_active' => $isActive]);

        return $customer->load('shops');
    }
}
