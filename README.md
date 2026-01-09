# Laravel Subscription Manager

Complete subscription management package for Laravel with multi-gateway support, 3D Secure, polymorphic relationships, and more.

[![PHP Version](https://img.shields.io/badge/PHP-8.1%2B-blue)](https://www.php.net/)
[![Laravel Version](https://img.shields.io/badge/Laravel-10.x%20%7C%2011.x-red)](https://laravel.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-success)](https://github.com/CesarAntolinez/laravel-subscription-manager)

---

## 🚀 Features

- ✅ **Polymorphic Relationships** - Subscribe Users, Companies, Teams, any model
- ✅ **Multi-Gateway Support** - Openpay, Stripe, Mercadopago (abstracted interface)
- ✅ **3D Secure 2.0** - Full PSD2 compliance implementation
- ✅ **Discount Coupons** - Percentage, fixed amount, duration-based (CORE feature)
- ✅ **Trial Periods** - Configurable trial days per plan
- ✅ **Grace Periods** - Handle failed payments gracefully (2 months default)
- ✅ **Payment Retries** - Automatic retry mechanism with configurable attempts
- ✅ **Webhooks** - Process payment events asynchronously
- ⚙️ **Optional Tokens** - Consumption-based billing module
- ⚙️ **Optional Referrals** - Complete referral system
- ⚙️ **Optional Invoicing** - Electronic invoicing (PAC/DIAN)
- 🔒 **Audit Logging** - Complete audit trail for compliance
- 📧 **20+ Notifications** - Transactional emails for all events

---

## 📖 Documentation

### Getting Started
- **[Installation Guide](./docs/INSTALLATION.md)** - Step-by-step installation
- **[Configuration](./docs/CONFIGURATION.md)** - Configuration options
- **[Polymorphic Relationships](./docs/POLYMORPHIC_RELATIONSHIPS.md)** - Usage guide

### Reference
- **[Package Features](./docs/PACKAGE_FEATURES.md)** - Complete feature list
- **[Database Schema](./docs/DATABASE_SCHEMA.md)** - Database structure
- **[API & Webhooks](./docs/API_WEBHOOKS.md)** - API endpoints
- **[3D Secure Integration](./docs/3DS_INTEGRATION.md)** - 3DS implementation
- **[Architecture](./docs/ARCHITECTURE.md)** - System architecture
- **[Use Cases](./docs/USE_CASES.md)** - Detailed use cases
- **[User Flows](./docs/USER_FLOWS.md)** - Flow diagrams

### Advanced
- **[Extending the Package](./docs/EXTENDING.md)** - Customization guide
- **[Recommendations](./docs/RECOMMENDATIONS.md)** - Best practices

---

## 🎯 Quick Start

### 1. Install via Composer

```bash
composer require cesarantolinez/laravel-subscription-manager
```

### 2. Publish Configuration & Migrations

```bash
php artisan vendor:publish --tag=subscription-config
php artisan vendor:publish --tag=subscription-migrations
php artisan migrate
```

### 3. Configure Environment

```env
# .env
SUBSCRIPTION_SUBSCRIBER_MODEL=App\\Models\\User
PAYMENT_GATEWAY=openpay
OPENPAY_MERCHANT_ID=your_merchant_id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
```

### 4. Add Trait to Your Model

```php
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class User extends Authenticatable
{
    use HasSubscription;
}
```

### 5. Subscribe to a Plan

```php
$user = User::find(1);
$plan = Plan::where('name', 'Professional Plan')->first();

$subscription = $user->subscribeToPlan($plan);

// Check status
if ($user->hasActiveSubscription()) {
    echo "Subscription active!";
}
```

---

## 💡 Core Concepts

### Polymorphic Relationships

Unlike traditional subscription packages, this one uses **polymorphic relationships** to work with any model:

```php
// User subscriptions
class User extends Authenticatable {
    use HasSubscription;
}

// Company subscriptions
class Company extends Model {
    use HasSubscription;
}

// Team subscriptions  
class Team extends Model {
    use HasSubscription;
}
```

All work seamlessly:
```php
$user->subscribeToPlan($plan);
$company->subscribeToPlan($plan);
$team->subscribeToPlan($plan);
```

### Payment Gateway Abstraction

Easy to switch between gateways or add custom ones:

```php
// config/subscription.php
'payment_gateway' => env('PAYMENT_GATEWAY', 'openpay'),

'gateways' => [
    'openpay' => OpenpayGateway::class,
    'stripe' => StripeGateway::class,
    'custom' => MyCustomGateway::class,
],
```

### Modular Features

Enable only what you need:

```php
// config/subscription.php
'features' => [
    'tokens' => true,      // Consumption tracking
    'referrals' => true,   // Referral system
    'invoicing' => false,  // Electronic invoicing
],
```

---

## 📊 Database Schema

### Core Tables (Always Included)
- `plans` - Subscription plans
- `subscriptions` - Subscriber subscriptions (polymorphic)
- `payments` - Payment records with 3DS
- `payment_retries` - Retry tracking
- `grace_periods` - Grace period management
- `billing_data` - Tax/billing information (polymorphic)
- `coupons` - Discount coupons **[CORE]**
- `subscriber_coupons` - Applied coupons (polymorphic) **[CORE]**
- `notifications` - Notification log (polymorphic)
- `audit_logs` - Audit trail (polymorphic)

### Optional Tables (Separate Migrations)
- `tokens_usage` - Token consumption (polymorphic) **[OPTIONAL]**
- `referrals` - Referral system (polymorphic) **[OPTIONAL]**
- `invoices` - Electronic invoicing (polymorphic) **[OPTIONAL]**

### No User Table
The package does **NOT** include a users table. It uses polymorphic relationships to work with your existing models.

---

## 🔐 Security Features

### 3D Secure 2.0 Implementation

- Strong Customer Authentication (SCA) compliance
- PSD2 regulation compliance
- Merchant-Initiated Transactions (MIT) after first payment
- Reduced fraud and chargebacks

### PCI Compliance

- Card tokenization (no card storage)
- Payment gateway handles sensitive data
- Secure webhook verification
- Encrypted billing data

---

## 🌍 Supported Payment Gateways

| Gateway | Status | 3DS Support | Countries |
|---------|--------|-------------|-----------|
| **Openpay** | ✅ Full | ✅ Yes | MX, CO |
| **Stripe** | 🔄 Coming Soon | ✅ Yes | Global |
| **Mercadopago** | 🔄 Coming Soon | ✅ Yes | LATAM |

---

## 📧 Notification Types

20+ transactional emails:
- Welcome, payment success/failed, reminders
- Trial expiring/expired
- Grace period start/reminders
- Subscription cancelled/reactivated
- Plan changed (upgrade/downgrade)
- Referral successful
- Invoice available
- Token usage alerts (50%, 75%, 90%, 100%)
- **Payment authentication required (3DS)**

---

## 🧪 Testing

```bash
# Run package tests
composer test

# Run with coverage
composer test:coverage
```

---

## 📦 Requirements

- **PHP:** 8.1+
- **Laravel:** 10.x or 11.x
- **Database:** MySQL 8.0+ / PostgreSQL 13+ / MariaDB 10.5+
- **Optional:** Redis (recommended for queues and cache)

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## 📄 License

This package is open-sourced software licensed under the [MIT license](LICENSE).

---

## 📞 Support

- **Documentation:** [Full Documentation](./docs/)
- **Issues:** [GitHub Issues](https://github.com/CesarAntolinez/laravel-subscription-manager/issues)
- **Discussions:** [GitHub Discussions](https://github.com/CesarAntolinez/laravel-subscription-manager/discussions)

---

## 🙏 Credits

Created and maintained by [Cesar Antolinez](https://github.com/CesarAntolinez)

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for recent changes.

---

**Version:** 2.0  
**Last Updated:** January 2026
