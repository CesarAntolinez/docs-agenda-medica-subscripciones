# Installation Guide
## Laravel Subscription Manager Package

**Version:** 2.0  
**Date:** January 2026

---

## 📑 Table of Contents

1. [Requirements](#requirements)
2. [Installation via Composer](#installation-via-composer)
3. [Configuration](#configuration)
4. [Database Setup](#database-setup)
5. [Model Setup](#model-setup)
6. [Payment Gateway Setup](#payment-gateway-setup)
7. [Queue Configuration](#queue-configuration)
8. [Verification](#verification)

---

## Requirements

### System Requirements

- **PHP:** 8.1 or higher
- **Laravel:** 10.x or 11.x
- **Database:** MySQL 8.0+ / PostgreSQL 13+ / MariaDB 10.5+
- **PHP Extensions:**
  - PDO
  - Mbstring
  - JSON
  - OpenSSL
  - BCMath (recommended for currency calculations)

### Recommended

- **Redis:** For queue and cache (optional but recommended)
- **Supervisor:** For queue workers in production
- **Composer:** 2.x

---

## Installation via Composer

### Step 1: Install the Package

```bash
composer require cesarantolinez/laravel-subscription-manager
```

### Step 2: Publish Configuration Files

Publish the package configuration file:

```bash
php artisan vendor:publish --tag=subscription-config
```

This creates `config/subscription.php` with default settings.

### Step 3: Publish Migrations

Publish the database migrations:

```bash
php artisan vendor:publish --tag=subscription-migrations
```

**Optional Module Migrations:**

If you want to use optional features, publish their migrations:

```bash
# Publish tokens module migration
php artisan vendor:publish --tag=subscription-migrations-tokens

# Publish referrals module migration
php artisan vendor:publish --tag=subscription-migrations-referrals

# Publish invoicing module migration
php artisan vendor:publish --tag=subscription-migrations-invoicing
```

### Step 4: Publish Views (Optional)

If you want to customize notification email templates:

```bash
php artisan vendor:publish --tag=subscription-views
```

### Step 5: Publish Translations (Optional)

If you want to customize notification messages:

```bash
php artisan vendor:publish --tag=subscription-lang
```

---

## Configuration

### Step 1: Configure Environment Variables

Add the following to your `.env` file:

```env
# ============================================================================
# Subscription Package Configuration
# ============================================================================

# Subscriber Model (the model that will have subscriptions)
SUBSCRIPTION_SUBSCRIBER_MODEL=App\\Models\\User

# Payment Gateway
PAYMENT_GATEWAY=openpay

# Openpay Configuration (if using Openpay)
OPENPAY_MERCHANT_ID=your-merchant-id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
OPENPAY_SANDBOX_MODE=true
OPENPAY_COUNTRY=MX  # MX or CO

# Stripe Configuration (if using Stripe)
STRIPE_KEY=pk_test_your_key
STRIPE_SECRET=sk_test_your_secret
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Optional Features
SUBSCRIPTION_TOKENS_ENABLED=true
SUBSCRIPTION_REFERRALS_ENABLED=true
SUBSCRIPTION_INVOICING_ENABLED=false

# Trial Configuration
SUBSCRIPTION_DEFAULT_TRIAL_DAYS=14

# Grace Period Configuration
SUBSCRIPTION_GRACE_PERIOD_MONTHS=2

# Payment Retry Configuration
SUBSCRIPTION_MAX_PAYMENT_RETRIES=3
SUBSCRIPTION_RETRY_DAYS=3,7,14  # Days between retries

# Notification Configuration
SUBSCRIPTION_NOTIFICATIONS_ENABLED=true
SUBSCRIPTION_NOTIFICATION_FROM_ADDRESS=noreply@example.com
SUBSCRIPTION_NOTIFICATION_FROM_NAME="Subscription Service"
```

### Step 2: Configure Subscriber Model

In your `config/subscription.php`, verify the subscriber model:

```php
'subscriber_model' => env('SUBSCRIPTION_SUBSCRIBER_MODEL', 'App\\Models\\User'),
```

---

## Database Setup

### Step 1: Review Migrations

Before running migrations, review the published migration files in `database/migrations/`:

- Core migrations (always run):
  - `xxxx_xx_xx_create_plans_table.php`
  - `xxxx_xx_xx_create_subscriptions_table.php`
  - `xxxx_xx_xx_create_payments_table.php`
  - `xxxx_xx_xx_create_payment_retries_table.php`
  - `xxxx_xx_xx_create_grace_periods_table.php`
  - `xxxx_xx_xx_create_coupons_table.php`
  - `xxxx_xx_xx_create_subscriber_coupons_table.php`
  - `xxxx_xx_xx_create_billing_data_table.php`
  - `xxxx_xx_xx_create_notifications_table.php`
  - `xxxx_xx_xx_create_audit_logs_table.php`

- Optional migrations (only if features enabled):
  - `xxxx_xx_xx_create_tokens_usage_table.php`
  - `xxxx_xx_xx_create_referrals_table.php`
  - `xxxx_xx_xx_create_invoices_table.php`

### Step 2: Run Migrations

```bash
php artisan migrate
```

This will create all the necessary tables in your database.

### Step 3: Seed Sample Plans (Optional)

Create a seeder for your subscription plans:

```bash
php artisan make:seeder SubscriptionPlanSeeder
```

Example seeder content:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SubscriptionPlanSeeder extends Seeder
{
    public function run()
    {
        DB::table('plans')->insert([
            [
                'name' => 'Starter Plan',
                'description' => 'Perfect for individuals and small teams',
                'tokens_monthly' => 5000,
                'periodicity' => 'monthly',
                'price_mxn' => 299.00,
                'price_cop' => 50000.00,
                'trial_days' => 14,
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Professional Plan',
                'description' => 'For growing businesses',
                'tokens_monthly' => 10000,
                'periodicity' => 'monthly',
                'price_mxn' => 499.00,
                'price_cop' => 80000.00,
                'trial_days' => 14,
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Enterprise Plan',
                'description' => 'For large organizations',
                'tokens_monthly' => 20000,
                'periodicity' => 'monthly',
                'price_mxn' => 899.00,
                'price_cop' => 150000.00,
                'trial_days' => 14,
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
```

Run the seeder:

```bash
php artisan db:seed --class=SubscriptionPlanSeeder
```

---

## Model Setup

### Step 1: Add Trait to Your Subscriber Model

Add the `HasSubscription` trait to any model you want to make subscribable.

**Example: User Model**

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class User extends Authenticatable
{
    use HasSubscription;

    // ... rest of your model
}
```

**Example: Company Model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class Company extends Model
{
    use HasSubscription;

    // ... rest of your model
}
```

**Example: Team Model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class Team extends Model
{
    use HasSubscription;

    // ... rest of your model
}
```

### Step 2: Verify Trait Methods

The `HasSubscription` trait provides the following methods:

```php
// Subscribe to a plan
$user->subscribeToPlan($plan, $periodicity, $cardToken);

// Get active subscription
$subscription = $user->activeSubscription();

// Check subscription status
$user->hasActiveSubscription();
$user->isOnTrial();
$user->isOnGracePeriod();

// Cancel subscription
$user->cancelSubscription();

// Get subscription history
$subscriptions = $user->subscriptions;

// Get billing data
$billingData = $user->billingData;

// Apply coupon
$user->applyCoupon($coupon);

// Get notifications
$notifications = $user->subscriptionNotifications;
```

---

## Payment Gateway Setup

### Openpay Setup

#### Step 1: Create Openpay Account

1. Go to [Openpay](https://www.openpay.mx/) (Mexico) or [Openpay Colombia](https://www.openpay.co/)
2. Create a merchant account
3. Obtain your credentials:
   - Merchant ID
   - Private Key
   - Public Key

#### Step 2: Configure Openpay

Update your `.env`:

```env
PAYMENT_GATEWAY=openpay
OPENPAY_MERCHANT_ID=your_merchant_id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
OPENPAY_SANDBOX_MODE=true  # Set to false in production
OPENPAY_COUNTRY=MX  # or CO
```

#### Step 3: Setup Webhooks

Configure webhooks in your Openpay dashboard:

**Webhook URL:**
```
https://yourdomain.com/api/subscriptions/webhooks/openpay
```

**Events to subscribe:**
- `charge.succeeded`
- `charge.failed`
- `charge.refunded`
- `charge.cancelled`

### Stripe Setup (Alternative)

#### Step 1: Create Stripe Account

1. Go to [Stripe](https://stripe.com/)
2. Create an account
3. Obtain API keys from Dashboard

#### Step 2: Configure Stripe

Update your `.env`:

```env
PAYMENT_GATEWAY=stripe
STRIPE_KEY=pk_test_your_key
STRIPE_SECRET=sk_test_your_secret
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

#### Step 3: Setup Webhooks

Configure webhooks in Stripe dashboard:

**Webhook URL:**
```
https://yourdomain.com/api/subscriptions/webhooks/stripe
```

---

## Queue Configuration

### Step 1: Configure Queue Driver

The package uses queues for background processing. Configure your queue driver in `.env`:

```env
QUEUE_CONNECTION=redis  # or database, sqs, etc.
```

### Step 2: Start Queue Worker

For development:

```bash
php artisan queue:work
```

For production, use Supervisor:

**Create supervisor config** (`/etc/supervisor/conf.d/laravel-worker.conf`):

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/your/project/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/path/to/your/project/storage/logs/worker.log
stopwaitsecs=3600
```

Reload Supervisor:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-worker:*
```

---

## Verification

### Step 1: Verify Installation

Run the package verification command:

```bash
php artisan subscription:verify
```

This will check:
- ✅ Config file exists
- ✅ Migrations ran successfully
- ✅ Subscriber model exists and uses trait
- ✅ Payment gateway configured
- ✅ Queue configured

### Step 2: Test Subscription Creation

Test creating a subscription in `tinker`:

```bash
php artisan tinker
```

```php
// Get a user and a plan
$user = App\Models\User::first();
$plan = DB::table('plans')->first();

// Subscribe
$subscription = $user->subscribeToPlan($plan);

// Check
$user->hasActiveSubscription(); // should return true
```

### Step 3: Verify Webhook Endpoint

Test that your webhook endpoint is accessible:

```bash
curl -X POST https://yourdomain.com/api/subscriptions/webhooks/openpay \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

Should return a response (may be an error if signature is invalid, but endpoint should be reachable).

---

## Troubleshooting

### Common Issues

**Issue: Migrations fail**
```
Solution: Ensure your database connection is configured correctly in .env
Check: php artisan migrate:status
```

**Issue: Trait not found**
```
Solution: Run composer dump-autoload
Command: composer dump-autoload
```

**Issue: Queue jobs not processing**
```
Solution: Ensure queue worker is running
Check: ps aux | grep "queue:work"
Start: php artisan queue:work
```

**Issue: Webhooks not receiving events**
```
Solution: 
1. Verify webhook URL is publicly accessible
2. Check webhook signature validation
3. Review logs: storage/logs/laravel.log
```

---

## Next Steps

After successful installation:

1. **Configuration:** See [CONFIGURATION.md](./CONFIGURATION.md) for detailed configuration options
2. **Usage:** See [POLYMORPHIC_RELATIONSHIPS.md](./POLYMORPHIC_RELATIONSHIPS.md) for usage examples
3. **Extending:** See [EXTENDING.md](./EXTENDING.md) for customization options
4. **Database:** See [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) for database details

---

## Support

**Documentation:** https://github.com/CesarAntolinez/laravel-subscription-manager/docs  
**Issues:** https://github.com/CesarAntolinez/laravel-subscription-manager/issues  
**Discussions:** https://github.com/CesarAntolinez/laravel-subscription-manager/discussions

---

**Version:** 2.0  
**Last Updated:** January 2026

---

**End of Document**
