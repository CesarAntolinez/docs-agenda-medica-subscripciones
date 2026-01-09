# Características del Paquete
## Gestor de Suscripciones Laravel

**Versión:** 2.0  
**Fecha:** Enero 2026

---

## 📑 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Características Core](#características-core)
3. [Módulos Opcionales](#módulos-opcionales)
4. [Soporte de Pasarelas de Pago](#soporte-de-pasarelas-de-pago)
5. [Características de Seguridad](#características-de-seguridad)
6. [Sistema de Notificaciones](#sistema-de-notificaciones)
7. [Características de Flexibilidad](#características-de-flexibilidad)

---

## Visión General

Laravel Subscription Manager es un paquete completo de gestión de suscripciones diseñado para flexibilidad, seguridad y escalabilidad. Usa **relaciones polimórficas** para trabajar con cualquier modelo en tu aplicación Laravel, haciéndolo verdaderamente reutilizable en diferentes tipos de proyectos.

**Diferenciadores Clave:**
- ✅ Relaciones polimórficas - suscribir Usuarios, Empresas, Equipos o cualquier modelo
- ✅ Soporte multi-pasarela con capa de abstracción
- ✅ Implementación 3D Secure 2.0 integrada
- ✅ Arquitectura modular - habilita solo lo que necesitas
- ✅ Listo para producción con registro de auditoría completo

---

## Características Core

### 1. Subscription Plans Management

**Descripción:** Flexible plan configuration with multiple periodicities and pricing.

**Features:**
- Multiple plans with customizable names and descriptions
- Three periodicity options:
  - Monthly billing
  - Annual billing (single payment)
  - Annual plan with monthly billing
- Multi-currency support (MXN, COP, easily extensible)
- Trial periods (configurable per plan)
- Plan activation/deactivation (historical plans preserved)
- Token allocation per plan (if tokens module enabled)

**Use Cases:**
- SaaS applications with tiered pricing
- Subscription-based services
- Membership platforms
- Multi-tenant applications

---

### 2. Polymorphic Subscriptions

**Descripción:** Subscribe any model in your application using the `HasSubscription` trait.

**Features:**
- Works with Users, Companies, Teams, Organizations, or custom models
- One active subscription per subscriber
- Complete subscription history
- Status tracking: trial, active, past_due, grace_period, cancelled, blocked
- Soft delete support for data recovery
- Scheduled plan changes (immediate upgrades, scheduled downgrades)
- Pro-rated billing on upgrades

**Example Models:**
```php
// Individual user subscriptions
class User extends Authenticatable {
    use HasSubscription;
}

// Company/Organization subscriptions
class Company extends Model {
    use HasSubscription;
}

// Team-based subscriptions
class Team extends Model {
    use HasSubscription;
}
```

---

### 3. Payment Processing

**Descripción:** Complete payment lifecycle management with retry logic and 3D Secure support.

**Features:**
- Multiple payment methods:
  - Credit/debit card (tokenized, PCI-compliant)
  - Manual payment (bank transfer with admin confirmation)
- Payment statuses: pending, processing, requires_3ds, authenticating, authenticated, completed, failed, refunded, cancelled
- Automatic retry mechanism (configurable attempts and intervals)
- Payment history and audit trail
- Refund support
- Multi-currency support

**Payment Flow:**
1. Initial payment with 3D Secure authentication (if required)
2. Card tokenization for recurring payments
3. Merchant-Initiated Transactions (MIT) for renewals
4. Automatic retries on failure (up to 3 attempts)
5. Grace period entry after exhausted retries

---

### 4. Discount Coupons System ✅ **[CORE]**

**Descripción:** Full-featured coupon system for promotions and discounts.

**Features:**
- Coupon types:
  - Percentage discount
  - Fixed amount discount
- Duration options:
  - Single payment
  - Multiple months
  - Permanent discount
- Usage limits:
  - Unlimited use
  - Limited total uses
  - One use per subscriber
- Plan applicability:
  - All plans
  - Specific plans only
- Expiration dates
- Active/inactive status
- Automatic validation and application
- Reuse prevention

**Use Cases:**
- Promotional campaigns
- Referral bonuses
- Loyalty rewards
- Trial conversion incentives

---

### 5. Grace Period Management

**Descripción:** Subscriber-friendly grace period system for failed payments.

**Features:**
- Configurable grace period duration (default: 2 months)
- Full access maintained during grace period
- Debt tracking (months owed, amount owed)
- Automatic reminder notifications (configurable frequency)
- Notification counter
- Subscription blocking after grace period expiration
- Reactivation support with payment

**Benefits:**
- Reduces churn from temporary payment issues
- Maintains customer relationships
- Provides time for payment resolution
- Transparent debt management

---

### 6. Billing Data Management

**Descripción:** Tax and billing information for electronic invoicing (polymorphic).

**Features:**
- Country-specific fields:
  - **Mexico**: RFC, legal name, tax regime, postal code, CFDI use
  - **Colombia**: NIT, legal name, person type, address, city, state
- Validation according to country regulations
- 1:1 relationship with subscribable model
- Support for both individuals and businesses
- Encrypted storage ready

**Compliance:**
- Mexico: SAT requirements
- Colombia: DIAN requirements
- Extensible for other countries

---

### 7. Comprehensive Notifications

**Descripción:** 20+ transactional notification types with queue support.

**Features:**
- Email notifications for all subscription events
- Notification types:
  1. Welcome email
  2. Payment success
  3. Payment reminder
  4. Payment failed
  5. Manual payment order
  6. Grace period start
  7. Grace period reminders
  8. Subscription cancelled
  9. Plan changed
  10. Referral successful
  11. Referral discount code
  12. Invoice available
  13. Token usage alerts (50%, 75%, 90%, 100%)
  14. Trial expiring
  15. Trial expired
  16. Subscription reactivated
  17. **Payment authentication required (3DS)**
- Notification status tracking: pending, sent, failed, bounced
- Metadata support for dynamic content
- Resend capability
- Queue integration for async sending

---

### 8. Audit Logging

**Descripción:** Complete audit trail of all critical actions.

**Features:**
- Action tracking: create, update, delete
- Before/after state comparison (JSON)
- IP address logging
- User/system attribution (polymorphic)
- Immutable logs (INSERT only)
- Entity and entity ID tracking
- Timestamp tracking

**Compliance:**
- SOC 2 ready
- GDPR compatible
- Audit trail for financial transactions

---

## Módulos Opcionales

### 9. Token Consumption Tracking **[OPTIONAL]**

**Descripción:** Track token/credit consumption for usage-based billing.

**Enable via config:**
```php
'features' => [
    'tokens' => env('SUBSCRIPTION_TOKENS_ENABLED', true),
],
```

**Features:**
- Token allocation per plan
- Period-based tracking (monthly)
- Real-time consumption monitoring
- Usage alerts at configurable thresholds
- Automatic reset on renewal
- Historical consumption data
- No carry-over (tokens expire each period)

**Use Cases:**
- API call limits
- AI/ML token consumption
- Credit-based services
- Resource usage tracking

---

### 10. Referral System **[OPTIONAL]**

**Descripción:** Complete referral program with configurable benefits.

**Enable via config:**
```php
'features' => [
    'referrals' => env('SUBSCRIPTION_REFERRALS_ENABLED', true),
],
```

**Features:**
- Unique referral codes per subscriber
- Polymorphic referrer/referred relationships
- Configurable benefits:
  - Referrer: discounts, tokens, credit
  - Referred: discounts
- Status tracking: pending, completed, expired
- Automatic benefit application on first payment
- Multiple referrals per subscriber

**Use Cases:**
- Viral growth campaigns
- Customer acquisition
- Loyalty programs
- Network effects

---

### 11. Electronic Invoicing **[OPTIONAL]**

**Descripción:** Electronic invoice management with external PAC/DIAN integration.

**Enable via config:**
```php
'features' => [
    'invoicing' => env('SUBSCRIPTION_INVOICING_ENABLED', true),
],
```

**Features:**
- Invoice request workflow
- Status tracking: requested, processing, completed, failed
- PDF storage and delivery
- Email distribution
- Re-download capability
- 1:1 relationship with payments
- Country-specific requirements:
  - **Mexico**: CFDI via authorized PAC
  - **Colombia**: Electronic invoice via DIAN

**Compliance:**
- Tax authority requirements
- Electronic signature support
- Audit trail

---

## Soporte de Pasarelas de Pago

### Multi-Gateway Architecture

**Descripción:** Abstracted payment gateway interface for easy integration.

**Included Gateways:**
- ✅ **Openpay** (Mexico/Colombia) - Full implementation with 3DS
- 🔄 **Stripe** (Coming soon)
- 🔄 **Mercadopago** (Coming soon)

**Gateway Interface:**
```php
interface PaymentGatewayInterface {
    public function charge(array $data): PaymentResult;
    public function createCardToken(array $cardData): string;
    public function refund(string $transactionId, float $amount): RefundResult;
    public function validateWebhook(Request $request): bool;
}
```

**Configuración:**
```php
'payment_gateway' => env('PAYMENT_GATEWAY', 'openpay'),
'gateways' => [
    'openpay' => \Package\Gateways\OpenpayGateway::class,
    'stripe' => \Package\Gateways\StripeGateway::class,
    'custom' => \App\Gateways\CustomGateway::class,
],
```

**Benefits:**
- Swap gateways without code changes
- Test mode support
- Webhook standardization
- Multi-region support

---

## Características de Seguridad

### 1. 3D Secure 2.0 Implementation

**Descripción:** Complete 3DS flow for secure payments and fraud reduction.

**Features:**
- Strong Customer Authentication (SCA) compliance
- PSD2 regulation compliance
- Reduced fraud and chargebacks
- Merchant-Initiated Transactions (MIT) exemption after first payment
- Bank authentication flow:
  - Initial payment requires 3DS authentication
  - Redirect to bank for user verification
  - MIT flag set after successful authentication
  - Future renewals use MIT (no 3DS required)

**Technical Implementation:**
- `requires_3ds` flag on payments
- `three_ds_status` tracking: not_required, pending, authenticated, failed, timeout
- `three_ds_redirect_url` for bank modal
- `three_ds_version` tracking (1.0, 2.0)
- `mit_enabled` flag on subscriptions
- `first_payment_3ds_completed` tracking

---

### 2. PCI Compliance

**Features:**
- Card tokenization (cards never stored)
- Payment gateway handles sensitive data
- Secure webhook verification
- Encrypted billing data
- Audit logging

---

### 3. Data Protection

**Features:**
- Soft delete for subscriptions
- Immutable audit logs
- Polymorphic relationships (no hard-coded user dependencies)
- Encrypted sensitive fields ready
- GDPR-compatible data handling

---

## Características de Flexibilidad

### 1. Polymorphic Relationships

**Benefits:**
- Subscribe any model (User, Company, Team, etc.)
- No dependency on specific user table structure
- Multi-tenant ready
- B2B and B2C compatible
- Future-proof architecture

---

### 2. Modular Architecture

**Benefits:**
- Enable only features you need
- Smaller database footprint
- Faster migrations
- Reduced complexity
- Easy feature toggling

---

### 3. Multi-Currency Support

**Features:**
- Multiple currency pricing per plan
- No automatic conversion (explicit pricing)
- Extensible for additional currencies
- Currency-specific formatting

---

### 4. Configurable Business Rules

**Customizable:**
- Trial period duration (per plan)
- Grace period duration
- Payment retry attempts and intervals
- Notification schedules
- Token allocation
- Referral benefits
- Coupon durations

---

## Integration Points

### 1. Queue System

**Support:**
- Laravel Queue for async jobs
- Notification sending
- Payment processing
- Webhook handling
- Token reset jobs
- Grace period checks

---

### 2. Event System

**Events Dispatched:**
- `SubscriptionCreated`
- `SubscriptionRenewed`
- `SubscriptionCancelled`
- `PaymentSucceeded`
- `PaymentFailed`
- `PlanChanged`
- `GracePeriodEntered`
- `TokenThresholdReached`
- `ReferralCompleted`

**Listeners:**
- Custom business logic
- Third-party integrations
- Analytics tracking
- Slack/Discord notifications

---

## Scalability Features

### 1. Database Optimization

**Features:**
- Strategic indexes for frequent queries
- Composite indexes for complex queries
- Partitioning ready
- Efficient polymorphic indexes

---

### 2. Caching Ready

**Cacheable:**
- Active plans
- Subscription status
- Current token usage
- Coupon validation

---

### 3. Performance

**Optimizations:**
- Eager loading support
- Chunk processing for large datasets
- Background job processing
- Webhook async handling

---

## Comparison: Core vs Opcional

| Feature | Category | Requerido? | Database Tables |
|---------|----------|-----------|-----------------|
| Subscription Management | Core | ✅ Yes | subscriptions, plans |
| Payment Processing | Core | ✅ Yes | payments, payment_retries |
| Grace Periods | Core | ✅ Yes | grace_periods |
| Coupons & Discounts | Core | ✅ Yes | coupons, subscriber_coupons |
| Billing Data | Core | ✅ Yes | billing_data |
| Notifications | Core | ✅ Yes | notifications |
| Audit Logs | Core | ✅ Yes | audit_logs |
| Token Tracking | Opcional | ❌ No | tokens_usage |
| Referral System | Opcional | ❌ No | referrals |
| Electronic Invoicing | Opcional | ❌ No | invoices |

---

## Technology Stack

**Backend:**
- Laravel 10.x / 11.x
- PHP 8.1+
- MySQL 8.0+ / PostgreSQL 13+

**Opcional:**
- Redis (recommended for queues and cache)
- Supervisor (for queue workers)

**External Services:**
- Payment Gateway (Openpay, Stripe, etc.)
- Email Service (SMTP, Mailgun, SendGrid, etc.)
- Invoice Provider (PAC for Mexico, DIAN for Colombia) - if invoicing module enabled

---

## Next Steps

**Para Instalación:** See [INSTALLATION.md](./INSTALLATION.md)  
**Para Configuración:** See [CONFIGURATION.md](./CONFIGURATION.md)  
**Para Extender:** See [EXTENDING.md](./EXTENDING.md)  
**Para Detalles de Base de Datos:** See [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)

---

**Versión:** 2.0  
**Última Actualización:** Enero 2026

---

**End of Document**
