# Theme Development, Frontend Assets & TailwindCSS v4 (`services/cms`)

## Frontend Asset & Code Rules

> [!CAUTION]
> These rules are enforced across all Botble CMS code. Violations cause bugs, security issues, or build failures.

| # | Rule | Details |
|---|------|---------|
| 1 | No CDN assets | Bundle locally via npm. No `googleapis`, `jsdelivr`, `unpkg`, `cdnjs` links |
| 2 | XSS whitelist only | All `{!! !!}` must use `BaseHelper::clean()` |
| 3 | jQuery `.on()` only | Never `.click()`, `.bind()`, `.hover()`, `.submit()` — deprecated methods |
| 4 | No inline JS/CSS | No `onclick=`, `onsubmit=`, inline `style=` (unless dynamic values) |
| 5 | No dead code | Delete unused code — never comment out. No `// TODO` leftovers |
| 6 | Latest libraries | Keep dependencies up to date. Run `npm outdated` periodically |

### Google Fonts

```php
// ❌ WRONG — direct CDN link
<link href="https://fonts.googleapis.com/...">

// ✅ CORRECT — caches locally via proxy
{!! BaseHelper::googleFonts('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap') !!}

// ✅ BEST — use Theme::typography() which handles everything automatically
Theme::typography()->registerFontFamilies([...]);
```

## Theme Development

### Theme Structure

```text
/platform/themes/my-theme/
├── assets/               # Source assets (sass, js)
├── config.php            # Theme configuration
├── functions/
│   ├── functions.php     # Theme helper functions
│   └── shortcodes.php    # Shortcode registrations
├── lang/
│   ├── en.json           # English translations (JSON)
│   └── vi.json           # Vietnamese translations
├── layouts/              # Layout templates
├── partials/
│   └── shortcodes/{name}/
│       ├── index.blade.php   # Frontend render
│       └── admin.blade.php   # Admin config form
├── routes/web.php        # Theme-specific routes (optional)
├── src/                  # Theme PHP classes, e.g. Http/Controllers (optional)
├── views/                # Page views
├── widgets/{name}/templates/
│   ├── frontend.blade.php
│   └── backend.blade.php
├── public/               # Compiled public assets
├── screenshot.png        # Theme preview image
├── theme.json            # Theme metadata
└── vite.build.mjs        # Asset build descriptor
```

### vite.build.mjs

Themes declare entries, not a full Vite config — the shared root `vite-build.mjs` runner consumes them. Themes that keep sources in `assets/` (rather than `resources/`) must use the explicit `{src, out}` form:

```js
export default {
    js: [{ src: 'assets/js/my-theme.js', out: 'my-theme.js' }],
    sass: [{ src: 'assets/sass/style.scss', out: 'style.css' }],
}
```

### theme.json Configuration

```json
{
    "id": "vendor/my-theme",
    "name": "My Theme",
    "namespace": "Theme\\MyTheme\\",
    "author": "Your Name",
    "url": "https://yoursite.com",
    "version": "1.0.0",
    "description": "Theme description",
    "required_plugins": ["ecommerce"]
}
```

### config.php Events

```php
return [
    'inherit' => null,  // Parent theme name for child themes

    'events' => [
        'beforeRenderTheme' => function (Theme $theme): void {
            // Register CSS
            $theme->asset()->usePath()->add('theme', 'css/theme.css');

            // Register JS (in footer)
            $theme->asset()->container('footer')->usePath()->add(
                'theme',
                'js/theme.js',
                attributes: ['defer']
            );
        },
    ],
];
```

### Child Theme Development

Create child themes by setting `'inherit' => 'parent-theme'` in `config.php`:

```php
// platform/themes/my-child-theme/config.php
return [
    'inherit' => 'shofy',  // Parent theme folder name

    'events' => [
        'beforeRenderTheme' => function (Theme $theme): void {
            // Add child theme specific assets
            $theme->asset()->usePath()->add('child-styles', 'css/custom.css');
        },
    ],
];
```

Child themes only need files you want to override. Views are looked up in child theme first, then parent.

### Theme Commands

```bash
# Create new theme
php artisan cms:theme:create my-theme

# Activate theme
php artisan cms:theme:activate my-theme

# Rename / remove theme
php artisan cms:theme:rename my-theme new-name
php artisan cms:theme:remove my-theme

# Publish theme assets
php artisan cms:theme:assets:publish

# Theme options & cache
php artisan cms:theme:clear-cache
php artisan cms:theme:options:check            # Diff DB options vs option definitions
php artisan cms:theme:options:cleanup-shared   # Remove stale locale-specific keys
```

