# Guía de Relaciones Polimórficas
## Paquete Gestor de Suscripciones Laravel

**Versión:** 2.0  
**Fecha:** Enero 2026

---

## Visión General

Este paquete usa **relaciones polimórficas** para proporcionar máxima flexibilidad. En lugar de estar vinculado a una tabla `users` específica, puede trabajar con **cualquier modelo** en tu aplicación.

**Beneficios:**
- Suscribir Usuarios, Empresas, Equipos, Organizaciones o cualquier modelo personalizado
- Sin dependencias codificadas de forma rígida en la estructura de tabla de usuarios
- Listo para multi-tenencia
- Compatible con B2B y B2C

---

## Inicio Rápido

### 1. Agregar Trait a Tu Modelo

```php
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class User extends Authenticatable
{
    use HasSubscription;
}
```

### 2. Suscribirse a un Plan

```php
$user = User::find(1);
$plan = Plan::find(1);

$subscription = $user->subscribeToPlan($plan);
```

¡Eso es todo! El paquete se encarga del resto.

---

## Cómo Funciona

### Estructura de Base de Datos

En lugar de:
```sql
-- Enfoque tradicional (NO usado)
subscriptions (
    user_id → users.id
)
```

el paquete usa:
```sql
-- Enfoque polimórfico (USADO)
subscriptions (
    subscriber_type → 'App\Models\User'
    subscriber_id → 1
)
```

Esto permite que la misma tabla `subscriptions` haga referencia a diferentes modelos.

---

## Ejemplos de Uso

### Ejemplo 1: User Subscriptions

```php
use App\Models\User;
use CesarAntolinez\LaravelSubscriptionManager\Models\Plan;

// Obtener usuario y plan
$user = User::find(1);
$plan = Plan::where('name', 'Professional Plan')->first();

// Subscribe
$subscription = $user->subscribeToPlan($plan, 'monthly', $cardToken);

// Check status
if ($user->hasActiveSubscription()) {
    echo "Active subscription!";
}

// Get subscription details
$subscription = $user->activeSubscription();
echo $subscription->plan->name;
echo $subscription->status;
```

### Ejemplo 2: Company Subscriptions

```php
use App\Models\Company;

class Company extends Model
{
    use HasSubscription;
    
    // Company-specific methods
    public function users()
    {
        return $this->hasMany(User::class);
    }
}

// Subscribe a company
$company = Company::find(1);
$plan = Plan::find(2);

$subscription = $company->subscribeToPlan($plan);

// All company users benefit from the subscription
if ($company->hasActiveSubscription()) {
    foreach ($company->users as $user) {
        // Grant access based on company subscription
    }
}
```

### Ejemplo 3: Team Subscriptions

```php
use App\Models\Team;

class Team extends Model
{
    use HasSubscription;
    
    public function members()
    {
        return $this->belongsToMany(User::class);
    }
}

// Subscribe a team
$team = Team::find(1);
$plan = Plan::where('name', 'Team Plan')->first();

$subscription = $team->subscribeToPlan($plan);

// Check team subscription
if ($team->hasActiveSubscription()) {
    echo "Team has access!";
}
```

---

## Available Methods

The `HasSubscription` trait provides:

### Subscription Management

```php
// Subscribe to a plan
$subscription = $model->subscribeToPlan($plan, $periodicity = 'monthly', $cardToken = null);

// Get active subscription
$subscription = $model->activeSubscription();

// Get all subscriptions (including history)
$subscriptions = $model->subscriptions;

// Cancel subscription
$model->cancelSubscription($reason = null);

// Reactivate subscription
$model->reactivateSubscription($cardToken);
```

### Status Checks

```php
// Check if has active subscription
$model->hasActiveSubscription(); // boolean

// Check if on trial
$model->isOnTrial(); // boolean

// Check if on grace period
$model->isOnGracePeriod(); // boolean

// Check if subscription is blocked
$model->isSubscriptionBlocked(); // boolean

// Verificar estado de suscripción
$status = $model->subscriptionStatus(); // 'trial', 'active', 'past_due', etc.
```

### Plan Changes

```php
// Upgrade plan (immediate)
$model->upgradePlan($newPlan);

// Downgrade plan (scheduled for next renewal)
$model->downgradePlan($newPlan);

// Get pending plan change
$pendingPlan = $model->pendingPlanChange();
```

### Billing Data

```php
// Get billing data
$billingData = $model->billingData;

// Set billing data
$model->setBillingData([
    'country' => 'MX',
    'tax_id' => 'RFC123456',
    'legal_name' => 'Company Name',
    // ... more fields
]);
```

### Coupons (CORE Feature)

```php
// Apply coupon
$model->applyCoupon($coupon);

// Check if coupon was used
$model->hasUsedCoupon($coupon); // boolean

// Get applied coupons
$coupons = $model->appliedCoupons;
```

### Tokens (OPTIONAL - if enabled)

```php
// Get current token usage
$tokenUsage = $model->currentTokenUsage();

// Consume tokens
$model->consumeTokens(100);

// Check remaining tokens
$remaining = $model->remainingTokens();

// Get token usage history
$history = $model->tokenUsageHistory;
```

### Referrals (OPTIONAL - if enabled)

```php
// Get referral code
$code = $model->referralCode();

// Refer someone
$model->refer($otherModel);

// Get referrals
$referrals = $model->referrals;

// Check if referred by someone
$model->wasReferred(); // boolean
```

### Notifications

