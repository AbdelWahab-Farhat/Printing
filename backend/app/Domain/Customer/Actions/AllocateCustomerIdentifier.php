<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\DTOs\CustomerIdentifier;
use Illuminate\Support\Facades\DB;

/**
 * Reserves the next customer id and builds its code: C1, C2, C3 …
 *
 * Why reserve the id instead of computing the code after inserting?
 *
 * The code has to equal 'C' + id, but the id only exists once the row is written. Writing
 * first and updating the code afterwards would need the column to be nullable, and two
 * concurrent inserts would briefly share a placeholder value. Pulling the next value from
 * the table's own sequence first means the insert carries a final, unique code, so the
 * column stays NOT NULL and no two requests can ever collide — `nextval` never returns the
 * same number twice, even under concurrency.
 *
 * A rolled-back transaction leaves its number unused, exactly as it would for the id
 * itself, so codes follow the ids and may skip a number. They are identifiers, not a count.
 *
 * PostgreSQL-specific: this is the only place in the codebase that depends on the driver.
 */
final class AllocateCustomerIdentifier
{
    /** Prefix that turns a numeric id into a customer code. */
    public const PREFIX = 'C';

    public function __invoke(): CustomerIdentifier
    {
        $id = (int) DB::scalar("select nextval(pg_get_serial_sequence('customers', 'id'))");

        return new CustomerIdentifier($id, self::PREFIX.$id);
    }
}
