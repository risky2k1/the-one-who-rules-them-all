# Forms, Tables, Controllers, Routes, Hooks, Translations & Security (`services/cms`)

## Translation System

### Two Distinct Systems

| Context | Function | File type | Location |
|---------|----------|-----------|----------|
| Plugins/packages/core (admin) | `trans('plugins/blog::posts.create')` | PHP arrays | `resources/lang/{locale}/*.php` |
| Frontend themes only | `__('Home')` | JSON flat key-value | `lang/{locale}.json` |

> [!CAUTION]
> **NEVER** use `__()` in plugins — it won't resolve plugin translation namespaces. Always use `trans()` with the full namespace.

### Translation Best Practices

> [!WARNING]
> - **NEVER** convert string translations to arrays (causes "Array to string conversion" errors)
> - **ALWAYS** escape apostrophes in single-quoted strings
> - Use flat string keys, not nested arrays

```php
// ❌ BAD - Unescaped apostrophe
'message' => 'L'utilisateur n'existe pas',

// ✅ GOOD - Escaped apostrophes
'message' => 'L\'utilisateur n\'existe pas',

// ❌ BAD - Array value
'settings' => ['title' => 'Settings'],

// ✅ GOOD - Flat string keys
'settings_title' => 'Settings',
```

### JSON Translation Rules (Themes)

- Flat key-value only — no nesting
- Keys = English strings
- Preserve `:placeholders` exactly
- One file per language

### Supported Languages (42+)

`ar`, `bg`, `bn`, `cs`, `da`, `de`, `el`, `es`, `fa`, `fi`, `fr`, `he`, `hi`, `hu`, `id`, `it`, `ja`, `ko`, `lt`, `lv`, `ms`, `nb`, `nl`, `pl`, `pt`, `pt-BR`, `ro`, `ru`, `sk`, `sl`, `sr`, `sv`, `th`, `tr`, `uk`, `vi`, `zh`, `zh-TW`

## Form Builder

### Modern Pattern with FieldOptions

```php
use Botble\Base\Forms\Fields\TextField;
use Botble\Base\Forms\Fields\SelectField;
use Botble\Base\Forms\FieldOptions\NameFieldOption;
use Botble\Base\Forms\FieldOptions\StatusFieldOption;

$this->setupModel(new MyModel)
    ->setValidatorClass(MyRequest::class)
    ->add('name', TextField::class, NameFieldOption::make()->required())
    ->add('status', SelectField::class, StatusFieldOption::make());
```

### Multi-Column Forms

```php
$this
    ->columns(12)
    ->add('name', TextField::class, NameFieldOption::make()->colspan(8)->required()->toArray())
    ->add('status', SelectField::class, StatusFieldOption::make()->colspan(4)->toArray());
```

### Available Field Types

- **Text & Input:** `TextField`, `EmailField`, `PasswordField`, `PhoneNumberField`, `NumberField`, `TextareaField`, `UrlField`, `HiddenField`
- **Rich Content:** `EditorField`, `CkEditorField`, `TinyMceField`, `CodeEditorField` (with `.mode('css'|'javascript'|'html'|'php')`)
- **Selection:** `SelectField`, `RadioField`, `CheckboxField`, `MultiCheckListField`, `OnOffField`, `OnOffCheckboxField`, `TreeCategoryField`
- **Media:** `MediaImageField`, `MediaImagesField`, `MediaFileField`, `FileField`
- **Date & Time:** `DatePickerField` (with `.withTimePicker()`), `DateField`, `DatetimeField`, `TimeField`, `TimePickerField`
- **Special:** `ColorField`, `ColorSelectorField`, `TagField`, `RepeaterField`, `CoreIconField`, `GoogleFontsField`, `UiSelectorField`, `AutocompleteField`, `AlertField`, `HtmlField`, `LabelField`

### Select Field: `searchable()` vs `ajaxSearch()`

> [!WARNING]
> These use different CSS classes and **cannot be combined**.

- `searchable()` → `select-search-full` — local search, preloads all choices
- `ajaxSearch()` → `select-search-ajax` — remote AJAX search via `data-url`

Built-in AJAX search routes: `admin.ajax.search-products`, `admin.ajax.search-categories`, `tags.all`

### Extending Another Plugin's Form via Hooks

```php
add_filter(BASE_FILTER_BEFORE_RENDER_FORM, function ($form, $data) {
    if ($data instanceof \Botble\Blog\Models\Post) {
        $form->add('custom_field', TextField::class, ...);
    }
    return $form;
}, 120, 2);
```

## Table Builder

```php
use Botble\Table\Columns\IdColumn;
use Botble\Table\Columns\NameColumn;
use Botble\Table\Columns\StatusColumn;
use Botble\Table\Columns\CreatedAtColumn;

$this->model(MyModel::class)
    ->addColumns([
        IdColumn::make(),
        NameColumn::make()->route('my-plugin.edit'),
        StatusColumn::make(),
        CreatedAtColumn::make(),
    ]);
```

