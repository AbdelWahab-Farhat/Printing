<?php

namespace Tests\Feature;

use Tests\TestCase;

class PrivacyPolicyPageTest extends TestCase
{
    public function test_the_privacy_policy_is_public(): void
    {
        $this->get('/privacy')
            ->assertOk()
            ->assertSee('<html lang="ar" dir="rtl">', false)
            ->assertSee('سياسة الخصوصية لتطبيق «دعاية»');
    }

    /**
     * The generator marks every unfilled `[placeholder]` in the Markdown; none may go public.
     */
    public function test_no_placeholder_is_left_unfilled(): void
    {
        $this->get('/privacy')
            ->assertDontSee('<mark class="todo">', false)
            ->assertSee('https://wa.me/218927206561', false);
    }

    /**
     * Play Console's account-deletion field links straight to this section.
     */
    public function test_the_deletion_section_has_a_stable_anchor(): void
    {
        $this->get('/privacy')->assertSee('id="delete-account"', false);
    }

    /**
     * The stylesheet sits in `@verbatim`, so its at-rules reach the browser exactly as written
     * rather than through Blade's directive compiler.
     */
    public function test_the_css_at_rules_survive_blade(): void
    {
        $this->get('/privacy')
            ->assertSee('@font-face', false)
            ->assertSee('@media (prefers-color-scheme: dark)', false)
            ->assertDontSee('verbatim', false);
    }
}
