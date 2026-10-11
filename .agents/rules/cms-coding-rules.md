---
paths:
  - "services/cms/**"
---

# Botble CMS (`services/cms`) — Core Coding Rules & Critical Pitfalls

When working inside `services/cms` (Botble CMS, Laravel 13+, PHP 8.4), enforce these mandatory rules at all times. For detailed patterns, activate the **`botble-cms`** skill (`.agents/skills/botble-cms/SKILL.md`) and read its `references/`.

## 1. Architecture & Directory Boundaries
- **Core is Read-Only**: NEVER edit `platform/core/` or `platform/packages/` unless explicitly requested. All custom work belongs in `platform/plugins/{plugin}/` or `platform/themes/{theme}/`.
- **No Repository Pattern in New Code**: `RepositoriesAbstract` is `@deprecated`. Query Eloquent models directly via `MyModel::query()->...` (unless modifying an older plugin that already uses repositories).
- **Thin Controllers**: Extend `BaseController`, use `MyForm::create()->renderForm()`, `MyForm::createFromModel($model)->setRequest($request)->save()`, and `DeleteResourceAction::make($model)`.

## 2. Critical Pitfalls (Zero Tolerance)

| Pitfall | Mandatory Rule |
| :--- | :--- |
| **Botble Enum Comparison** | Botble uses custom `Botble\Base\Supports\Enum` (NOT PHP native enums). `$enum->value` is `protected` and `$model->status === BaseStatusEnum::PUBLISHED` is **always `false`**. ALWAYS use `$model->status->getValue() === BaseStatusEnum::PUBLISHED` or `(string) $model->status`. |
| **ID Type Support (Int + UUID)** | Always type-hint IDs as `int\|string $id`, use `->wherePrimaryKey()` in routes, `$model->getKey()` instead of `$model->id`, and `$table->foreignId('...')->constrained()` in migrations. |
| **Model Base Class & Casts** | Always extend `Botble\Base\Models\BaseModel`. Define `protected function casts(): array` (method, not `$casts` property). |
| **Table Custom Rendering** | `Column::make()` silently ignores `getValueUsing()` and `renderUsing()`. Always use `FormattedColumn::make()` and match the exact column class in closure type-hints. |
| **Translations** | In plugins/packages/core: ALWAYS use `trans('plugins/name::file.key')` with flat PHP array keys (NEVER `__()` or nested arrays). In themes: use `__('Key')` with flat JSON files. Escape apostrophes (`\'`). |
| **XSS & Security** | Never use raw `{!! $var !!}` — wrap with `{!! BaseHelper::clean($var) !!}`. Use `@json($var)` in `<script>`. Read cookies via `request()->cookie()` with an allowlist. |
| **Media & Assets** | Always render images with `RvMedia::getImageUrl()` or `RvMedia::image()`. Never use CDN links (bundle locally via npm; use `BaseHelper::googleFonts()` or `Theme::typography()`). Build via Vite (`vite.build.mjs`), never `webpack.mix.js`. |
| **Tabler UI Badges** | Always pair `bg-{color}` with `text-{color}-fg` (e.g., `badge bg-green text-green-fg`), or use `-lt` light variants (`bg-green-lt`). |
| **Plugin Uninstall Contract** | `Plugin::removed()` MUST drop all plugin tables (`Schema::dropIfExists(...)`) and delete all settings/metadata. |

## 3. Code Quality & Pre-Commit Checklist
- Keep Blade views under ~150 lines (split into partials; no DB queries in header/footer — use View Composers) and PHP classes under ~200 lines.
- Use jQuery `.on()` only (never `.click()`, `.submit()`, or inline `onclick=`).
- Format changed PHP files with `./vendor/bin/pint <path>` and run `php -l <path>` before finishing.
- After `npm run prod`, always run `php artisan cms:publish:assets`.

## 4. Deep-Dive Reference Guides
Before implementing specific features in `services/cms`, read the corresponding reference in `.agents/skills/botble-cms/references/`:
- [`core-and-database.md`](../skills/botble-cms/references/core-and-database.md) — Naming, Enums, Database/Models, Eloquent, Validation, Commands, Troubleshooting
- [`forms-tables-admin.md`](../skills/botble-cms/references/forms-tables-admin.md) — Form Builder, Table Builder, Controllers, Routes, Hooks, Translations, Tabler UI, Security
- [`plugin-development.md`](../skills/botble-cms/references/plugin-development.md) — Plugin Structure, Artisan Generators (`cms:plugin:*`), Lifecycle, ServiceProvider, Permissions
- [`theme-and-frontend.md`](../skills/botble-cms/references/theme-and-frontend.md) — Themes, Child Themes, Vite, TailwindCSS v4, Theme Facade, RvMedia, Shortcodes
- [`ecommerce.md`](../skills/botble-cms/references/ecommerce.md) — Ecommerce Models, Order Lifecycle, Enums, Hooks, Payment Gateway (6-step pattern)
- [`api-and-seeders.md`](../skills/botble-cms/references/api-and-seeders.md) — REST API (`BaseApiController`, Sanctum, Guest Cart, Headers) & Seeder Architecture