### FormattedColumn vs Column

> [!CAUTION]
> `Column::make()` **silently ignores** `getValueUsing()` and `renderUsing()`. You MUST use `FormattedColumn::make()` for custom render logic. Type-hints in closures must match the actual column class.

```php
// ❌ WRONG — renderUsing silently ignored
Column::make('price')->renderUsing(function (Column $col, $value) { ... });

// ✅ CORRECT
FormattedColumn::make('price')
    ->formatted(fn ($value) => format_price($value));

// ❌ WRONG type-hint — TypeError
ImageColumn::make('image')->getValueUsing(fn (Column $col) => ...);

// ✅ CORRECT type-hint
ImageColumn::make('image')->getValueUsing(fn (ImageColumn $col) => ...);
```

### Product Image Eager Loading

> [!WARNING]
> The `image` accessor depends on the `images` field as fallback. Always include both.

```php
// ❌ WRONG — image accessor may return null
->with('product:id,name,image')

// ✅ CORRECT
->with('product:id,name,image,images')
```

### All Column Types

`IdColumn`, `NameColumn`, `ImageColumn`, `StatusColumn`, `CreatedAtColumn`, `UpdatedAtColumn`, `DateColumn`, `DateTimeColumn`, `FormattedColumn`, `EnumColumn`, `LinkableColumn`, `EmailColumn`, `PhoneColumn`, `YesNoColumn`, `CheckboxColumn`, `RowActionsColumn`

### Column Customization Methods

```php
$column
    ->visible(false)
    ->orderable(false)
    ->searchable(false)
    ->exportable(false)
    ->getValueUsing(fn ($col) => ...)
    ->renderUsing(fn ($col, $value) => ...)
    ->append(fn ($col) => '<span>...</span>')
    ->alignStart() / ->alignCenter() / ->alignEnd()
    ->withColor('success')
    ->withIcon('ti ti-check')
    ->withEmptyState('N/A')
    ->copyable()
    ->blur()
```

### Disabling the Operations Column

For read-only tables (audit logs, stock movements):

```php
class MyReadOnlyTable extends TableAbstract
{
    protected $hasOperations = false;  // ✅ CORRECT
    // NOT ->addActions([]) — empty array doesn't disable it
}
```

## Controller Pattern

> [!CAUTION]
> Modern Botble controllers are **thin**. They extend `BaseController`, delegate rendering to the Form class, and delegate deletion to `DeleteResourceAction`. Do **not** generate controllers that inject repositories, build responses manually, or call `findOrFail()`.

```php
use Botble\Base\Http\Actions\DeleteResourceAction;
use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Supports\Breadcrumb;

class FaqController extends BaseController
{
    protected function breadcrumb(): Breadcrumb
    {
        return parent::breadcrumb()
            ->add(trans('plugins/faq::faq.name'), route('faq.index'));
    }

    public function index(FaqTable $table)
    {
        $this->pageTitle(trans('plugins/faq::faq.name'));

        return $table->renderTable();
    }

    public function create()
    {
        $this->pageTitle(trans('plugins/faq::faq.create'));

        return FaqForm::create()->renderForm();
    }

    public function store(FaqRequest $request)
    {
        $form = FaqForm::create()->setRequest($request);
        $form->save();

        return $this
            ->httpResponse()
            ->setPreviousRoute('faq.index')
            ->setNextRoute('faq.edit', $form->getModel()->getKey())
            ->withCreatedSuccessMessage();
    }

    public function edit(Faq $faq)
    {
        $this->pageTitle(trans('core/base::forms.edit_item', ['name' => $faq->question]));

        return FaqForm::createFromModel($faq)->renderForm();
    }

    public function update(Faq $faq, FaqRequest $request)
    {
        FaqForm::createFromModel($faq)->setRequest($request)->save();

        return $this->httpResponse()->setPreviousRoute('faq.index')->withUpdatedSuccessMessage();
    }

    public function destroy(Faq $faq)
    {
        return DeleteResourceAction::make($faq);
    }
}
```

### Key Points

| Element | Rule |
|---------|------|
| Base class | Always `BaseController` — never plain `Controller` |
| Page title | `$this->pageTitle(...)` — not a `$data['title']` array |
| Breadcrumb | Override `protected function breadcrumb(): Breadcrumb` |
| Create form | `MyForm::create()->renderForm()` |
| Edit form | `MyForm::createFromModel($model)->renderForm()` |
| Save | `->setRequest($request)->save()` — form handles persistence |
| Delete | `DeleteResourceAction::make($model)` — handles permissions, events, response |
| Model resolution | Route model binding (`edit(Faq $faq)`) — auto-404, supports int + UUID |

## Hooks System

```php
// Actions - Execute code at specific points
do_action('event_name', $param1, $param2);
add_action('event_name', $callback, priority: 20);

// Filters - Modify values
$value = apply_filters('filter_name', $value, $param);
add_filter('filter_name', $callback, priority: 20);
```

