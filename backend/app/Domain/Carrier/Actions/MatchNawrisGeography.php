<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\DTOs\GeographyMatchReport;
use App\Domain\Carrier\Support\ArabicName;
use App\Domain\Carrier\Support\NawrisClient;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;

/**
 * Reads their government and area lists and writes **their names** onto our own cities and regions.
 *
 * **Their name, verbatim — not their id.** `add-order` validates `government` and `area` against
 * the names in those lists: an id comes back «المدينة غير موجودة», and the routing suffix is part
 * of the string it wants, so «الحشان(s18)» is accepted where «الحشان» is not. The columns are
 * still called `nawris_government_id` and `nawris_area_id` because they were added before anyone
 * had called the API.
 *
 * **Why this is not a screen.** A city with no `nawris_government_id` refuses dispatch by name —
 * see {@see \App\Domain\Carrier\Exceptions\CityHasNoNawrisMapping} — so before the first parcel
 * every destination has to be mapped. Doing it by hand is reading two lists side by side and
 * copying integers, once per town, and getting one wrong sends parcels to the wrong place with
 * nothing on our side reading as an error.
 *
 * **An exact match after normalisation, or nothing.** {@see ArabicName} folds the spellings nobody
 * means differently; anything left over is reported for a human rather than guessed at. The
 * failure mode of a fuzzy match here is a parcel delivered to another town, which no one finds
 * out about until a customer calls.
 *
 * **Never overwrites.** A city that already carries an id was mapped by somebody who looked, and
 * a name match is a weaker fact than a decision. Re-running is therefore safe, and is how the
 * mapping is finished: map what you can, phone about the rest, run it again.
 *
 * Areas are read per government, so an area name is only ever matched inside the city it belongs
 * to — two towns may both have a «وسط البلد».
 */
final class MatchNawrisGeography
{
    public function __construct(private readonly NawrisClient $client) {}

    /**
     * @param  bool  $apply  false previews: the same report, nothing written
     */
    public function __invoke(bool $apply = true): GeographyMatchReport
    {
        [$strict, $loose] = $this->byName($this->client->governments());

        $matchedCities = 0;
        $matchedRegions = 0;
        $alreadyMapped = 0;
        $unmatchedCities = [];
        $unmatchedRegions = [];

        $cities = City::query()
            // **An «استلام مكتب» city is not an unmapped destination, it is not a destination.**
            // Two of ours are counters of our own wearing a city's clothes; dispatch refuses them
            // by name anyway, and listing them as unmatched would put permanent noise in a report
            // whose whole worth is being a to-do list that can reach empty.
            ->where('fulfilment_type', FulfilmentType::Delivery)
            ->with('regions')
            ->orderBy('name')
            ->get();

        foreach ($cities as $city) {
            // A city mapped by hand carries their *name*, and `get-area` wants their id — so the
            // row is looked up either way, and the mapping is simply not rewritten.
            $their = $this->theirRowFor(
                $this->mapped($city->nawris_government_id) ?? $city->name,
                $strict,
                $loose,
            );

            if ($their === null) {
                // Their side has never heard of this town; its regions cannot be read either.
                $unmatchedCities[] = (string) $city->name;

                continue;
            }

            if ($this->mapped($city->nawris_government_id) !== null) {
                $alreadyMapped++;
            } else {
                $matchedCities++;

                if ($apply) {
                    $city->forceFill(['nawris_government_id' => $their['name']])->save();
                }
            }

            [$regions, $missing] = $this->matchRegions($city, $their['id'], $apply);

            $matchedRegions += $regions;
            $unmatchedRegions = [...$unmatchedRegions, ...$missing];
        }

        return new GeographyMatchReport(
            matchedCities: $matchedCities,
            matchedRegions: $matchedRegions,
            unmatchedCities: $unmatchedCities,
            unmatchedRegions: $unmatchedRegions,
            alreadyMappedCities: $alreadyMapped,
        );
    }

    /**
     * @param  string  $government  their **id** for the city — what `get-area` is keyed by
     * @return array{int, list<string>}
     */
    private function matchRegions(City $city, string $government, bool $apply): array
    {
        $unmapped = $city->regions->filter(fn (Region $region) => $this->mapped($region->nawris_area_id) === null);

        // One HTTP call per city is already the cost of this; making it for a city with nothing
        // left to map would be paying it for no reason.
        if ($unmapped->isEmpty()) {
            return [0, []];
        }

        [$strict, $loose] = $this->byName($this->client->areas($government));

        $matched = 0;
        $missing = [];

        foreach ($unmapped as $region) {
            $area = $this->theirRowFor($region->name, $strict, $loose);

            if ($area === null) {
                // Named with its city, because «الظهرة» alone does not say which one.
                $missing[] = $city->name.' — '.$region->name;

                continue;
            }

            $matched++;

            if ($apply) {
                $region->forceFill(['nawris_area_id' => $area['name']])->save();
            }
        }

        return [$matched, $missing];
    }

    /**
     * Their rows keyed by the normalised name.
     *
     * A name they list twice keeps the first: a duplicate is their data problem, and picking the
     * later one silently would make this run's answer depend on their ordering.
     *
     * **Their whole row, not just the name.** Both are needed and for different reasons: the name
     * is what `add-order` validates against and is therefore what we store, while `get-area` is
     * keyed by the id — so a city matched by name is read for its areas by number.
     *
     * @param  list<array<string, mixed>>  $rows
     * @return array{array<string, array<string, mixed>>, array<string, array<string, mixed>>}
     */
    private function byName(array $rows): array
    {
        $keyed = [];
        $loose = [];
        $ambiguous = [];

        foreach ($rows as $row) {
            $raw = isset($row['name']) ? (string) $row['name'] : '';
            $name = ArabicName::normalize($raw);

            if ($name === '' || isset($keyed[$name])) {
                continue;
            }

            $keyed[$name] = $row;

            // The article pass, built beside the strict one so a collision can be seen. Two of
            // their names that collapse together are removed from it entirely — «البيضاء» and
            // «بيضاء» may be two towns, and picking one silently is the failure this whole class
            // is arranged to avoid.
            $bare = ArabicName::withoutArticles($raw);

            if (isset($loose[$bare])) {
                $ambiguous[$bare] = true;

                continue;
            }

            $loose[$bare] = $row;
        }

        return [$keyed, array_diff_key($loose, $ambiguous)];
    }

    /**
     * Their row for one of ours, or null.
     *
     * @param  array<string, array<string, mixed>>  $strict
     * @param  array<string, array<string, mixed>>  $loose
     * @return array{id: string, name: string}|null
     */
    private function theirRowFor(?string $ours, array $strict, array $loose): ?array
    {
        $row = $strict[ArabicName::normalize($ours)]
            ?? $loose[ArabicName::withoutArticles($ours)]
            ?? null;

        if ($row === null) {
            return null;
        }

        $name = isset($row['name']) ? (string) $row['name'] : '';

        return $name === ''
            ? null
            : ['id' => isset($row['id']) ? (string) $row['id'] : '', 'name' => $name];
    }

    /** An id that is present and not an empty string — the same test dispatch makes. */
    private function mapped(?string $id): ?string
    {
        return $id !== null && trim($id) !== '' ? $id : null;
    }
}
