# Extending the Package
## Laravel Subscription Manager

**Version:** 2.0  
**Date:** January 2026

---

## Table of Contents

1. [Custom Payment Gateways](#custom-payment-gateways)
2. [Custom Notifications](#custom-notifications)
3. [Event Listeners](#event-listeners)
4. [Middleware](#middleware)
5. [Custom Business Logic](#custom-business-logic)

---

## Custom Payment Gateways

### Create a Custom Gateway

Implement the `PaymentGatewayInterface`:

```php
<?php

namespace App\Gateways;

use CesarAntolinez\LaravelSubscriptionManager\Contracts\PaymentGatewayInterface;
use CesarAntolinez\LaravelSubscriptionManager\DTOs\PaymentResult;
use CesarAntolinez\LaravelSubscriptionManager\DTOs\RefundResult;
use Illuminate\Http\Request;

class MyCustomGateway implements PaymentGatewayInterface
{
    public function charge(array $data): PaymentResult
    {
        // Implement your charge logic
        // $data contains: amount, currency, card_token, description, etc.
        
        try {
            // Call your payment provider API
            $response = $this->callGatewayAPI($data);
            
            return new PaymentResult([
                'success' => true,
                'transaction_id' => $response['id'],
                'amount' => $data['amount'],
                'currency' => $data['currency'],
                'status' => 'completed',
            ]);
        } catch (\Exception $e) {
            return new PaymentResult([
                'success' => false,
                'error_code' => $e->getCode(),
                'error_message' => $e->getMessage(),
            ]);
        }
    }
    
    public function createCardToken(array $cardData): string
    {
        // Tokenize card data
        // Return token string
    }
    
    public function refund(string $transactionId, float $amount): RefundResult
    {
        // Implement refund logic
    }
    
    public function validateWebhook(Request $request): bool
    {
        // Validate webhook signature
        $signature = $request->header('X-Gateway-Signature');
        $payload = $request->getContent();
        
        return hash_equals(
            $signature,
            hash_hmac('sha256', $payload, config('services.gateway.secret'))
        );
    }
}
```

### Register Your Gateway

In `config/subscription.php`:

```php
'gateways' => [
    'custom' => [
        'class' => \App\Gateways\MyCustomGateway::class,
        'api_key' => env('CUSTOM_GATEWAY_API_KEY'),
        'webhook_secret' => env('CUSTOM_GATEWAY_WEBHOOK_SECRET'),
    ],
],
```

### Use Your Gateway

```env
PAYMENT_GATEWAY=custom
CUSTOM_GATEWAY_API_KEY=your_api_key
```

---

## Custom Notifications

### Create Custom Notification

```php
<?php

namespace App\Notifications;

use CesarAntolinez\LaravelSubscriptionManager\Notifications\SubscriptionNotification;
use Illuminate\Notifications\Messages\MailMessage;

class CustomSubscriptionCreated extends SubscriptionNotification
{
    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Welcome to ' . config('app.name'))
            ->greeting('Hello ' . $notifiable->name . '!')
            ->line('Your subscription has been created successfully.')
            ->line('Plan: ' . $this->subscription->plan->name)
            ->action('View Dashboard', url('/dashboard'))
            ->line('Thank you for subscribing!');
    }
    
    public function toSlack($notifiable)
    {
        // Custom Slack notification
    }
    
    public function toDatabase($notifiable)
    {
        return [
            'subscription_id' => $this->subscription->id,
            'plan_name' => $this->subscription->plan->name,
            'message' => 'New subscription created',
        ];
    }
}
```

### Replace Default Notification

In your service provider:

```php
use CesarAntolinez\LaravelSubscriptionManager\SubscriptionManager;

public function boot()
{
    SubscriptionManager::useNotification(
        'subscription_created',
        \App\Notifications\CustomSubscriptionCreated::class
    );
}
```

---

## Event Listeners

### Available Events

```php
// Subscription events
SubscriptionCreated
SubscriptionRenewed
SubscriptionCancelled
SubscriptionReactivated
SubscriptionBlocked

// Payment events
PaymentSucceeded
PaymentFailed
PaymentRequires3DS
PaymentRefunded

// Plan events
PlanUpgraded
PlanDowngraded

// Grace period events
GracePeriodEntered
GracePeriodEnded

// Token events (if enabled)
TokensConsumed
TokenThresholdReached

// Referral events (if enabled)
ReferralCompleted

// Coupon events
CouponApplied
```

### Create Event Listener

```php
<?php

namespace App\Listeners;

use CesarAntolinez\LaravelSubscriptionManager\Events\SubscriptionCreated;
use Illuminate\Support\Facades\Log;

class HandleSubscriptionCreated
{
    public function handle(SubscriptionCreated $event)
    {
        $subscription = $event->subscription;
        $subscriber = $subscription->subscriber;
        
        // Your custom logic
        Log::info('New subscription created', [
            'subscriber_id' => $subscriber->id,
            'subscriber_type' => get_class($subscriber),
            'plan' => $subscription->plan->name,
        ]);
        
        // Send to analytics
        Analytics::track('subscription_created', [
            'plan' => $subscription->plan->name,
            'value' => $subscription->plan->price_mxn,
        ]);
        
        // Integrate with third-party
        CRM::createSubscription($subscriber, $subscription);
    }
}
```

### Register Listener

In `EventServiceProvider.php`:

```php
protected $listen = [
    \CesarAntolinez\LaravelSubscriptionManager\Events\SubscriptionCreated::class => [
        \App\Listeners\HandleSubscriptionCreated::class,
    ],
];
```

---

## Middleware

### Subscription Access Middleware

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureHasActiveSubscription
{
    public function handle(Request $request, Closure $next, ...$plans)
    {
        $user = $request->user();
        
        if (!$user || !$user->hasActiveSubscription()) {
            return redirect()->route('subscription.plans')
                ->with('error', 'You need an active subscription to access this feature.');
        }
        
        // Check specific plans if provided
        if (!empty($plans)) {
            $subscription = $user->activeSubscription();
            if (!in_array($subscription->plan->name, $plans)) {
                return redirect()->route('subscription.upgrade')
                    ->with('error', 'This feature requires a higher plan.');
            }
        }
        
        return $next($request);
    }
}
```

### Usage

```php
// routes/web.php
Route::middleware(['auth', EnsureHasActiveSubscription::class])->group(function () {
    Route::get('/premium-feature', [PremiumController::class, 'index']);
});

// Specific plans
Route::middleware(['auth', EnsureHasActiveSubscription::class.':Professional Plan,Enterprise Plan'])
    ->group(function () {
        Route::get('/advanced-feature', [AdvancedController::class, 'index']);
    });
```

### Token Limit Middleware

```php
<?php

namespace App\Http\Middleware;

use Closure;

class EnsureHasTokens
{
    public function handle($request, Closure $next, $required = 1)
    {
        $user = $request->user();
        
        if (!$user || $user->remainingTokens() < $required) {
            return response()->json([
                'error' => 'Insufficient tokens',
                'required' => $required,
                'remaining' => $user->remainingTokens(),
            ], 429);
        }
        
        return $next($request);
    }
}
```

---

## Custom Business Logic

### Extend Subscription Model

```php
<?php

namespace App\Models;

use CesarAntolinez\LaravelSubscriptionManager\Models\Subscription as BaseSubscription;

class Subscription extends BaseSubscription
{
    public function isEnterprise(): bool
    {
        return $this->plan->name === 'Enterprise Plan';
    }
    
    public function canAccessFeature(string $feature): bool
    {
        $features = config("features.{$this->plan->name}");
        return in_array($feature, $features);
    }
}
```

### Use Custom Model

In `config/subscription.php`:

```php
'models' => [
    'subscription' => \App\Models\Subscription::class,
],
```

### Custom Plan Logic

```php
<?php

namespace App\Models;

use CesarAntolinez\LaravelSubscriptionManager\Models\Plan as BasePlan;

class Plan extends BasePlan
{
    public function getMonthlyPriceAttribute()
    {
        if ($this->periodicity === 'annual') {
            return $this->price_mxn / 12;
        }
        return $this->price_mxn;
    }
    
    public function getSavingsAttribute()
    {
        if ($this->periodicity === 'annual') {
            $monthlyTotal = $this->getMonthlyPriceAttribute() * 12;
            return $monthlyTotal - $this->price_mxn;
        }
        return 0;
    }
}
```

---

## Webhook Customization

### Custom Webhook Handler

```php
<?php

namespace App\Webhooks;

use CesarAntolinez\LaravelSubscriptionManager\Webhooks\WebhookHandler;

class CustomChargeSucceededHandler extends WebhookHandler
{
    public function handle(array $payload)
    {
        $chargeId = $payload['id'];
        
        // Your custom logic
        $this->sendToAnalytics($payload);
        $this->updateCRM($payload);
        
        // Call parent if you want default behavior too
        parent::handle($payload);
    }
    
    protected function sendToAnalytics($payload)
    {
        // Send event to analytics platform
    }
}
```

### Register Custom Handler

In `config/subscription.php`:

```php
'webhooks' => [
    'handlers' => [
        'charge.succeeded' => \App\Webhooks\CustomChargeSucceededHandler::class,
    ],
],
```

---

## Customize Views

### Publish Views

```bash
php artisan vendor:publish --tag=subscription-views
```

Views will be in `resources/views/vendor/subscription/`.

### Customize Email Templates

```blade
{{-- resources/views/vendor/subscription/emails/subscription-created.blade.php --}}
@component('mail::message')
# Welcome {{ $subscriber->name }}!

Your {{ $subscription->plan->name }} subscription is now active.

**Trial Period:** {{ $subscription->trial_days }} days

@component('mail::button', ['url' => $dashboardUrl])
Go to Dashboard
@endcomponent

Thanks,<br>
{{ config('app.name') }}
@endcomponent
```

---

## Custom Validation Rules

```php
<?php

namespace App\Rules;

use Illuminate\Contracts\Validation\Rule;
use CesarAntolinez\LaravelSubscriptionManager\Models\Subscription;

class CanUpgradeToPlan implements Rule
{
    public function passes($attribute, $value)
    {
        $user = auth()->user();
        $newPlan = Plan::find($value);
        $currentSubscription = $user->activeSubscription();
        
        if (!$currentSubscription) {
            return true;
        }
        
        // Custom upgrade logic
        return $newPlan->price_mxn > $currentSubscription->plan->price_mxn;
    }
    
    public function message()
    {
        return 'You can only upgrade to a higher-priced plan.';
    }
}
```

---

## Package Extension Points

### Service Provider Hooks

```php
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use CesarAntolinez\LaravelSubscriptionManager\SubscriptionManager;

class AppServiceProvider extends ServiceProvider
{
    public function boot()
    {
        // Customize subscription creation
        SubscriptionManager::creatingSubscription(function ($subscription) {
            // Custom logic before subscription is saved
        });
        
        // Customize payment processing
        SubscriptionManager::processingPayment(function ($payment) {
            // Custom logic before payment is processed
        });
        
        // Add custom validation
        SubscriptionManager::validatingCoupon(function ($coupon, $subscriber) {
            // Return false to reject coupon
            return $this->customCouponValidation($coupon, $subscriber);
        });
    }
}
```

---

## Next Steps

- **Installation:** [INSTALLATION.md](./INSTALLATION.md)
- **Configuration:** [CONFIGURATION.md](./CONFIGURATION.md)
- **Usage:** [POLYMORPHIC_RELATIONSHIPS.md](./POLYMORPHIC_RELATIONSHIPS.md)

---

**Version:** 2.0  
**Last Updated:** January 2026

---

**End of Document**