```php
// Get subscription notifications
$notifications = $model->subscriptionNotifications;

// Get unread notifications
$unread = $model->unreadSubscriptionNotifications();
```

---

## Multiple Subscribable Models

You can have multiple different models that can subscribe:

```php
// config/subscription.php
'subscriber_model' => 'App\\Models\\User', // Primary subscriber

// But you can use the trait on multiple models:

// Suscripciones de usuario
class User extends Authenticatable {
    use HasSubscription;
}

// Suscripciones de empresa
class Company extends Model {
    use HasSubscription;
}

// Suscripciones de equipo
class Team extends Model {
    use HasSubscription;
}
```

All will work simultaneously:

```php
// User subscription
$user->subscribeToPlan($plan);

// Company subscription
$company->subscribeToPlan($plan);

// Team subscription
$team->subscribeToPlan($plan);
```

---

## Querying Subscriptions

### Get All Subscriptions for a Subscriber

```php
$subscriptions = $model->subscriptions;

// Only active
$active = $model->subscriptions()->where('status', 'active')->get();

// With plan details
$withPlan = $model->subscriptions()->with('plan')->get();
```

### Find Subscribers by Subscription Status

```php
use CesarAntolinez\LaravelSubscriptionManager\Models\Subscription;

// All users with active subscriptions
$activeUsers = User::whereHas('subscriptions', function ($query) {
    $query->where('status', 'active');
})->get();

// All companies on trial
$trialCompanies = Company::whereHas('subscriptions', function ($query) {
    $query->where('status', 'trial');
})->get();
```

### Get Subscribers by Plan

```php
// All users on "Professional Plan"
$professionalUsers = User::whereHas('subscriptions', function ($query) use ($plan) {
    $query->where('plan_id', $plan->id)
          ->where('status', 'active');
})->get();
```

---

## Polymorphic Relationships Explained

### subscriptions

```php
// Relationship
$model->subscriptions() // morphMany

// Database
subscriber_type: 'App\Models\User'
subscriber_id: 1
```

### billing_data

```php
// Relationship
$model->billingData() // morphOne

// Database
billable_type: 'App\Models\User'
billable_id: 1
```

### subscriber_coupons

```php
// Relationship
$model->appliedCoupons() // morphMany through subscriber_coupons

// Database
subscriber_type: 'App\Models\User'
subscriber_id: 1
```

### tokens_usage (OPTIONAL)

```php
// Relationship
$model->tokenUsageHistory() // morphMany

// Database
subscriber_type: 'App\Models\User'
subscriber_id: 1
```

### referrals (OPTIONAL)

```php
// Relationships
$model->referrals() // morphMany as referrer
$model->referredBy() // morphOne as referred

// Database (as referrer)
referrer_type: 'App\Models\User'
referrer_id: 1

// Database (as referred)
referred_type: 'App\Models\User'
referred_id: 2
```

### notifications

```php
// Relationship
$model->subscriptionNotifications() // morphMany

// Database
notifiable_type: 'App\Models\User'
notifiable_id: 1
```

---

## Advanced Examples

### Multi-Tenant SaaS

```php
class Organization extends Model
{
    use HasSubscription;
    
    public function teams()
    {
        return $this->hasMany(Team::class);
    }
    
    public function users()
    {
        return $this->hasManyThrough(User::class, Team::class);
    }
}

// Organization subscribes, all users get access
$organization = Organization::find(1);
$organization->subscribeToPlan($enterprisePlan);

// Check in middleware
if ($user->organization->hasActiveSubscription()) {
    // Allow access
}
```

### B2B Marketplace

```php
class Vendor extends Model
{
    use HasSubscription;
    
    public function products()
    {
        return $this->hasMany(Product::class);
    }
}

// Vendors subscribe to list products
$vendor = Vendor::find(1);
$vendor->subscribeToPlan($vendorPlan);

// Check subscription before allowing product listing
if ($vendor->hasActiveSubscription()) {
    $vendor->products()->create([...]);
}
```

---

## Mejores Prácticas

1. **Use Type Hints:**
```php
use CesarAntolinez\LaravelSubscriptionManager\Models\Subscription;

public function myMethod(): ?Subscription
{
    return $this->activeSubscription();
}
```

2. **Eager Load Relationships:**
```php
$users = User::with(['subscriptions.plan', 'billingData'])->get();
```

3. **Cache Subscription Status:**
```php
$isActive = Cache::remember(
    "user.{$user->id}.subscription.active",
    300,
    fn() => $user->hasActiveSubscription()
);
```

4. **Use Events:**
```php
// Listen for subscription events
Event::listen(SubscriptionCreated::class, function ($event) {
    // $event->subscription->subscriber returns your model
});
```

---

## Resolución de Problemas

**Issue: Trait methods not found**
```php
Solution: Ensure you've added the HasSubscription trait to your model
```

**Issue: Polymorphic relationship returns null**
```php
Solution: Check that subscriber_type contains the full class name with namespace
Example: 'App\\Models\\User' not 'User'
```

**Issue: Can't query subscriptions**
```php
Solution: Use whereHas or with relationships properly
Example: User::whereHas('subscriptions', fn($q) => $q->where('status', 'active'))
```

---

## Next Steps

- **Installation:** [INSTALLATION.md](./INSTALLATION.md)
- **Configuration:** [CONFIGURATION.md](./CONFIGURATION.md)
- **Extending:** [EXTENDING.md](./EXTENDING.md)

---

**Versión:** 2.0  
**Last Updated:** January 2026

---

**End of Document**
