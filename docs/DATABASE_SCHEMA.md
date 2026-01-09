# Database Schema
## Laravel Subscription Manager Package

**Version:** 2.0  
**Date:** January 2026  
**Update:** Polymorphic Relationships (subscriber_type/subscriber_id)

---

## 📑 Table of Contents

1. [ERD Diagram](#erd-diagram)
2. [Table Categories](#table-categories)
3. [Table Descriptions](#table-descriptions)
4. [Relationships](#relationships)
5. [Recommended Indexes](#recommended-indexes)
6. [Deletion Policies](#deletion-policies)

---

## ERD Diagram

```mermaid
erDiagram
    Subscriber ||--o{ subscriptions : "has (polymorphic)"
    Subscriber ||--o{ billing_data : "has (polymorphic)"
    Subscriber ||--o{ subscriber_coupons : "applies (polymorphic)"
    Subscriber ||--o{ notifications : "receives (polymorphic)"
    Subscriber ||--o{ referrals_as_referrer : "refers (polymorphic)"
    Subscriber ||--o{ referrals_as_referred : "referred_by (polymorphic)"
    Subscriber ||--o{ invoices : "requests (polymorphic)"
    Subscriber ||--o{ tokens_usage : "tracks (polymorphic)"
    
    plans ||--o{ subscriptions : "offered_in"
    
    subscriptions ||--o{ payments : "generates"
    subscriptions ||--o{ grace_periods : "enters"
    
    payments ||--o{ payment_retries : "has_retries"
    payments ||--o{ invoices : "requires_invoice"
    
    coupons ||--o{ subscriber_coupons : "used_by"
    
    Subscriber {
        string type "App-Models-User, App-Models-Company, etc"
        bigint id "Any subscribable model ID"
        note "NOT stored in package - provided by host app"
    }
    
    plans {
        bigint id PK
        string name
        text description
        int tokens_monthly
        enum periodicity "monthly, annual, annual_monthly_billing"
        decimal price_mxn "10,2"
        decimal price_cop "10,2"
        int trial_days
        boolean active
        timestamps created_at_updated_at
    }
    
    subscriptions {
        bigint id PK
        string subscriber_type "Polymorphic type"
        bigint subscriber_id "Polymorphic ID"
        bigint plan_id FK
        enum status "trial, active, past_due, grace_period, cancelled, blocked"
        enum periodicity "monthly, annual, annual_monthly_billing"
        date starts_at
        date ends_at
        date next_billing_date
        string card_token
        string manual_payment_reference
        boolean mit_enabled "MIT enabled for recurring"
        boolean first_payment_3ds_completed "First payment with 3DS OK"
        bigint pending_plan_id FK "For scheduled downgrades"
        date pending_plan_change_date
        timestamps created_at_updated_at
        timestamp deleted_at
    }
    
    tokens_usage {
        bigint id PK
        string subscriber_type "Polymorphic type - OPTIONAL"
        bigint subscriber_id "Polymorphic ID - OPTIONAL"
        bigint subscription_id FK
        date period_start
        date period_end
        int used
        int total
        timestamps created_at_updated_at
    }
    
    payments {
        bigint id PK
        bigint subscription_id FK
        decimal amount "10,2"
        string currency "MXN, COP"
        enum method "card, bank_transfer"
        enum status "pending, processing, requires_3ds, authenticating, authenticated, completed, failed, refunded, cancelled"
        string openpay_transaction_id
        int attempt "1, 2, 3"
        timestamp paid_at
        string error_code
        text error_message
        boolean requires_3ds "Payment requires 3DS auth"
        enum three_ds_status "not_required, pending, authenticated, failed, timeout"
        string three_ds_redirect_url "500 chars"
        string three_ds_version "1.0, 2.0"
        timestamp authentication_required_notified_at
        timestamps created_at_updated_at
    }
    
    coupons {
        bigint id PK
        string code UK
        enum type "percentage, fixed"
        decimal value "10,2"
        int duration_months "NULL=permanent"
        json applicable_plans "NULL=all plans"
        int usage_limit "NULL=unlimited"
        int current_usage
        date expires_at
        boolean active
        timestamps created_at_updated_at
    }
    
    subscriber_coupons {
        bigint id PK
        string subscriber_type "Polymorphic type"
        bigint subscriber_id "Polymorphic ID"
        bigint coupon_id FK
        timestamp applied_at
        timestamps created_at_updated_at
    }
    
    referrals {
        bigint id PK
        string referrer_type "Polymorphic type - OPTIONAL"
        bigint referrer_id "Polymorphic ID - OPTIONAL"
        string referred_type "Polymorphic type - OPTIONAL"
        bigint referred_id "Polymorphic ID - OPTIONAL"
        string code UK
        json referrer_benefit "discount, tokens, credit"
        json referred_benefit "discount"
        enum status "pending, completed, expired"
        timestamp completed_at
        timestamps created_at_updated_at
    }
    
    billing_data {
        bigint id PK
        string billable_type "Polymorphic type"
        bigint billable_id "Polymorphic ID"
        enum country "MX, CO"
        string tax_id "RFC or NIT"
        string legal_name
        string tax_regime "MX only"
        string postal_code "MX only"
        string cfdi_use "MX only"
        enum person_type "natural, legal - CO only"
        text address "CO only"
        string city "CO only"
        string state "CO only"
        timestamps created_at_updated_at
    }
    
    invoices {
        bigint id PK
        string invoiceable_type "Polymorphic type - OPTIONAL"
        bigint invoiceable_id "Polymorphic ID - OPTIONAL"
        bigint payment_id FK
        string file_url
        timestamp requested_at
        timestamp sent_at
        enum status "requested, processing, completed, failed"
        timestamps created_at_updated_at
    }
    
    payment_retries {
        bigint id PK
        bigint payment_id FK
        int attempt
        timestamp tried_at
        text result
        timestamps created_at_updated_at
    }
    
    grace_periods {
        bigint id PK
        bigint subscription_id FK
        date started_at
        date ends_at
        int months_owed
        decimal amount_owed "10,2"
        int notifications_sent
        timestamps created_at_updated_at
    }
    
    notifications {
        bigint id PK
        string notifiable_type "Polymorphic type"
        bigint notifiable_id "Polymorphic ID"
        string type "20+ types"
        timestamp sent_at
        enum status "pending, sent, failed, bounced"
        json metadata
        timestamps created_at_updated_at
    }
    
    audit_logs {
        bigint id PK
        string auditable_type "Polymorphic type, NULL for system"
        bigint auditable_id "Polymorphic ID, NULL for system"
        string action
        string entity
        bigint entity_id
        json before
        json after
        string ip
        timestamps created_at_updated_at
    }
```

---

## Table Categories

### Core Tables (Always Included)
- `plans` - Subscription plans catalog
- `subscriptions` - Subscriber subscriptions (polymorphic)
- `payments` - Payment records with 3DS support
- `payment_retries` - Payment retry tracking
- `grace_periods` - Grace period management
- `billing_data` - Tax/billing data (polymorphic)
- `coupons` ✅ - Discount coupons catalog
- `subscriber_coupons` ✅ - Applied coupons (polymorphic)
- `notifications` - Notification log (polymorphic)
- `audit_logs` - Audit trail (polymorphic)

### Optional Tables (Separate Migrations)
- `tokens_usage` - Only if `tokens` feature is enabled
- `referrals` - Only if `referrals` feature is enabled
- `invoices` - Only if `invoicing` feature is enabled

### Not Included (Host Application Responsibility)
- `users` or any subscriber model - The package uses **polymorphic relationships** to work with any subscribable model provided by the host application

---

## Table Descriptions

### 1. plans

**Description:** Catalog of available subscription plans.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| `name` | VARCHAR(255) | NO | Plan name |
| `description` | TEXT | YES | Detailed plan description |
| `tokens_monthly` | INT | NO | Monthly token allocation |
| `periodicity` | ENUM | NO | monthly, annual, annual_monthly_billing |
| `price_mxn` | DECIMAL(10,2) | NO | Price in Mexican pesos |
| `price_cop` | DECIMAL(10,2) | NO | Price in Colombian pesos |
| `trial_days` | INT | NO | Trial period days |
| `active` | BOOLEAN | NO | Plan available for new subscriptions |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY:  `id`
- INDEX: `active`

**Relationships:**
- `plans` → `subscriptions` (1:N)

**Policies:**
- No soft delete (historical plans remain)
- Prices are fixed per currency (no automatic conversion)
- Inactive plan doesn't appear in selection, but existing subscriptions continue

---

### 2. subscriptions 🔒 **[UPDATED - Polymorphic + 3DS]**

**Description:** Subscriptions linked to any subscribable model (User, Company, Team, etc.)

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`subscriber_type`** 🆕 | **VARCHAR(255)** | **NO** | **Polymorphic model class (App\\Models\\User, App\\Models\\Company, etc.)** |
| **`subscriber_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Polymorphic model ID** |
| `plan_id` | BIGINT UNSIGNED | NO | FK → plans.id (current plan) |
| `status` | ENUM | NO | trial, active, past_due, grace_period, cancelled, blocked |
| `periodicity` | ENUM | NO | monthly, annual, annual_monthly_billing |
| `starts_at` | DATE | NO | Subscription start date |
| `ends_at` | DATE | YES | End date (NULL if active) |
| `next_billing_date` | DATE | NO | Next billing date |
| `card_token` | VARCHAR(255) | YES | Tokenized card from payment gateway |
| `manual_payment_reference` | VARCHAR(255) | YES | Manual payment reference |
| `mit_enabled` | BOOLEAN | NO | MIT enabled for recurring payments |
| `first_payment_3ds_completed` | BOOLEAN | NO | First payment with 3DS successful |
| `pending_plan_id` | BIGINT UNSIGNED | YES | FK → plans.id (for scheduled downgrades) |
| `pending_plan_change_date` | DATE | YES | Scheduled change date |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |
| `deleted_at` | TIMESTAMP | YES | Soft delete |

**Indexes:**
- PRIMARY KEY: `id`
- **INDEX: `subscriber_type`, `subscriber_id`** 🆕
- FOREIGN KEY: `plan_id` → `plans.id`
- FOREIGN KEY: `pending_plan_id` → `plans.id`
- INDEX: `status`, `next_billing_date`, `deleted_at`
- INDEX: `mit_enabled`, `first_payment_3ds_completed`

**Relationships:**
- **Subscriber (polymorphic)** → `subscriptions` (1:N)
- `plans` → `subscriptions` (1:N)
- `subscriptions` → `payments` (1:N)
- `subscriptions` → `tokens_usage` (1:N)
- `subscriptions` → `grace_periods` (1:N)

**Policies:**
- Soft delete enabled
- A subscriber can have multiple subscriptions (history)
- Only one active subscription per subscriber at a time

**Status:**
- `trial`: In trial period
- `active`: Active and up-to-date subscription
- `past_due`: Overdue payment (in retries)
- `grace_period`: In grace period (2 months)
- `cancelled`: Cancelled by subscriber
- `blocked`: Blocked for non-payment

**Polymorphic Usage:**
The package doesn't define what a "subscriber" is. It can be:
- `App\Models\User`
- `App\Models\Company`
- `App\Models\Team`
- `App\Models\Organization`
- Any model in your application that uses the `HasSubscription` trait

---

### 3. tokens_usage **[OPTIONAL MODULE - Polymorphic]**

**Description:** Token consumption tracking per billing period. Only created if `tokens` feature is enabled.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`subscriber_type`** 🆕 | **VARCHAR(255)** | **NO** | **Polymorphic model class** |
| **`subscriber_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Polymorphic model ID** |
| `subscription_id` | BIGINT UNSIGNED | NO | FK → subscriptions.id |
| `period_start` | DATE | NO | Billing period start |
| `period_end` | DATE | NO | Billing period end |
| `used` | INT | NO | Tokens used in period |
| `total` | INT | NO | Total tokens allocated |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- **INDEX: `subscriber_type`, `subscriber_id`** 🆕
- FOREIGN KEY: `subscription_id` → `subscriptions.id`
- INDEX: `subscription_id`, `period_start`

**Relationships:**
- **Subscriber (polymorphic)** → `tokens_usage` (1:N)
- `subscriptions` → `tokens_usage` (1:N)

**Policies:**
- New record created each billing period
- Unused tokens DO NOT accumulate (`used` field resets)
- Allows viewing consumption history

---

### 4. payments 🔒 **[UPDATED - 3DS]**

**Description:** Complete record of all payment attempts with 3DS support.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| `subscription_id` | BIGINT UNSIGNED | NO | FK → subscriptions.id |
| `amount` | DECIMAL(10,2) | NO | Payment amount |
| `currency` | VARCHAR(3) | NO | MXN or COP |
| `method` | ENUM | NO | card, bank_transfer |
| `status` | ENUM | NO | pending, processing, **requires_3ds**, **authenticating**, **authenticated**, completed, failed, refunded, cancelled |
| `openpay_transaction_id` | VARCHAR(255) | YES | Transaction ID in payment gateway |
| `attempt` | INT | NO | Attempt number (1, 2, 3) |
| `paid_at` | TIMESTAMP | YES | Payment completion date |
| `error_code` | VARCHAR(50) | YES | Error code if failed |
| `error_message` | TEXT | YES | Error message if failed |
| **`requires_3ds`** 🆕 | **BOOLEAN** | **NO** | **Payment requires 3DS authentication** |
| **`three_ds_status`** 🆕 | **ENUM** | **NO** | **not_required, pending, authenticated, failed, timeout** |
| **`three_ds_redirect_url`** 🆕 | **VARCHAR(500)** | **YES** | **Bank URL for authentication** |
| **`three_ds_version`** 🆕 | **VARCHAR(10)** | **YES** | **3DS version (1.0 or 2.0)** |
| **`authentication_required_notified_at`** 🆕 | **TIMESTAMP** | **YES** | **When user was notified** |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `subscription_id` → `subscriptions.id`
- INDEX: `status`, `openpay_transaction_id`, `subscription_id`
- INDEX: **`requires_3ds`, `three_ds_status`** 🆕

**Relationships:**
- `subscriptions` → `payments` (1:N)
- `payments` → `payment_retries` (1:N)
- `payments` → `invoices` (1:1)

**Policies:**
- NO soft delete (complete audit)
- Each charge attempt creates a record
- Status reflects payment lifecycle

**3DS-added statuses:**
- `requires_3ds`: Payment gateway requests user authentication
- `authenticating`: User is in bank modal
- `authenticated`: Successful authentication, processing charge

**3DS Fields:**
- `requires_3ds`: Boolean flag for quick filters
- `three_ds_status`: Detailed 3DS process status
- `three_ds_redirect_url`: URL for bank modal/iframe
- `three_ds_version`: Tracks which 3DS version was used
- `authentication_required_notified_at`: Timestamp of email #20 sent

---

### 5. coupons **[CORE]**

**Description:** Discount coupon catalog.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| `code` | VARCHAR(50) | NO | Unique coupon code |
| `type` | ENUM | NO | percentage, fixed |
| `value` | DECIMAL(10,2) | NO | Discount value (% or fixed amount) |
| `duration_months` | INT | YES | Duration in months (NULL = permanent) |
| `applicable_plans` | JSON | YES | Applicable plan IDs (NULL = all) |
| `usage_limit` | INT | YES | Total usage limit (NULL = unlimited) |
| `current_usage` | INT | NO | Current usage count |
| `expires_at` | DATE | YES | Expiration date (NULL = doesn't expire) |
| `active` | BOOLEAN | NO | Coupon is active |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- UNIQUE: `code`
- INDEX: `active`, `expires_at`

**Relationships:**
- `coupons` → `subscriber_coupons` (1:N)

**Policies:**
- No soft delete
- Codes are case-insensitive when validating
- Inactive coupon cannot be applied

---

### 6. subscriber_coupons **[CORE - Polymorphic]**

**Description:** Record of coupons applied by subscribers (prevents reuse).

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`subscriber_type`** 🆕 | **VARCHAR(255)** | **NO** | **Polymorphic model class** |
| **`subscriber_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Polymorphic model ID** |
| `coupon_id` | BIGINT UNSIGNED | NO | FK → coupons.id |
| `applied_at` | TIMESTAMP | NO | Application date |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `coupon_id` → `coupons.id`
- **UNIQUE: `subscriber_type` + `subscriber_id` + `coupon_id`** (prevents duplicate usage) 🆕
- **INDEX: `subscriber_type`, `subscriber_id`** 🆕

**Relationships:**
- **Subscriber (polymorphic)** → `subscriber_coupons` (1:N)
- `coupons` → `subscriber_coupons` (1:N)

**Policies:**
- NO soft delete (audit)
- A subscriber can have multiple coupons (different ones)
- A subscriber CANNOT reuse the same coupon

---

### 7. referrals **[OPTIONAL MODULE - Polymorphic]**

**Description:** Referral system with benefit tracking. Only created if `referrals` feature is enabled.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`referrer_type`** 🆕 | **VARCHAR(255)** | **NO** | **Referrer polymorphic model class** |
| **`referrer_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Referrer polymorphic model ID** |
| **`referred_type`** 🆕 | **VARCHAR(255)** | **NO** | **Referred polymorphic model class** |
| **`referred_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Referred polymorphic model ID** |
| `code` | VARCHAR(50) | NO | Unique referral code |
| `referrer_benefit` | JSON | NO | Referrer benefits (discount, tokens, credit) |
| `referred_benefit` | JSON | NO | Referred benefits (discount) |
| `status` | ENUM | NO | pending, completed, expired |
| `completed_at` | TIMESTAMP | YES | Completion date |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- **INDEX: `referrer_type`, `referrer_id`** 🆕
- **INDEX: `referred_type`, `referred_id`** 🆕
- UNIQUE: `code`
- INDEX: `status`

**Relationships:**
- **Subscriber (polymorphic)** as referrer → `referrals` (1:N)
- **Subscriber (polymorphic)** as referred → `referrals` (1:N)

**Policies:**
- NO soft delete (audit)
- A subscriber can refer multiple people
- A subscriber can be referred only once

**Example `referrer_benefit` JSON:**
```json
{
  "discount": {"type": "percentage", "value": 20, "duration_months": 1},
  "tokens": 1000,
  "credit": {"amount": 100, "currency": "MXN"}
}
```

**Status:**
- `pending`: Referred registered but hasn't paid
- `completed`: Referred made first payment, benefits granted
- `expired`: Referred cancelled trial without paying

---

### 8. billing_data **[CORE - Polymorphic]**

**Description:** Tax/billing data for electronic invoicing.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`billable_type`** 🆕 | **VARCHAR(255)** | **NO** | **Billable polymorphic model class** |
| **`billable_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Billable polymorphic model ID** |
| `country` | ENUM | NO | MX, CO |
| `tax_id` | VARCHAR(50) | NO | RFC (MX) or NIT (CO) |
| `legal_name` | VARCHAR(255) | NO | Legal name |
| `tax_regime` | VARCHAR(100) | YES | Tax regime (MX only) |
| `postal_code` | VARCHAR(10) | YES | Postal code (MX only) |
| `cfdi_use` | VARCHAR(10) | YES | CFDI use (MX only) |
| `person_type` | ENUM | YES | natural, legal (CO only) |
| `address` | TEXT | YES | Full address (CO only) |
| `city` | VARCHAR(100) | YES | City (CO only) |
| `state` | VARCHAR(100) | YES | State/Department (CO only) |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- **UNIQUE: `billable_type` + `billable_id`** (1:1 relationship) 🆕
- INDEX: `country`

**Relationships:**
- **Subscriber (polymorphic)** → `billing_data` (1:1)

**Policies:**
- NO soft delete
- RFC/NIT validation according to each country format
- MX fields are NULL for CO users and vice versa

---

### 9. invoices **[OPTIONAL MODULE - Polymorphic]**

**Description:** Electronic invoice requests and records. Only created if `invoicing` feature is enabled.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`invoiceable_type`** 🆕 | **VARCHAR(255)** | **NO** | **Invoiceable polymorphic model class** |
| **`invoiceable_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Invoiceable polymorphic model ID** |
| `payment_id` | BIGINT UNSIGNED | NO | FK → payments.id |
| `file_url` | VARCHAR(500) | YES | PDF file path |
| `requested_at` | TIMESTAMP | NO | Request date |
| `sent_at` | TIMESTAMP | YES | Sent date |
| `status` | ENUM | NO | requested, processing, completed, failed |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- **INDEX: `invoiceable_type`, `invoiceable_id`** 🆕
- FOREIGN KEY: `payment_id` → `payments.id`
- INDEX: `status`

**Relationships:**
- **Subscriber (polymorphic)** → `invoices` (1:N)
- `payments` → `invoices` (1:1)

**Policies:**
- NO soft delete (tax audit)
- A payment can have only one invoice
- User can re-download invoice indefinitely

---

### 10. payment_retries

**Description:** Record of failed payment retries.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| `payment_id` | BIGINT UNSIGNED | NO | FK → payments.id |
| `attempt` | INT | NO | Retry number (1, 2, 3) |
| `tried_at` | TIMESTAMP | NO | Retry date and time |
| `result` | TEXT | YES | Retry result (success or failure reason) |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `payment_id` → `payments.id`
- INDEX: `payment_id`, `tried_at`

**Relationships:**
- `payments` → `payment_retries` (1:N)

**Policies:**
- NO soft delete (audit)
- Maximum 3 attempts per payment
- Each retry is scheduled according to configured days

---

### 11. grace_periods

**Description:** Grace periods granted for payment failures.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| `subscription_id` | BIGINT UNSIGNED | NO | FK → subscriptions.id |
| `started_at` | DATE | NO | Grace period start date |
| `ends_at` | DATE | NO | Grace period end date (2 months later) |
| `months_owed` | INT | NO | Months owed |
| `amount_owed` | DECIMAL(10,2) | NO | Total amount owed |
| `notifications_sent` | INT | NO | Number of notifications sent |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `subscription_id` → `subscriptions.id`
- INDEX: `subscription_id`, `ends_at`

**Relationships:**
- `subscriptions` → `grace_periods` (1:N, but ideally 1:1 active)

**Policies:**
- NO soft delete (audit)
- Fixed duration: 2 months
- Reminders every 15 days (configurable)
- Subscriber maintains full access during grace period

---

### 12. notifications **[CORE - Polymorphic]**

**Description:** Log of all notifications sent (20+ types).

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`notifiable_type`** 🆕 | **VARCHAR(255)** | **NO** | **Notifiable polymorphic model class** |
| **`notifiable_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Notifiable polymorphic model ID** |
| `type` | VARCHAR(100) | NO | Notification type (20+ types) |
| `sent_at` | TIMESTAMP | YES | Send date and time |
| `status` | ENUM | NO | pending, sent, failed, bounced |
| `metadata` | JSON | YES | Additional notification data |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- **INDEX: `notifiable_type`, `notifiable_id`** 🆕
- INDEX: `type`, `status`, `sent_at`

**Relationships:**
- **Subscriber (polymorphic)** → `notifications` (1:N)

**Policies:**
- NO soft delete (audit)
- Allows manual resend if failed
- Complete tracking for metrics

**Notification types (20+):**
1. `welcome`
2. `payment_success`
3. `payment_reminder`
4. `payment_failed`
5. `manual_payment_order`
6. `grace_period_start`
7. `grace_period_reminder`
8. `subscription_cancelled`
9. `plan_changed`
10. `referral_successful`
11. `referral_discount_code`
12. `invoice_available`
13. `tokens_50`
14. `tokens_75`
15. `tokens_90`
16. `tokens_100`
17. `trial_expiring`
18. `trial_expired`
19. `subscription_reactivated`
20. **`payment_authentication_required`** 🆕

---

### 13. audit_logs **[CORE - Polymorphic]**

**Description:** Audit log of all critical actions.

| Field | Type | Null | Description |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | PK, Auto-increment |
| **`auditable_type`** 🆕 | **VARCHAR(255)** | **YES** | **Auditable polymorphic model class (NULL for system)** |
| **`auditable_id`** 🆕 | **BIGINT UNSIGNED** | **YES** | **Auditable polymorphic model ID (NULL for system)** |
| `action` | VARCHAR(100) | NO | Action performed (create, update, delete, etc.) |
| `entity` | VARCHAR(100) | NO | Affected entity (subscription, payment, etc.) |
| `entity_id` | BIGINT UNSIGNED | NO | Affected record ID |
| `before` | JSON | YES | State before change |
| `after` | JSON | YES | State after change |
| `ip` | VARCHAR(45) | YES | IP from which action was performed |
| `created_at` | TIMESTAMP | YES | Creation date |
| `updated_at` | TIMESTAMP | YES | Last update date |

**Indexes:**
- PRIMARY KEY: `id`
- **INDEX: `auditable_type`, `auditable_id`** 🆕
- INDEX: `entity`, `entity_id`, `created_at`

**Relationships:**
- **Subscriber (polymorphic)** → `audit_logs` (1:N)

**Policies:**
- NO soft delete (permanent audit)
- Immutable (INSERT only)
- Retention: indefinite or according to compliance policies

---

## Relationships

### Simplified Relationship Diagram

```
Subscriber (polymorphic) ──── (N) subscriptions
Subscriber (polymorphic) ──── (N) tokens_usage [OPTIONAL]
Subscriber (polymorphic) ──── (1) billing_data
Subscriber (polymorphic) ──── (N) subscriber_coupons
Subscriber (polymorphic) ──── (N) referrals (as referrer) [OPTIONAL]
Subscriber (polymorphic) ──── (N) referrals (as referred) [OPTIONAL]
Subscriber (polymorphic) ──── (N) notifications
Subscriber (polymorphic) ──── (N) invoices [OPTIONAL]
Subscriber (polymorphic) ──── (N) audit_logs

plans (1) ──────────────────── (N) subscriptions
subscriptions (1) ────────────  (N) payments
subscriptions (1) ────────────  (N) grace_periods
payments (1) ─────────────────  (N) payment_retries
payments (1) ─────────────────  (1) invoices [OPTIONAL]
coupons (1) ──────────────────  (N) subscriber_coupons
```

### Polymorphic Relationships Explanation

The package uses **polymorphic relationships** for maximum flexibility. Instead of hardcoding a relationship to a `users` table, it uses two columns:

- `{relation}_type`: The model class (e.g., `App\Models\User`, `App\Models\Company`)
- `{relation}_id`: The model's ID

This allows the package to work with **any** model in your application. Examples:

**Subscriber Model Examples:**
- `App\Models\User` (individual users)
- `App\Models\Company` (company subscriptions)
- `App\Models\Team` (team subscriptions)
- `App\Models\Organization` (organizational subscriptions)

**Usage in your application:**
```php
// User subscription
$user = User::find(1);
$user->subscribeToPlan($plan);

// Company subscription  
$company = Company::find(1);
$company->subscribeToPlan($plan);

// Team subscription
$team = Team::find(1);
$team->subscribeToPlan($plan);
```

All these models would use the `HasSubscription` trait provided by the package.

---

## Recommended Indexes

### Critical Performance Indexes

**Frequent queries:**

```sql
-- Get subscriptions to renew today
SELECT * FROM subscriptions 
WHERE next_billing_date <= CURDATE() 
AND status = 'active';
-- INDEX: (next_billing_date, status)

-- Get payments requiring 3DS without notification
SELECT * FROM payments 
WHERE requires_3ds = true 
AND authentication_required_notified_at IS NULL;
-- INDEX: (requires_3ds, authentication_required_notified_at)

-- Get subscriber's current tokens
SELECT * FROM tokens_usage 
WHERE subscriber_type = ? AND subscriber_id = ?
ORDER BY period_start DESC 
LIMIT 1;
-- INDEX: (subscriber_type, subscriber_id, period_start)

-- Validate coupon
SELECT * FROM coupons 
WHERE code = ?  
AND active = true 
AND (expires_at IS NULL OR expires_at >= CURDATE());
-- INDEX: (code, active, expires_at)
```

### Additional Composite Indexes

```sql
CREATE INDEX idx_subscriptions_renewal 
ON subscriptions(next_billing_date, status);

CREATE INDEX idx_payments_3ds_pending 
ON payments(requires_3ds, three_ds_status, authentication_required_notified_at);

CREATE INDEX idx_tokens_subscriber_period 
ON tokens_usage(subscriber_type, subscriber_id, period_start DESC);

CREATE INDEX idx_grace_periods_active 
ON grace_periods(subscription_id, ends_at);

CREATE INDEX idx_notifications_pending 
ON notifications(status, created_at) 
WHERE status = 'pending';
```

---

## Deletion Policies

### Soft Delete Enabled

The following table uses soft delete (`deleted_at`):
- ✅ `subscriptions`

**Reason:** Allows recovery and maintains referential integrity.

### No Soft Delete (Audit)

The following tables DO NOT use soft delete:
- ❌ `payments` - Tax audit
- ❌ `invoices` - Legal obligation
- ❌ `payment_retries` - Traceability
- ❌ `grace_periods` - Audit
- ❌ `subscriber_coupons` - Prevent reuse
- ❌ `referrals` - Complete tracking
- ❌ `audit_logs` - Immutable
- ❌ `notifications` - Traceability

### Deletion Cascades

```sql
-- Note: Since we use polymorphic relationships, we don't have 
-- traditional foreign keys to subscriber models. The host application
-- is responsible for cleaning up package data when deleting subscribable models.

-- Example cleanup (should be handled by host application):
-- When deleting a User/Company/Team, cascade delete:
Subscription::where('subscriber_type', User::class)
    ->where('subscriber_id', $userId)
    ->delete();

-- Existing cascades within package tables:
ALTER TABLE payments
ADD CONSTRAINT fk_payments_subscription
FOREIGN KEY (subscription_id) REFERENCES subscriptions(id)
ON DELETE RESTRICT; -- Cannot delete subscription with payments
```

**Recommended policy:**
- Subscriptions can be soft-deleted
- Payments/invoices: RESTRICT (no deletion if they exist)
- Everything else: Handle manually or via application logic

---

## Summary of 3DS and Polymorphic Changes

### Tables Modified for Polymorphic Relationships

**1. subscriptions:**
- ✅ `subscriber_type` (VARCHAR 255) - Polymorphic model class
- ✅ `subscriber_id` (BIGINT UNSIGNED) - Polymorphic model ID
- ✅ Removed `user_id` foreign key

**2. tokens_usage:**
- ✅ `subscriber_type` (VARCHAR 255)
- ✅ `subscriber_id` (BIGINT UNSIGNED)
- ✅ Removed `user_id` foreign key

**3. subscriber_coupons (renamed from user_coupons):**
- ✅ `subscriber_type` (VARCHAR 255)
- ✅ `subscriber_id` (BIGINT UNSIGNED)
- ✅ Removed `user_id` foreign key
- ✅ Table renamed

**4. referrals:**
- ✅ `referrer_type` (VARCHAR 255)
- ✅ `referrer_id` (BIGINT UNSIGNED)
- ✅ `referred_type` (VARCHAR 255)
- ✅ `referred_id` (BIGINT UNSIGNED)
- ✅ Removed `referrer_id` and `referred_id` foreign keys to users

**5. billing_data:**
- ✅ `billable_type` (VARCHAR 255)
- ✅ `billable_id` (BIGINT UNSIGNED)
- ✅ Removed `user_id` foreign key

**6. invoices:**
- ✅ `invoiceable_type` (VARCHAR 255)
- ✅ `invoiceable_id` (BIGINT UNSIGNED)
- ✅ Removed `user_id` foreign key

**7. notifications:**
- ✅ `notifiable_type` (VARCHAR 255)
- ✅ `notifiable_id` (BIGINT UNSIGNED)
- ✅ Removed `user_id` foreign key

**8. audit_logs:**
- ✅ `auditable_type` (VARCHAR 255, nullable)
- ✅ `auditable_id` (BIGINT UNSIGNED, nullable)
- ✅ Removed `user_id` foreign key

### Tables Modified for 3DS

**1. subscriptions:**
- ✅ `mit_enabled` (BOOLEAN)
- ✅ `first_payment_3ds_completed` (BOOLEAN)

**2. payments:**
- ✅ `requires_3ds` (BOOLEAN)
- ✅ `three_ds_status` (ENUM)
- ✅ `three_ds_redirect_url` (VARCHAR 500)
- ✅ `three_ds_version` (VARCHAR 10)
- ✅ `authentication_required_notified_at` (TIMESTAMP)
- ✅ ENUM status updated: `requires_3ds`, `authenticating`, `authenticated`

**3. notifications:**
- ✅ New type: `payment_authentication_required`

### New Indexes for Polymorphic Relationships

```sql
CREATE INDEX idx_subscriber ON subscriptions(subscriber_type, subscriber_id);
CREATE INDEX idx_subscriber ON tokens_usage(subscriber_type, subscriber_id);
CREATE INDEX idx_subscriber ON subscriber_coupons(subscriber_type, subscriber_id);
CREATE INDEX idx_referrer ON referrals(referrer_type, referrer_id);
CREATE INDEX idx_referred ON referrals(referred_type, referred_id);
CREATE INDEX idx_billable ON billing_data(billable_type, billable_id);
CREATE INDEX idx_invoiceable ON invoices(invoiceable_type, invoiceable_id);
CREATE INDEX idx_notifiable ON notifications(notifiable_type, notifiable_id);
CREATE INDEX idx_auditable ON audit_logs(auditable_type, auditable_id);
```

### New Indexes for 3DS

```sql
CREATE INDEX idx_subscriptions_mit ON subscriptions(mit_enabled);
CREATE INDEX idx_payments_3ds ON payments(requires_3ds, three_ds_status);
CREATE INDEX idx_payments_auth_notified ON payments(authentication_required_notified_at);
```

---

## 📚 References

- [DATABASE_DDL.sql](./DATABASE_DDL.sql) - Complete SQL scripts
- [3DS Integration](./3DS_INTEGRATION.md) - 3DS integration details
- [API Webhooks](./API_WEBHOOKS.md) - Webhooks affecting these tables
- [Polymorphic Relationships](./POLYMORPHIC_RELATIONSHIPS.md) - Usage guide

---

**Version:** 2.0  
**Changes:**
- ✅ Removed users table - package uses polymorphic relationships
- ✅ All foreign keys to users converted to polymorphic (subscriber_type/subscriber_id, etc.)
- ✅ Renamed user_coupons to subscriber_coupons
- ✅ Added billable_type/billable_id to billing_data
- ✅ Added referrer_type/referrer_id and referred_type/referred_id to referrals
- ✅ Added notifiable_type/notifiable_id to notifications
- ✅ Added invoiceable_type/invoiceable_id to invoices
- ✅ Added auditable_type/auditable_id to audit_logs
- ✅ Marked optional modules: tokens_usage, referrals, invoices
- ✅ Marked core modules: subscriptions, payments, coupons, subscriber_coupons
- ✅ Updated all indexes for polymorphic relationships
- ✅ Added 3DS fields in payments and subscriptions
- ✅ Added `payment_authentication_required` notification type
- ✅ Complete documentation for each table

---

**End of Document**