# Ecommerce & Payment Gateways (`services/cms`)

## Key Models Hierarchy

```text
Product (configurable or simple)
├── ProductVariation → ProductVariationItem
├── ProductAttributeSet → ProductAttribute
├── SpecificationGroup → SpecificationAttribute
├── FlashSale
└── ProductCategory, ProductTag, ProductCollection
```

## Order Lifecycle

```text
PENDING → PROCESSING → COMPLETED
PENDING → PROCESSING → CANCELED
COMPLETED → PARTIAL_RETURNED → RETURNED
```

## Key Ecommerce Enums

```php
OrderStatusEnum:    PENDING, PROCESSING, COMPLETED, CANCELED, PARTIAL_RETURNED, RETURNED
PaymentStatusEnum:  PENDING, APPROVED, FAILED, REFUNDED
ShippingStatusEnum: PENDING, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, FAILED
ProductTypeEnum:    PHYSICAL, DIGITAL
StockStatusEnum:    IN_STOCK, OUT_OF_STOCK, LOW_STOCK
```

Always use `->getValue()` for ALL ecommerce enum comparisons.

## Key Ecommerce Hooks

| Hook | Type | Purpose |
|------|------|---------|
| `ACTION_AFTER_ORDER_STATUS_COMPLETED_ECOMMERCE` | Action | Order completed |
| `PAYMENT_ACTION_PAYMENT_PROCESSED` | Action | Payment recorded |
| `ecommerce_create_order_from_data` | Action | Order created |
| `PAYMENT_FILTER_AFTER_POST_CHECKOUT` | Filter | After checkout |
| `ecommerce_cart_data_for_response` | Filter | Cart response |
| `ecommerce_products_filter` | Filter | Products query |
| `ecommerce_calculate_shipping_fee` | Filter | Shipping fee |
| `ecommerce_invoice_header/footer` | Filter | Invoice customization |

## EcommerceHelper Facade

```php
EcommerceHelper::isCartEnabled()
EcommerceHelper::withProductEagerLoadingRelations($query)
EcommerceHelper::viewPath('includes.filters')
EcommerceHelper::jsAttributes('add-to-cart', $product)
EcommerceHelper::jsAttributes('quick-shop', $product)
```

## Payment Gateway Integration (6-Step Pattern)

1. Create `helpers/constants.php` defining `MY_GATEWAY_PAYMENT_METHOD_NAME`
2. Register 8 filters in `HookServiceProvider` (checkout UI, process, settings, 3 enum filters, service class, detail)
3. Implement `MyGatewayPaymentService` with `execute()` + `refundOrder()` + `PaymentErrorTrait`
4. Add webhook controller with signature verification + idempotency check
5. Routes: webhook must bypass CSRF with `->withoutMiddleware([VerifyCsrfToken::class])`, plus success/error routes
6. Settings form extending `PaymentMethodForm` with `paymentFeeField()`

## Infinite Scroll Pattern

```php
// Blade template for infinite scroll
// <div class="bb-infinite-products-grid" data-url="{{ $products->nextPageUrl() }}">
// <button class="bb-load-more-btn">Load More</button>
```
