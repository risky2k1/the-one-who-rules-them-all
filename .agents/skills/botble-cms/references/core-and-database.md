# Core Architecture, Database, Enums & Tooling (`services/cms`)

## Project Architecture

Botble CMS is a modular Laravel CMS with the following structure under `services/cms`:

```text
/platform/
├── core/      # Core modules (ACL, base, dashboard, media, settings, table) — READ-ONLY
├── packages/  # Packages (menu, page, SEO, theme, widget) — READ-ONLY
├── plugins/   # Feature plugins (blog, ecommerce, contact, gallery) — EDITABLE
└── themes/    # Frontend themes — EDITABLE
```

### Tech Stack

- **Backend**: Laravel 13+, PHP 8.3+ / 8.4
- **Frontend**: Vue.js 3.5, Bootstrap 5.3, jQuery
- **Build**: Vite (per-module `vite.build.mjs` descriptors, shared `vite-build.mjs` runner), npm workspaces. Applies to **core, packages, plugins AND themes** — `webpack.mix.js` is legacy.
- **Database**: MySQL (SQLite for tests)
- **UI Framework**: [Tabler UI](https://docs.tabler.io/ui)
- **Tooling**: Pint (`pint.json`), PHPStan (`phpstan.neon`), Rector (`rector.php`), Prettier (`.prettierrc`)

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| PHP files | `kebab-case.php` | `product-controller.php` |
| Classes/Enums | `PascalCase` | `ProductController` |
| Methods | `camelCase` | `getProductList()` |
| Variables/Properties | `snake_case` | `$product_name` |
| Constants/Enum Cases | `SCREAMING_SNAKE_CASE` | `PUBLISHED` |
| Translation keys | `dot.notation` | `plugins/blog::posts.create` |
| Route names | `dot.notation` | `my-plugin.index` |
| Config keys | `snake_case` | `max_upload_size` |

## Critical: Botble Enum Usage

> [!CAUTION]
> Botble uses a **custom Enum class** (`Botble\Base\Supports\Enum`), NOT PHP 8.1 native enums. The `$value` property is **protected** and cannot be accessed directly. Direct `===` comparison between an enum instance and a constant always returns `false` (object vs string) — this is the **most common silent bug**.

```php
// ❌ BAD - Will throw: "Cannot access protected property"
$type = $model->status->value;

// ❌ BAD - Always false! Object vs string comparison
if ($model->status === BaseStatusEnum::PUBLISHED) { }

// ✅ GOOD - Use getValue() method
$type = $model->status->getValue();

// ✅ GOOD - Use (string) cast
$type = (string) $model->status;

// ✅ GOOD - Compare using getValue()
if ($attribute->type->getValue() === 'checkbox') { }

// ✅ GOOD - Use static constant for comparison
if ($status->getValue() === BaseStatusEnum::PUBLISHED) { }

// ✅ GOOD - In match() expressions
match ($model->discount_type->getValue()) {
    DiscountTypeEnum::PERCENTAGE => ...,
};
```

`getValue()` is **NOT needed** when:
- Using `$request->input('field')` — already a raw string
- In `->where('status', SomeEnum::VALUE)` — Laravel handles query bindings
- Comparing local variables from enum constants directly

### Enum Methods Reference

**Instance Methods:**
- `getValue()` - Get the raw value
- `label()` - Get translated label
- `getKey()` - Get constant name
- `equals($enum)` - Compare with another enum
- `toHtml()` - Get HTML representation

**Static Methods:**
- `toArray()` - Get all values as `['KEY' => 'value']`
- `labels()` - Get all labels as `['value' => 'Label']`
- `isValid($value)` - Check if value is valid
- `getLabel($value)` - Get translated label for value

## Database Conventions

### Standard Model Fields

All models typically include:
- `id` - Primary key (supports both integer and UUID)
- `name` or `title` - Display name
- `slug` - URL-friendly identifier
- `status` - Uses `BaseStatusEnum`
- `created_at`, `updated_at` - Timestamps
- `author_id`, `author_type` - Polymorphic author relation

### Model Rules

- Always extend `Botble\Base\Models\BaseModel`, never plain `Model`
- `casts()` is a **method** (not property) in Laravel 12+: `protected function casts(): array`

### ID Type Support

Botble CMS supports both integer IDs and UUIDs. Every controller parameter, service method, and route must support both:

```php
// ❌ BAD - Only supports integer IDs
public function show(int $id): Response
Route::get('{id}', ...)->where('id', '[0-9]+');

// ✅ GOOD - Supports both integer and UUID
public function show(int|string $id): Response
Route::get('{id}', ...)->wherePrimaryKey();  // auto-handles int or UUID
```

Never cast `$id` to `(int)`. Use `$model->getKey()` instead of `$model->id` when type matters.

For migrations:
```php
// ❌ BAD - Hardcoded to big integer
$table->bigInteger('user_id')->unsigned();

// ✅ GOOD - Adapts to referenced table's ID type
$table->foreignId('user_id')->constrained();
```

## Eloquent Best Practices

```php
// ✅ Always use query() for Eloquent queries
User::query()->where('status', BaseStatusEnum::PUBLISHED)->get();

// ❌ Avoid raw DB facade
DB::table('users')->where(...);

// ✅ Use eager loading to prevent N+1
Post::query()->with(['author', 'categories'])->get();
```

## Repository Pattern (Deprecated)

> [!CAUTION]
> `Botble\Support\Repositories\Eloquent\RepositoriesAbstract` is marked `@deprecated` in core. Older plugins (blog, contact, gallery, faq, language, member…) still ship `src/Repositories/` folders — that is legacy, not a pattern to copy.
>
> **For new code:** query the model directly (`MyModel::query()->...`) and put reusable logic in the Model, a Service class, or a query scope.

```php
// ❌ DEPRECATED - do not scaffold this for new plugins
interface MyInterface extends RepositoryInterface {}
class MyRepository extends RepositoriesAbstract implements MyInterface {}
$this->app->bind(MyInterface::class, MyRepository::class);

// ✅ CURRENT - direct model access
MyModel::query()->where('status', BaseStatusEnum::PUBLISHED)->get();
```

When editing an existing plugin that already uses repositories, follow its established pattern rather than mixing both styles in one plugin.

## Request Validation

```php
class MyRequest extends Request
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:250'],
            'status' => Rule::in(BaseStatusEnum::values()),
        ];
    }

    public function attributes(): array
    {
        return ['name' => trans('plugins/my::my.form.name')];
    }
}
```

## Development Commands

```bash
# Build assets
npm run dev|prod

# Format code
./vendor/bin/pint [path]              # PHP (config: pint.json)
npx prettier --write {path}           # JS/Vue/Blade (config: .prettierrc)

# Quality checks
php artisan test                      # Run tests
./vendor/bin/phpstan analyse          # Static analysis (config: phpstan.neon)
./vendor/bin/rector process --dry-run # Automated refactors (config: rector.php)

# CMS commands
php artisan cms:plugin:list
php artisan cms:plugin:activate {name}
php artisan cms:theme:activate {name}
php artisan cms:publish:assets        # After prod build
```

### Pre-commit Verification

```bash
php -l path/to/file.php                   # Syntax check
./vendor/bin/pint path/to/file.php        # Format
php artisan test platform/plugins/{plugin}/tests
```

## Code Quality Rules

1. **Always run Pint** on changed PHP files before committing
2. **Use Eloquent** over raw DB queries
3. **Avoid N+1** - use eager loading
4. **Use enums** for select/radio/checklist options
5. **Follow KISS/DRY/YAGNI** principles
6. **Remove unnecessary comments** - keep only `@var`, `@param`, `@return` docblocks
7. **Prefer editing** existing files over creating new ones
8. **Check for security vulnerabilities** - sanitize inputs, escape outputs
9. **Max ~150 lines** per Blade view, ~200 lines per PHP class
10. **No DB queries** in header/footer partials — use View Composers

## Code Review Severity Guide

- **Critical:** Enum comparisons without `getValue()`, XSS `{!! !!}` without `BaseHelper::clean()`, CDN assets, SQL injection, CSRF missing
- **High:** Models not extending `BaseModel`, inline JS/CSS, dead code, DRY violations, view files >150 lines, controller >200 lines
- **Medium:** ID params not `int|string`, hardcoded strings, `bigInteger` in migrations, cookie without allowlist, N+1 queries
- **Low:** Missing `query()` builder, `setInterval` without cleanup, noisy comments

## "My Change Isn't Showing" — Check Before Debugging Code

> [!WARNING]
> A large share of reported Botble "bugs" are stale caches or unpublished assets, not logic errors. Rule these out **before** rewriting working code.

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Blade/shortcode edit has no effect | Shortcode cache | Admin → Settings → Cache → disable "Enable shortcode cache" |
| Widget content stale | Widget cache | Same settings page |
| Any admin/frontend staleness | CMS cache | Platform Administration → Cache Management, or `php artisan cache:clear` |
| CSS/JS edit not applied | Assets not published | `npm run prod` **then** `php artisan cms:publish:assets` |
| Theme option/asset changes ignored | Theme cache | `php artisan cms:theme:clear-cache` |
| New route 404s | Cached routes | `php artisan route:clear` |
| New plugin class not found | Stale plugin manifest | `php artisan cms:plugin:discover` |
| Images wrong size after changing `theme.json` / `config/image_sizes.php` | Old thumbnails still on disk | Admin → Settings → Media → Regenerate thumbnails |
| Session-dependent output (currency, locale) never changes | Host-level cache ignores session cookies | Check LiteSpeed / Cloudflare / hPanel cache outside the CMS |

Also note: `plugin.json` `version` reflects the plugin's own tag, **not** the core CMS version — a "low" number there is by design, not a stale install.

### Public Cache Control

```bash
# .env
CMS_PUBLIC_CACHE_CONTROL_ENABLED=true
CMS_PUBLIC_CACHE_MAX_AGE=600
```

Pages with CSRF forms automatically get `Cache-Control: no-store`. Public pages get `Cache-Control: public, max-age=600`.
