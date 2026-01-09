# Guía de Configuración
## Paquete Gestor de Suscripciones Laravel

**Versión:** 2.0  
**Fecha:** Enero 2026

---

## 📑 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Configuraciones Principales](#configuraciones-principales)
3. [Configuración de Pasarela de Pagos](#configuración-de-pasarela-de-pagos)
4. [Características Opcionales](#características-opcionales)
5. [Reglas de Negocio](#reglas-de-negocio)
6. [Configuraciones de Notificaciones](#configuraciones-de-notificaciones)
7. [Configuración Avanzada](#configuración-avanzada)

---

## Visión General

El archivo de configuración del paquete se encuentra en `config/subscription.php` después de publicarlo.

Todos los valores de configuración se pueden establecer a través de variables de entorno para facilitar el despliegue en diferentes entornos.

---

## Configuraciones Principales

### Modelo Suscriptor

Define qué modelo en tu aplicación puede tener suscripciones.

```php
'subscriber_model' => env('SUBSCRIPTION_SUBSCRIBER_MODEL', 'App\\Models\\User'),
```

**Variable de Entorno:**
```env
SUBSCRIPTION_SUBSCRIBER_MODEL=App\\Models\\User
```

**Ejemplos:**
```php
// Suscripciones de usuarios
'subscriber_model' => 'App\\Models\\User'

// Suscripciones de empresas
'subscriber_model' => 'App\\Models\\Company'

// Suscripciones de equipos
'subscriber_model' => 'App\\Models\\Team'
```

**Nota:** El paquete utiliza **relaciones polimórficas**, por lo que puedes tener múltiples modelos suscribibles. Solo agrega el trait `HasSubscription` a cada modelo.

---

### Configuraciones de Moneda

Definir monedas soportadas y formato.

```php
'currencies' => [
    'MXN' => [
        'symbol' => '$',
        'decimal_separator' => '.',
        'thousands_separator' => ',',
        'decimals' => 2,
    ],
    'COP' => [
        'symbol' => '$',
        'decimal_separator' => ',',
        'thousands_separator' => '.',
        'decimals' => 0,
    ],
],

'default_currency' => env('SUBSCRIPTION_DEFAULT_CURRENCY', 'MXN'),
```

**Variable de Entorno:**
```env
SUBSCRIPTION_DEFAULT_CURRENCY=MXN
```

---

### Período de Prueba

Configurar el período de prueba predeterminado para nuevas suscripciones.

```php
'trial_days' => env('SUBSCRIPTION_DEFAULT_TRIAL_DAYS', 14),
```

**Variable de Entorno:**
```env
SUBSCRIPTION_DEFAULT_TRIAL_DAYS=14
```

**Note:** Individual plans can override this with their own `trial_days` value.

---

## Payment Gateway Configuration

### Gateway Selection

Choose your payment gateway provider.

```php
'payment_gateway' => env('PAYMENT_GATEWAY', 'openpay'),
```

**Environment Variable:**
```env
PAYMENT_GATEWAY=openpay  # or stripe, mercadopago, custom
```

---

### Openpay Configuration

```php
'gateways' => [
    'openpay' => [
        'class' => \CesarAntolinez\LaravelSubscriptionManager\Gateways\OpenpayGateway::class,
        'merchant_id' => env('OPENPAY_MERCHANT_ID'),
        'private_key' => env('OPENPAY_PRIVATE_KEY'),
        'public_key' => env('OPENPAY_PUBLIC_KEY'),
        'sandbox' => env('OPENPAY_SANDBOX_MODE', true),
        'country' => env('OPENPAY_COUNTRY', 'MX'), // MX or CO
        
        // 3D Secure Settings
        '3ds_required' => env('OPENPAY_3DS_REQUIRED', true),
        '3ds_version' => env('OPENPAY_3DS_VERSION', '2.0'),
        
        // Webhook Settings
        'webhook_secret' => env('OPENPAY_WEBHOOK_SECRET'),
        'webhook_tolerance' => 300, // seconds
    ],
],
```

**Environment Variables:**
```env
OPENPAY_MERCHANT_ID=your_merchant_id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
OPENPAY_SANDBOX_MODE=true
OPENPAY_COUNTRY=MX
OPENPAY_3DS_REQUIRED=true
OPENPAY_3DS_VERSION=2.0
OPENPAY_WEBHOOK_SECRET=your_webhook_secret
```

---

### Stripe Configuration

```php
'gateways' => [
    'stripe' => [
        'class' => \CesarAntolinez\LaravelSubscriptionManager\Gateways\StripeGateway::class,
        'api_key' => env('STRIPE_SECRET'),
        'public_key' => env('STRIPE_KEY'),
        'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
        'api_version' => env('STRIPE_API_VERSION', '2023-10-16'),
    ],
],
```

**Environment Variables:**
```env
STRIPE_KEY=pk_test_your_key
STRIPE_SECRET=sk_test_your_secret
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
STRIPE_API_VERSION=2023-10-16
```

---

### Custom Gateway

You can add custom payment gateways:

```php
'gateways' => [
    'custom' => [
        'class' => \App\Gateways\CustomPaymentGateway::class,
        'api_key' => env('CUSTOM_GATEWAY_API_KEY'),
        // ... other settings
    ],
],
```

See [EXTENDING.md](./EXTENDING.md) for details on creating custom gateways.

---

## Optional Features

Enable or disable optional modules.

```php
'features' => [
    // Token consumption tracking
    'tokens' => env('SUBSCRIPTION_TOKENS_ENABLED', false),
    
    // Referral system
    'referrals' => env('SUBSCRIPTION_REFERRALS_ENABLED', false),
    
    // Electronic invoicing
    'invoicing' => env('SUBSCRIPTION_INVOICING_ENABLED', false),
],
```

**Environment Variables:**
```env
SUBSCRIPTION_TOKENS_ENABLED=true
SUBSCRIPTION_REFERRALS_ENABLED=true
SUBSCRIPTION_INVOICING_ENABLED=false
```

### Token Module Configuration

```php
'tokens' => [
    'enabled' => env('SUBSCRIPTION_TOKENS_ENABLED', false),
    
    // Alert thresholds (percentage)
    'alert_thresholds' => [50, 75, 90, 100],
    
    // Reset on renewal
    'reset_on_renewal' => true,
    
    // Carry over unused tokens
    'carry_over' => false,
],
```

**Environment Variables:**
```env
SUBSCRIPTION_TOKENS_ENABLED=true
SUBSCRIPTION_TOKENS_CARRY_OVER=false
```

### Referral Module Configuration

```php
'referrals' => [
    'enabled' => env('SUBSCRIPTION_REFERRALS_ENABLED', false),
    
    // Default referrer benefit
    'referrer_benefit' => [
        'type' => 'percentage',
        'value' => 20,
        'duration_months' => 1,
    ],
    
    // Default referred benefit
    'referred_benefit' => [
        'type' => 'percentage',
        'value' => 10,
        'duration_months' => 1,
    ],
    
    // Code generation
    'code_length' => 8,
    'code_prefix' => 'REF',
],
```

**Environment Variables:**
```env
SUBSCRIPTION_REFERRALS_ENABLED=true
SUBSCRIPTION_REFERRAL_CODE_PREFIX=REF
```

### Invoicing Module Configuration

```php
'invoicing' => [
    'enabled' => env('SUBSCRIPTION_INVOICING_ENABLED', false),
    
    // Invoice providers by country
    'providers' => [
        'MX' => [
            'pac_provider' => env('INVOICE_PAC_PROVIDER', 'facturapi'),
            'api_key' => env('INVOICE_PAC_API_KEY'),
        ],
        'CO' => [
            'dian_provider' => env('INVOICE_DIAN_PROVIDER', 'alegra'),
            'api_key' => env('INVOICE_DIAN_API_KEY'),
        ],
    ],
    
    // Storage
    'storage_disk' => env('INVOICE_STORAGE_DISK', 'local'),
    'storage_path' => 'invoices',
],
```

---

## Business Rules

### Grace Period

Configure how grace periods work after payment failures.

```php
'grace_period' => [
    // Duration in months
    'months' => env('SUBSCRIPTION_GRACE_PERIOD_MONTHS', 2),
    
    // Allow access during grace period
    'allow_access' => true,
    
    // Reminder frequency (days)
    'reminder_frequency' => 15,
    
    // Block after grace period expires
    'block_on_expiry' => true,
],
```

**Environment Variables:**
```env
SUBSCRIPTION_GRACE_PERIOD_MONTHS=2
SUBSCRIPTION_GRACE_REMINDER_DAYS=15
```

---

### Payment Retries

Configure automatic payment retry behavior.

```php
'payment_retries' => [
    // Maximum retry attempts
    'max_attempts' => env('SUBSCRIPTION_MAX_PAYMENT_RETRIES', 3),
    
    // Days between retries
    'retry_schedule' => [3, 7, 14], // 3rd day, 7th day, 14th day
    
    // Enter grace period after all retries fail
    'grace_period_on_failure' => true,
],
```

**Environment Variables:**
```env
SUBSCRIPTION_MAX_PAYMENT_RETRIES=3
SUBSCRIPTION_RETRY_DAYS=3,7,14
```

---

### Plan Changes

Configure how plan upgrades and downgrades work.

```php
'plan_changes' => [
    // Upgrade behavior
    'upgrade' => [
        'immediate' => true, // Apply immediately
        'prorate' => true,   // Prorate the difference
        'charge_immediately' => true,
    ],
    
    // Downgrade behavior
    'downgrade' => [
        'immediate' => false, // Schedule for next renewal
        'refund' => false,    // No refund on downgrade
    ],
],
```

---

### Subscription Cancellation

```php
'cancellation' => [
    // Allow cancellation
    'allow_cancellation' => true,
    
    // Access until end of period
    'access_until_end' => true,
    
    // Require feedback
    'require_feedback' => true,
    
    // Cancellation reasons
    'feedback_options' => [
        'too_expensive',
        'not_using',
        'missing_features',
        'switching_to_competitor',
        'other',
    ],
],
```

---

## Notification Settings

### Email Configuration

```php
'notifications' => [
    // Enable notifications
    'enabled' => env('SUBSCRIPTION_NOTIFICATIONS_ENABLED', true),
    
    // From address
    'from' => [
        'address' => env('SUBSCRIPTION_NOTIFICATION_FROM_ADDRESS', 'noreply@example.com'),
        'name' => env('SUBSCRIPTION_NOTIFICATION_FROM_NAME', 'Subscription Service'),
    ],
    
    // Queue notifications
    'queue' => env('SUBSCRIPTION_NOTIFICATIONS_QUEUE', true),
    'queue_connection' => env('SUBSCRIPTION_NOTIFICATIONS_QUEUE_CONNECTION', 'redis'),
    
    // Notification types enabled
    'types' => [
        'welcome' => true,
        'payment_success' => true,
        'payment_failed' => true,
        'payment_reminder' => true,
        'trial_expiring' => true,
        'grace_period_start' => true,
        'subscription_cancelled' => true,
        'plan_changed' => true,
        'authentication_required' => true, // 3DS
        'tokens_50' => true,
        'tokens_75' => true,
        'tokens_90' => true,
        'tokens_100' => true,
        // ... more types
    ],
    
    // Timing
    'trial_expiry_warning_days' => 3, // Warn 3 days before trial expires
    'payment_reminder_days' => 3,     // Remind 3 days before billing
],
```

**Environment Variables:**
```env
SUBSCRIPTION_NOTIFICATIONS_ENABLED=true
SUBSCRIPTION_NOTIFICATION_FROM_ADDRESS=noreply@example.com
SUBSCRIPTION_NOTIFICATION_FROM_NAME="My App Subscriptions"
SUBSCRIPTION_NOTIFICATIONS_QUEUE=true
```

---

## Advanced Configuration

### Audit Logging

```php
'audit' => [
    // Enable audit logging
    'enabled' => true,
    
    // Log all actions
    'log_all' => true,
    
    // Specific actions to log
    'actions' => [
        'subscription_created',
        'subscription_updated',
        'subscription_cancelled',
        'payment_processed',
        'payment_failed',
        'plan_changed',
        'coupon_applied',
    ],
    
    // Retention period (days, null = forever)
    'retention_days' => null,
],
```

---

### Caching

```php
'cache' => [
    // Enable caching
    'enabled' => true,
    
    // Cache driver
    'driver' => env('CACHE_DRIVER', 'redis'),
    
    // Cache TTL (seconds)
    'ttl' => [
        'plans' => 3600,        // 1 hour
        'subscription' => 300,  // 5 minutes
        'coupons' => 1800,      // 30 minutes
    ],
    
    // Cache prefixes
    'prefix' => 'subscription:',
],
```

---

### Webhooks

```php
'webhooks' => [
    // Verify webhook signatures
    'verify_signature' => true,
    
    // Signature tolerance (seconds)
    'signature_tolerance' => 300,
    
    // Log webhooks
    'log_all' => env('SUBSCRIPTION_LOG_WEBHOOKS', true),
    
    // Webhook event handlers
    'handlers' => [
        'charge.succeeded' => \CesarAntolinez\LaravelSubscriptionManager\Webhooks\ChargeSucceededHandler::class,
        'charge.failed' => \CesarAntolinez\LaravelSubscriptionManager\Webhooks\ChargeFailedHandler::class,
        'charge.refunded' => \CesarAntolinez\LaravelSubscriptionManager\Webhooks\ChargeRefundedHandler::class,
    ],
],
```

---

### Database

```php
'database' => [
    // Table prefix
    'table_prefix' => env('SUBSCRIPTION_TABLE_PREFIX', ''),
    
    // Connection (null = default)
    'connection' => env('SUBSCRIPTION_DB_CONNECTION', null),
    
    // Use transactions
    'use_transactions' => true,
],
```

---

### Testing

```php
'testing' => [
    // Disable actual payment processing in tests
    'fake_payments' => env('SUBSCRIPTION_FAKE_PAYMENTS', false),
    
    // Disable notifications in tests
    'fake_notifications' => env('SUBSCRIPTION_FAKE_NOTIFICATIONS', false),
    
    // Fast-forward time in tests
    'allow_time_travel' => env('SUBSCRIPTION_ALLOW_TIME_TRAVEL', false),
],
```

---

## Environment-Specific Configuration

### Development

```env
APP_ENV=local

# Payment
PAYMENT_GATEWAY=openpay
OPENPAY_SANDBOX_MODE=true

# Notifications
SUBSCRIPTION_NOTIFICATIONS_ENABLED=true
MAIL_MAILER=log

# Testing
SUBSCRIPTION_FAKE_PAYMENTS=false
```

### Staging

```env
APP_ENV=staging

# Payment
PAYMENT_GATEWAY=openpay
OPENPAY_SANDBOX_MODE=true

# Notifications
SUBSCRIPTION_NOTIFICATIONS_ENABLED=true

# Webhooks
SUBSCRIPTION_LOG_WEBHOOKS=true
```

### Production

```env
APP_ENV=production

# Payment
PAYMENT_GATEWAY=openpay
OPENPAY_SANDBOX_MODE=false

# Notifications
SUBSCRIPTION_NOTIFICATIONS_ENABLED=true
SUBSCRIPTION_NOTIFICATIONS_QUEUE=true

# Cache
CACHE_DRIVER=redis

# Queue
QUEUE_CONNECTION=redis
```

---

## Configuration Examples

### Example 1: SaaS with Token Limits

```php
// config/subscription.php
return [
    'subscriber_model' => 'App\\Models\\User',
    
    'features' => [
        'tokens' => true,
        'referrals' => true,
        'invoicing' => false,
    ],
    
    'tokens' => [
        'enabled' => true,
        'alert_thresholds' => [50, 75, 90, 100],
        'carry_over' => false,
    ],
];
```

### Example 2: B2B with Company Subscriptions

```php
// config/subscription.php
return [
    'subscriber_model' => 'App\\Models\\Company',
    
    'features' => [
        'tokens' => false,
        'referrals' => false,
        'invoicing' => true,
    ],
    
    'trial_days' => 30,
    
    'grace_period' => [
        'months' => 3,
        'reminder_frequency' => 7,
    ],
];
```

### Example 3: Multi-Tenant with Team Subscriptions

```php
// config/subscription.php
return [
    'subscriber_model' => 'App\\Models\\Team',
    
    'features' => [
        'tokens' => true,
        'referrals' => true,
        'invoicing' => false,
    ],
    
    'plan_changes' => [
        'upgrade' => [
            'immediate' => true,
            'prorate' => true,
        ],
        'downgrade' => [
            'immediate' => false,
        ],
    ],
];
```

---

## Períodos Personalizables

El paquete permite personalizar tanto el trial como el grace period a nivel de **suscripción individual**.

### Configuración Global (Defaults)

```php
'defaults' => [
    // Trial por defecto si el plan no especifica
    'trial_days' => env('SUBSCRIPTION_DEFAULT_TRIAL_DAYS', 14),
    
    // Grace period por defecto si la suscripción no especifica
    'grace_period_months' => env('SUBSCRIPTION_DEFAULT_GRACE_MONTHS', 2),
],
```

### Personalización por Suscripción

**Trial Personalizado:**
```php
// Trial estándar (hereda del plan)
$user->subscribeToPlan($plan);

// Trial personalizado de 60 días (promoción)
$user->subscribeToPlan($plan, ['trial_days' => 60]);

// Sin trial (pago inmediato)
$user->subscribeToPlan($plan, ['trial_days' => 0]);
```

**Grace Period Personalizado:**
```php
// Grace period estándar (2 meses)
$subscription = $user->subscription;

// Grace period extendido para cliente premium
$subscription->update(['grace_period_months' => 6]);

// Sin grace period (bloqueo inmediato)
$subscription->update(['grace_period_months' => 0]);
```

### Variables de Entorno

```env
# Defaults globales
SUBSCRIPTION_DEFAULT_TRIAL_DAYS=14
SUBSCRIPTION_DEFAULT_GRACE_MONTHS=2

# Permitir personalización
SUBSCRIPTION_ALLOW_CUSTOM_TRIAL=true
SUBSCRIPTION_ALLOW_CUSTOM_GRACE=true
```

---

## Configuration Validation

Run the configuration validation command:

```bash
php artisan subscription:validate-config
```

This will check:
- ✅ Required configuration values present
- ✅ Subscriber model exists
- ✅ Payment gateway configured correctly
- ✅ Optional features configured properly
- ✅ Environment variables set

---

## Next Steps

- **Installation:** See [INSTALLATION.md](./INSTALLATION.md)
- **Usage:** See [POLYMORPHIC_RELATIONSHIPS.md](./POLYMORPHIC_RELATIONSHIPS.md)
- **Customization:** See [EXTENDING.md](./EXTENDING.md)

---

**Version:** 2.0  
**Last Updated:** January 2026

---

**End of Document**