### Using Theme Facade

```php
use Botble\Theme\Facades\Theme;

// Render a view
Theme::scope('page', $data)->render();

// Load a partial
Theme::partial('header');

// Get theme option
theme_option('logo');

// Add breadcrumb
Theme::breadcrumb()->add('Home', '/')->add('Page', '/page');
```

### Built-in Theme Getters (Prefer Over Raw `theme_option()`)

```php
Theme::getSiteTitle()         // not theme_option('site_title')
Theme::getLogo()              // not theme_option('logo')
Theme::getLogo('logo_light')  // alt logo variant
Theme::getLogoImage(['alt' => Theme::getSiteTitle()])
Theme::getSiteCopyright()
Theme::formatDate($date)
BaseHelper::getHomepageUrl()
```

### RvMedia: ALWAYS Use for Images

```php
// ❌ WRONG — raw path in img src
// <img src="{{ $product->image }}">
// <img src="/storage/{{ $post->image }}">

// ✅ CORRECT
RvMedia::getImageUrl($model->image)
RvMedia::getImageUrl($model->image, 'thumb')
{!! RvMedia::image($model->image, $model->name, 'thumb') !!}
// Disable lazy loading for above-fold images
{!! RvMedia::image($model->image, $model->name, null, true, [], null, false) !!}
```

### Theme Support Helpers

Register in `functions.php`:

```php
ThemeSupport::registerSocialLinks();
ThemeSupport::registerToastNotification();
ThemeSupport::registerPreloader();
ThemeSupport::registerSiteCopyright();
ThemeSupport::registerDateFormatOption();
ThemeSupport::registerLazyLoadImages();
ThemeSupport::registerSocialSharing();
ThemeSupport::registerSiteLogoHeight();
```

### Shortcode Development

1. Register in `functions/shortcodes.php`
2. Create frontend view at `partials/shortcodes/{name}/index.blade.php`
3. Create admin config view at `partials/shortcodes/{name}/admin.blade.php`

### Shortcode Admin Field Types

```php
Shortcode::fields()->text('name', __('Label'), Arr::get($attributes, 'name'))
Shortcode::fields()->textarea('desc', __('Desc'), ...)
Shortcode::fields()->image('image', __('Image'), ...)
Shortcode::fields()->select('style', __('Style'), ..., ['s1' => 'Style 1'])
Shortcode::fields()->onOff('show_title', __('Show Title'), ..., 'yes')
Shortcode::fields()->number('limit', __('Limit'), ..., 6)
Shortcode::fields()->color('bg_color', __('Background'), ...)
Shortcode::fields()->tabs(Shortcode::fields()->tab('tabs', __('Tabs'), [...]))
```

### View Size & DRY Rules

- Max ~150 lines per Blade file — split into partials if exceeded
- No DB queries in header/footer partials — use a View Composer:

```php
View::composer('theme.my::partials.header', function ($view) {
    $counts = Cache::remember('header_counts', 60, fn () => [...]);
    $view->with('counts', $counts);
});
```

- JS utility functions: never duplicate across files — extract to `assets/js/utils/`
- Always clean up `setInterval`/`setTimeout` on page unload:

```js
const interval = setInterval(checkStatus, 5000);
window.addEventListener('beforeunload', () => clearInterval(interval));
```

### Slider Unique IDs (Multiple Shortcode Instances)

```php
@php($sliderUniqueId = 'product-slider-' . uniqid())
// Use $sliderUniqueId in Blade: id="{{ $sliderUniqueId }}"
// Button: class="slider-prev-{{ $sliderUniqueId }}"
```

## TailwindCSS v4 Themes

### No tailwind.config.js — All Config in CSS

```css
@import "tailwindcss";

@source "../../../../themes/my-theme/layouts/**/*.blade.php";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
    --color-primary-500: oklch(0.62 0.18 255);
    --font-sans: 'Inter', ui-sans-serif, system-ui;
}

@plugin "@tailwindcss/forms";
```

### Dark Mode

Toggle `.dark` class on `<html>`. Use `dark:` prefix on all affected classes. Persist to cookie with `SameSite=Lax`.

### Build Pipeline

```bash
npm run dev     # development build (alias: npm run development)
npm run prod    # production build (alias: npm run production) — minifies + copies to public/
php artisan cms:publish:assets  # always run after prod build
```

> [!WARNING]
> There is no `npm run watch` script. Available scripts are `dev`, `development`, `prod`, `production`, `screenshot`, `admin-screenshot`.
