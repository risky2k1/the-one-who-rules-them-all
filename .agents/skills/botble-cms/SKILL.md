---
name: botble-cms
description: >-
  Comprehensive coding guidelines, architecture patterns, and reference manuals for
  Botble CMS (services/cms — Laravel 13, PHP 8.4). Activate this skill whenever creating,
  modifying, debugging, or reviewing code inside services/cms, including plugins, themes,
  forms, tables, controllers, models, ecommerce features, payment gateways, APIs, or seeders.
---

# Botble CMS Development Skill (`services/cms`)

This skill provides the complete architecture and coding patterns for `services/cms` (`the-one-who-dutifully-keeps`), built on **Botble CMS (Laravel 13+, PHP 8.4, Vue 3.5, Tabler UI, Vite)**.

## How to Use This Skill (Progressive Disclosure)

Do **not** guess Botble conventions. Before writing or modifying code in `services/cms`, read the relevant topic reference file(s) below based on your task:

| Task / Domain | Reference File to Read | Contents |
| :--- | :--- | :--- |
| **Models, Enums, DB, Validation, CLI, Cache Bugs** | [`references/core-and-database.md`](./references/core-and-database.md) | Naming conventions, Botble `Enum` usage (`getValue()`), `BaseModel`, int/UUID support, Eloquent rules, deprecated Repository pattern, Form Requests, CLI commands, and "My Change Isn't Showing" cache troubleshooting. |
| **Admin CRUD, Forms, Tables, Controllers, Hooks, UI** | [`references/forms-tables-admin.md`](./references/forms-tables-admin.md) | Form Builder (`FieldOptions`), Table Builder (`FormattedColumn` vs `Column`), thin `BaseController` + `DeleteResourceAction`, Admin/Public Routes, Hooks (`add_action`/`add_filter`), Translations (`trans()` vs `__()`), Tabler UI badges/widgets, and Security (XSS/CSRF/Cookies). |
| **Creating or Extending a Plugin** | [`references/plugin-development.md`](./references/plugin-development.md) | Plugin directory structure, Artisan scaffolding (`cms:plugin:create`, `cms:plugin:make:crud`), `Plugin.php` lifecycle (`activate`/`removed`), `plugin.json`, ServiceProvider boot registrations (`DashboardMenu`, `SlugHelper`, `SeoHelper`, `LanguageAdvancedManager`), and permissions. |
| **Themes, Blade Views, Shortcodes, Tailwind v4, Vite** | [`references/theme-and-frontend.md`](./references/theme-and-frontend.md) | Theme & child theme structure, `vite.build.mjs`, `config.php` events, `Theme` & `ThemeSupport` facades, `RvMedia` image rendering, Shortcode registration & admin fields, View Composer/DRY rules, and TailwindCSS v4 configuration. |
| **Ecommerce & Payment Gateways** | [`references/ecommerce.md`](./references/ecommerce.md) | Product/Variation/Specification hierarchy, Order lifecycle & Ecommerce enums, Ecommerce hooks, `EcommerceHelper`, 6-step Payment Gateway integration pattern, and infinite scroll. |
| **REST API & Database Seeders** | [`references/api-and-seeders.md`](./references/api-and-seeders.md) | `BaseApiController`, JSON response format, Sanctum & `api.optional.auth` middleware, Mobile headers (`X-CURRENCY`, `X-LANGUAGE`), Guest Cart pattern, and multi-language Seeder rules (no `fake()` for visible content). |

## Quick Reference Card

```php
// Enum value access (CRITICAL: never access $enum->value or compare object === string)
$model->status->getValue()           // Get raw string value
$model->status->label()              // Get translated label
(string) $model->status              // Cast to string
if ($model->status->getValue() === BaseStatusEnum::PUBLISHED) { ... }

// Translations
trans('plugins/name::file.key')      // Admin (plugins/packages/core) — NEVER use __() in plugins
__('Home')                           // Frontend (themes only, lang/{locale}.json)

// Eloquent
MyModel::query()->where(...)->get()  // Always start with query(), avoid DB:: facade
->with(['relation'])                 // Eager load (for products: include both 'image' and 'images')

// Forms & Tables
NameFieldOption::make()->required()  // Form field options
FormattedColumn::make('col')         // Custom table column render (Column::make() ignores renderUsing!)
    ->formatted(fn ($v) => ...)

// Security & Media
{!! BaseHelper::clean($html) !!}     // Sanitize HTML output
@json($data)                         // Safe JS embedding
RvMedia::getImageUrl($path, 'thumb') // Always use RvMedia for images

// Routes & Controllers
Route::get('{id}', ...)->wherePrimaryKey()      // Supports both int and UUID
MyForm::create()->renderForm()                  // Create action
MyForm::createFromModel($model)->renderForm()   // Edit action
DeleteResourceAction::make($model)              // Destroy action
$this->pageTitle(trans('...'))                  // Set admin page title
$this->httpResponse()->withCreatedSuccessMessage()
```
