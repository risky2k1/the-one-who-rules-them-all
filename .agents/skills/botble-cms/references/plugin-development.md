# Plugin Development (`services/cms`)

## Learning Resources

> [!TIP]
> Before creating new plugins, study example plugins from the community:
> - **FriendsOfBotble**: https://github.com/orgs/FriendsOfBotble/repositories
> - Contains well-structured plugins demonstrating best practices
> - Examples: `fob-comment`, `fob-wishlist`, `fob-compare`, `fob-faq`, etc.

## Plugin Structure

```text
/platform/plugins/my-plugin/
├── config/
│   ├── general.php
│   └── permissions.php
├── database/migrations/
├── resources/
│   ├── lang/en/{plugin}.php
│   ├── views/
│   ├── js/
│   └── sass/
├── routes/
│   ├── web.php
│   └── api.php (optional)
├── src/
│   ├── Database/
│   ├── Enums/
│   ├── Forms/
│   ├── Http/
│   │   ├── Controllers/
│   │   └── Requests/
│   ├── Models/
│   ├── Providers/
│   │   ├── {Name}ServiceProvider.php
│   │   └── EventServiceProvider.php
│   ├── Repositories/
│   ├── Services/
│   ├── Tables/
│   ├── Widgets/
│   └── Plugin.php
└── plugin.json
```

## Artisan Scaffolding Commands

```bash
# Create new plugin scaffold
php artisan cms:plugin:create my-plugin

# Scaffold a full CRUD module inside a plugin (preferred — generates all classes at once)
php artisan cms:plugin:make:crud my-plugin
php artisan cms:package:make:crud my-package   # same, for /platform/packages

# Scaffold individual components
php artisan cms:make:model {Name} --no-interaction
php artisan cms:make:form {Name} --no-interaction
php artisan cms:make:table {Name} --no-interaction
php artisan cms:make:controller {Name} --no-interaction
php artisan cms:make:request {Name} --no-interaction
php artisan cms:make:route {Name} --no-interaction
php artisan cms:make:panel-section {Name}      # Settings panel section
php artisan cms:make:setting {Name}            # Setting controller + form + request

# Plugin management
php artisan cms:plugin:activate my-plugin
php artisan cms:plugin:deactivate my-plugin
php artisan cms:plugin:activate:all
php artisan cms:plugin:discover                # Rebuild cached plugin manifest
php artisan cms:plugin:assets:publish my-plugin
php artisan cms:plugin:install-from-marketplace {name}
php artisan cms:plugin:update-version-info
```

## Plugin.php Lifecycle

> [!CAUTION]
> `removed()` MUST drop ALL tables and clean up ALL settings. Partial cleanup fails the uninstall contract.

```php
class Plugin extends PluginOperationAbstract
{
    public static function activate(): void
    {
        // Run when plugin is activated
        // Create tables, seed data, register permissions
    }

    public static function deactivate(): void
    {
        // Run when plugin is deactivated
    }

    public static function removed(): void
    {
        // MUST drop ALL tables and clean up ALL data
        Schema::dropIfExists('my_models');
        // Also delete settings, meta, etc.
    }
}
```

## plugin.json Configuration

```json
{
    "id": "vendor/my-plugin",
    "name": "My Plugin",
    "namespace": "Vendor\\MyPlugin\\",
    "provider": "Vendor\\MyPlugin\\Providers\\MyPluginServiceProvider",
    "author": "Your Name",
    "url": "https://yoursite.com",
    "version": "1.0.0",
    "description": "Plugin description",
    "required_plugins": ["ecommerce"]
}
```

## Service Provider Pattern

```php
class MyPluginServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $this
            ->setNamespace('plugins/my-plugin')
            ->loadAndPublishConfigurations(['permissions'])
            ->loadAndPublishViews()
            ->loadAndPublishTranslations()
            ->loadRoutes()
            ->loadMigrations()
            ->publishAssets();

        // Register dashboard menu
        DashboardMenu::default()->beforeRetrieving(function (): void {
            DashboardMenu::make()
                ->registerItem([
                    'id' => 'cms-plugins-my-plugin',
                    'priority' => 5,
                    'name' => 'My Plugin',
                    'icon' => 'ti ti-box',
                    'url' => route('my-plugin.index'),
                    'permissions' => ['my-plugin.index'],
                ]);
        });
    }
}
```

## Permissions Config

```php
// config/permissions.php
return [
    ['name' => 'My Plugin', 'flag' => 'my-plugin.index', 'parent_flag' => 'core.cms'],
    ['name' => 'Create',    'flag' => 'my-plugin.create',  'parent_flag' => 'my-plugin.index'],
    ['name' => 'Edit',      'flag' => 'my-plugin.edit',    'parent_flag' => 'my-plugin.index'],
    ['name' => 'Delete',    'flag' => 'my-plugin.destroy', 'parent_flag' => 'my-plugin.index'],
];
```

## Key Plugin Registrations (in Service Provider `boot()`)

```php
SlugHelper::registerModule(MyModel::class, 'My Items');
SlugHelper::setPrefix(MyModel::class, 'items');
SeoHelper::registerModule([MyModel::class]);

if (is_plugin_active('language') && is_plugin_active('language-advanced')) {
    LanguageAdvancedManager::registerModule(MyModel::class, ['name', 'description', 'content']);
}
```