### Common Base Hooks

| Hook | Type | Purpose |
|------|------|---------|
| `BASE_ACTION_META_BOXES` | Action | Render meta boxes |
| `BASE_FILTER_BEFORE_RENDER_FORM` | Filter | Before form renders |
| `BASE_ACTION_AFTER_CREATE_CONTENT` | Action | After content created |
| `BASE_ACTION_AFTER_UPDATE_CONTENT` | Action | After content updated |
| `BASE_ACTION_AFTER_DELETE_CONTENT` | Action | After content deleted |
| `DASHBOARD_FILTER_ADMIN_LIST` | Filter | Dashboard widgets |
| `BASE_FILTER_ENUM_ARRAY` | Filter | Extend enum values |
| `BASE_FILTER_ENUM_LABEL` | Filter | Customize enum labels |
| `BASE_FILTER_ENUM_HTML` | Filter | Enum HTML badge |

## Routes

### Admin Routes

```php
use Botble\Base\Facades\AdminHelper;

AdminHelper::registerRoutes(function(): void {
    Route::group(['prefix' => 'my-plugin', 'as' => 'my-plugin.'], function(): void {
        Route::resource('', 'MyController')->parameters(['' => 'item']);
    });
});
```

### Route Model Binding (Preferred)

Automatically resolves both int and UUID IDs. Route parameter name in `parameters()` must match controller method parameter name:

```php
public function edit(MyModel $item)     // auto-resolved, auto-404
public function destroy(MyModel $item)  // cleaner, no findOrFail()
```

### Public/Theme Routes

```php
use Botble\Theme\Facades\Theme;

Theme::registerRoutes(function(): void {
    Route::get('search', ['as' => 'public.search', 'uses' => 'PublicController@getSearch']);
});
```

### Controller Response Helpers

```php
return $this->httpResponse()
    ->setNextRoute('my-plugin.edit', $form->getModel())
    ->withCreatedSuccessMessage();

return $this->httpResponse()->withUpdatedSuccessMessage();
return $this->httpResponse()->withDeletedSuccessMessage();
```

## Security Best Practices

### XSS Prevention in Blade

```php
// For HTML contexts - use BaseHelper::clean()
{!! BaseHelper::clean($userContent) !!}

// For JavaScript contexts - use @json directive
// <script> var data = @json($variable); </script>

// Default - auto-escapes HTML
// Use Blade double curly braces: {{ $variable }}
```

### CSRF in AJAX

```javascript
headers: {'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')}
```

### Cookie Security

```php
// ❌ WRONG
$mode = $_COOKIE['theme_mode'];

// ✅ CORRECT — with allowlist validation
$mode = request()->cookie('theme_mode');
$mode = in_array($mode, ['light', 'dark']) ? $mode : 'light';
```

```js
// JS cookie must have security flags
document.cookie = `theme_mode=${mode}; path=/; Secure; SameSite=Lax; max-age=31536000`;
```

## UI Components (Tabler)

### Badge Rule

> [!CAUTION]
> Always use BOTH `bg-{color}` AND `text-{color}-fg` together. Never use `bg-{color}` alone — text becomes invisible.

```html
<!-- ❌ WRONG -->
<span class="badge bg-green">Active</span>

<!-- ✅ CORRECT -->
<span class="badge bg-green text-green-fg">Active</span>
```

Available colors: `blue`, `azure`, `indigo`, `purple`, `pink`, `red`, `orange`, `yellow`, `lime`, `green`, `teal`, `cyan`

Light variants: append `-lt` (e.g., `bg-green-lt`) — these don't need the `-fg` suffix.

Do NOT use Bootstrap colors (`bg-success`, `bg-danger`) for badges in Tabler UI.

### Dashboard Widget Pattern

```php
add_filter(DASHBOARD_FILTER_ADMIN_LIST, function (array $widgets, Collection $widgetSettings) {
    return (new DashboardWidgetInstance())
        ->setType('stats')
        ->setPermission('my-plugin.index')
        ->setKey('widget_my_plugin_count')
        ->setTitle(trans('...'))
        ->setIcon('ti ti-chart-bar')
        ->setColor('primary')
        ->setStatsTotal(fn () => MyModel::query()->count())
        ->setRoute(route('my-plugin.index'))
        ->setColumn('col-12 col-md-6 col-lg-3')
        ->setPriority(99)
        ->init($widgets, $widgetSettings);
}, 99, 2);
```

### Common Admin Icons

```text
ti ti-home          Dashboard          ti ti-chart-bar     Analytics
ti ti-box           Products/Items     ti ti-mail          Email/Messages
ti ti-users         Users/Customers    ti ti-photo         Media/Images
ti ti-shopping-cart Cart/Orders        ti ti-tag           Tags/Labels
ti ti-settings      Settings           ti ti-folder        Categories
ti ti-credit-card   Payments           ti ti-truck         Shipping
ti ti-star          Reviews/Featured
```
