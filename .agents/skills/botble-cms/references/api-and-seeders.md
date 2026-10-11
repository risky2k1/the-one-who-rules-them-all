# REST API & Seeder Development (`services/cms`)

## API Development

### API Structure

```text
src/Http/
├── Controllers/API/{Resource}Controller.php  (extends BaseApiController)
├── Resources/API/{Resource}Resource.php       (JsonResource)
└── Requests/API/{Resource}Request.php
```

### API Response Format

```json
{ "error": false, "data": {...}, "message": null }
{ "error": true, "data": null, "message": "Not found" }
```

Use `$this->httpResponse()->setData(...)->setMessage(...)->toApiResponse()`.

### Middleware Reference

| Middleware | Purpose |
|-----------|---------|
| `auth:sanctum` | Require authentication |
| `api.optional.auth` | Guest or authenticated (cart/wishlist) |
| `ForceJsonResponse` | Ensure JSON responses |
| `ThrottleRequests::using('name')` | Rate limiting |
| `ApiCurrencyMiddleware` | Read `X-CURRENCY` header |
| `api.language.ecommerce` | Read `X-LANGUAGE` header |

### Mobile App Custom Headers

```text
X-API-KEY        App authentication
X-CURRENCY       User-selected currency (e.g., 'USD')
X-LANGUAGE       User-selected language (e.g., 'vi')
X-API-IP         Client IP for geolocation
Authorization    Bearer {sanctum-token}
```

### Guest Cart with Optional Auth

```php
Route::group(['middleware' => 'api.optional.auth'], function (): void {
    Route::post('cart/add', [CartController::class, 'addToCart']);
});

// In controller
$customerId = auth('sanctum')->check() ? auth('sanctum')->id() : null;
$cartIdentifier = $customerId ?? (string) Str::uuid();
```

## Seeder Development

### Core Rules

1. **NO** `fake()` / `Faker` for user-visible content — use real names, real descriptions
2. All seeded content must support multi-language via JSON translation files
3. Real images from `database/seeders/files/`, not placeholder URLs
4. Use `Arr::random()` for variety

### When `fake()` IS Acceptable

- Passwords: `bcrypt('12345678')`
- Random selection from real data: `Arr::random($realProducts)`
- Random counts: `rand(3, 8)`
- Random booleans: `rand(0, 1)` for `is_featured`

### Architecture

```text
database/seeders/
├── DatabaseSeeder.php
├── TranslationSeeder.php
├── contents/          HTML content files
├── files/             Seed images/media
├── translations/
│   └── {locale}/
│       ├── ec_products.json
│       └── {model}-content.html
└── Themes/
    └── Main/          Per-variant seeders
```
