# Esquema de Base de Datos
## Paquete Gestor de Suscripciones Laravel

**Versión:** 2.0  
**Fecha:** Enero 2026  
**Actualización:** Relaciones Polimórficas (subscriber_type/subscriber_id) + Períodos Personalizables

---

## 📑 Tabla de Contenidos

1. [Diagrama ERD](#diagrama-erd)
2. [Categorías de Tablas](#categorías-de-tablas)
3. [Descripciones de Tablas](#descripciones-de-tablas)
4. [Relaciones](#relaciones)
5. [Índices Recomendados](#índices-recomendados)
6. [Políticas de Eliminación](#políticas-de-eliminación)

---

## Diagrama ERD

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
        int trial_days "Custom trial (NULL = use plan trial)"
        date trial_ends_at "Calculated trial end date"
        int grace_period_months "Custom grace (NULL = use global config)"
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
        string type "20+ tipos"
        timestamp sent_at
        enum status "pending, sent, failed, bounced"
        json metadata
        timestamps created_at_updated_at
    }
    
    audit_logs {
        bigint id PK
        string auditable_type "Tipo polimórfico, NULL para sistema"
        bigint auditable_id "ID polimórfico, NULL para sistema"
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

## Categorías de Tablas

### Tablas Core (Siempre Incluidas)
- `plans` - Catálogo de planes de suscripción
- `subscriptions` - Suscripciones de suscriptores (polimórfico)
- `payments` - Registros de pagos con soporte 3DS
- `payment_retries` - Seguimiento de reintentos de pago
- `grace_periods` - Gestión de períodos de gracia
- `billing_data` - Datos fiscales/facturación (polimórfico)
- `coupons` ✅ - Catálogo de cupones de descuento
- `subscriber_coupons` ✅ - Cupones aplicados (polimórfico)
- `notifications` - Registro de notificaciones (polimórfico)
- `audit_logs` - Registro de auditoría (polimórfico)

### Tablas Opcionales (Migraciones Separadas)
- `tokens_usage` - Solo si la característica `tokens` está habilitada
- `referrals` - Solo si la característica `referrals` está habilitada
- `invoices` - Solo si la característica `invoicing` está habilitada

### No Incluidas (Responsabilidad de la Aplicación Host)
- `users` o cualquier modelo suscriptor - El paquete usa **relaciones polimórficas** para trabajar con cualquier modelo suscribible proporcionado por la aplicación host

---

## Descripciones de Tablas

### 1. plans

**Descripción:** Catálogo de planes de suscripción disponibles.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| `name` | VARCHAR(255) | NO | Nombre del plan |
| `description` | TEXT | SÍ | Descripción detallada del plan |
| `tokens_monthly` | INT | NO | Asignación mensual de tokens |
| `periodicity` | ENUM | NO | monthly, annual, annual_monthly_billing |
| `price_mxn` | DECIMAL(10,2) | NO | Precio en pesos mexicanos |
| `price_cop` | DECIMAL(10,2) | NO | Precio en pesos colombianos |
| `trial_days` | INT | NO | Días de período de prueba |
| `active` | BOOLEAN | NO | Plan disponible para nuevas suscripciones |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- ÍNDICE: `active`

**Relaciones:**
- `plans` → `subscriptions` (1:N)

**Políticas:**
- Sin borrado suave (los planes históricos permanecen)
- Los precios son fijos por moneda (sin conversión automática)
- Plan inactivo no aparece en selección, pero suscripciones existentes continúan

---

### 2. subscriptions 🔒 **[ACTUALIZADO - Polimórfico + 3DS + Períodos Personalizables]**

**Descripción:** Suscripciones vinculadas a cualquier modelo suscribible (User, Company, Team, etc.)

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`subscriber_type`** 🆕 | **VARCHAR(255)** | **NO** | **Clase del modelo polimórfico (App\\Models\\User, App\\Models\\Company, etc.)** |
| **`subscriber_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **ID del modelo polimórfico** |
| `plan_id` | BIGINT UNSIGNED | NO | FK → plans.id (plan actual) |
| **`trial_days`** 🆕 | **INT** | **SÍ** | **Trial personalizado en días. Si es NULL, usa `plans.trial_days`. Permite promociones especiales o ajustes manuales.** |
| **`trial_ends_at`** 🆕 | **DATE** | **SÍ** | **Fecha calculada de fin del trial. Se calcula automáticamente al crear la suscripción.** |
| **`grace_period_months`** 🆕 | **INT** | **SÍ** | **Período de gracia personalizado en meses. Si es NULL, usa configuración global (2 meses). Permite ajuste por nivel de cliente.** |
| `status` | ENUM | NO | trial, active, past_due, grace_period, cancelled, blocked |
| `periodicity` | ENUM | NO | monthly, annual, annual_monthly_billing |
| `starts_at` | DATE | NO | Fecha de inicio de suscripción |
| `ends_at` | DATE | SÍ | Fecha de fin (NULL si está activa) |
| `next_billing_date` | DATE | NO | Próxima fecha de facturación |
| `card_token` | VARCHAR(255) | SÍ | Tarjeta tokenizada de la pasarela de pagos |
| `manual_payment_reference` | VARCHAR(255) | SÍ | Referencia de pago manual |
| `mit_enabled` | BOOLEAN | NO | MIT habilitado para pagos recurrentes |
| `first_payment_3ds_completed` | BOOLEAN | NO | Primer pago con 3DS exitoso |
| `pending_plan_id` | BIGINT UNSIGNED | SÍ | FK → plans.id (para downgrades programados) |
| `pending_plan_change_date` | DATE | SÍ | Fecha de cambio programada |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |
| `deleted_at` | TIMESTAMP | SÍ | Borrado suave |

**Índices:**
- CLAVE PRIMARIA: `id`
- **ÍNDICE: `subscriber_type`, `subscriber_id`** 🆕
- CLAVE FORÁNEA: `plan_id` → `plans.id`
- CLAVE FORÁNEA: `pending_plan_id` → `plans.id`
- ÍNDICE: `status`, `next_billing_date`, `deleted_at`
- ÍNDICE: `mit_enabled`, `first_payment_3ds_completed`
- **ÍNDICE: `trial_ends_at`** 🆕

**Relaciones:**
- **Subscriber (polimórfico)** → `subscriptions` (1:N)
- `plans` → `subscriptions` (1:N)
- `subscriptions` → `payments` (1:N)
- `subscriptions` → `tokens_usage` (1:N)
- `subscriptions` → `grace_periods` (1:N)

**Políticas:**
- Borrado suave habilitado
- Un suscriptor puede tener múltiples suscripciones (historial)
- Solo una suscripción activa por suscriptor a la vez

**Estados:**
- `trial`: En período de prueba
- `active`: Suscripción activa y al día
- `past_due`: Pago vencido (en reintentos)
- `grace_period`: En período de gracia (personalizable)
- `cancelled`: Cancelada por el suscriptor
- `blocked`: Bloqueada por falta de pago

**Uso Polimórfico:**
El paquete no define qué es un "suscriptor". Puede ser:
- `App\Models\User`
- `App\Models\Company`
- `App\Models\Team`
- `App\Models\Organization`
- Cualquier modelo en tu aplicación que use el trait `HasSubscription`

**Reglas de Negocio:**

### Trial Personalizable

**Lógica de Aplicación:**
1. Si `subscriptions.trial_days` es NULL → usar `plans.trial_days` (comportamiento estándar)
2. Si `subscriptions.trial_days` tiene valor → usar ese valor (override personalizado)
3. Si `subscriptions.trial_days = 0` → sin trial (pago inmediato)

**Casos de Uso:**
- Trial estándar: `trial_days = NULL` (hereda del plan)
- Promoción especial: `trial_days = 60` (60 días aunque el plan tenga 30)
- Cliente corporativo: `trial_days = 0` (sin trial, pago inmediato)
- Ajuste manual admin: Cualquier valor personalizado

**Cálculo de `trial_ends_at`:**
```php
// Pseudocódigo
$trialDays = $subscription->trial_days ?? $subscription->plan->trial_days;
$subscription->trial_ends_at = $subscription->starts_at->addDays($trialDays);
```

### Período de Gracia Personalizable

**Lógica de Aplicación:**
1. Si `subscriptions.grace_period_months` es NULL → usar config global (2 meses)
2. Si `subscriptions.grace_period_months` tiene valor → usar ese valor personalizado
3. Si `subscriptions.grace_period_months = 0` → bloqueo inmediato (sin gracia)

**Casos de Uso:**
- Cliente estándar: `grace_period_months = NULL` (2 meses por defecto)
- Cliente premium: `grace_period_months = 6` (6 meses de tolerancia)
- Cliente problemático: `grace_period_months = 0` (bloqueo inmediato)
- Ajuste temporal admin: Cualquier valor de 1-12 meses

**Ejemplo de Creación de Período de Gracia:**
```php
// Pseudocode
$graceMonths = $subscription->grace_period_months ?? config('subscriptions.grace_period.months', 2);

$gracePeriod = GracePeriod::create([
    'subscription_id' => $subscription->id,
    'started_at' => now(),
    'ends_at' => now()->addMonths($graceMonths),
]);
```

---

### 3. tokens_usage **[MÓDULO OPCIONAL - Polimórfico]**

**Descripción:** Seguimiento de consumo de tokens por período de facturación. Solo se crea si la característica `tokens` está habilitada.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`subscriber_type`** 🆕 | **VARCHAR(255)** | **NO** | **Clase del modelo polimórfico** |
| **`subscriber_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **ID del modelo polimórfico** |
| `subscription_id` | BIGINT UNSIGNED | NO | FK → subscriptions.id |
| `period_start` | DATE | NO | Inicio del período de facturación |
| `period_end` | DATE | NO | Fin del período de facturación |
| `used` | INT | NO | Tokens utilizados en el período |
| `total` | INT | NO | Total de tokens asignados |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- **ÍNDICE: `subscriber_type`, `subscriber_id`** 🆕
- CLAVE FORÁNEA: `subscription_id` → `subscriptions.id`
- ÍNDICE: `subscription_id`, `period_start`

**Relaciones:**
- **Subscriber (polymorphic)** → `tokens_usage` (1:N)
- `subscriptions` → `tokens_usage` (1:N)

**Políticas:**
- Se crea un nuevo registro cada período de facturación
- Los tokens no utilizados NO se acumulan (el campo `used` se reinicia)
- Permite ver historial de consumo

---

### 4. payments 🔒 **[ACTUALIZADO - 3DS]**

**Descripción:** Registro completo de todos los intentos de pago con soporte 3DS.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| `subscription_id` | BIGINT UNSIGNED | NO | FK → subscriptions.id |
| `amount` | DECIMAL(10,2) | NO | Monto del pago |
| `currency` | VARCHAR(3) | NO | MXN o COP |
| `method` | ENUM | NO | card, bank_transfer |
| `status` | ENUM | NO | pending, processing, **requires_3ds**, **authenticating**, **authenticated**, completed, failed, refunded, cancelled |
| `openpay_transaction_id` | VARCHAR(255) | SÍ | ID de transacción en la pasarela de pagos |
| `attempt` | INT | NO | Número de intento (1, 2, 3) |
| `paid_at` | TIMESTAMP | SÍ | Fecha de finalización del pago |
| `error_code` | VARCHAR(50) | SÍ | Código de error si falló |
| `error_message` | TEXT | SÍ | Mensaje de error si falló |
| **`requires_3ds`** 🆕 | **BOOLEAN** | **NO** | **El pago requiere autenticación 3DS** |
| **`three_ds_status`** 🆕 | **ENUM** | **NO** | **not_required, pending, authenticated, failed, timeout** |
| **`three_ds_redirect_url`** 🆕 | **VARCHAR(500)** | **YES** | **Bank URL for authentication** |
| **`three_ds_version`** 🆕 | **VARCHAR(10)** | **YES** | **3DS version (1.0 or 2.0)** |
| **`authentication_required_notified_at`** 🆕 | **TIMESTAMP** | **YES** | **When user was notified** |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- CLAVE FORÁNEA: `subscription_id` → `subscriptions.id`
- ÍNDICE: `status`, `openpay_transaction_id`, `subscription_id`
- ÍNDICE: **`requires_3ds`, `three_ds_status`** 🆕

**Relaciones:**
- `subscriptions` → `payments` (1:N)
- `payments` → `payment_retries` (1:N)
- `payments` → `invoices` (1:1)

**Políticas:**
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

**Descripción:** Discount coupon catalog.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| `code` | VARCHAR(50) | NO | Unique coupon code |
| `type` | ENUM | NO | percentage, fixed |
| `value` | DECIMAL(10,2) | NO | Valor del descuento (% or fixed amount) |
| `duration_months` | INT | SÍ | Duration in months (NULL = permanent) |
| `applicable_plans` | JSON | SÍ | Applicable plan IDs (NULL = all) |
| `usage_limit` | INT | SÍ | Total usage limit (NULL = unlimited) |
| `current_usage` | INT | NO | Current usage count |
| `expires_at` | DATE | SÍ | Fecha de expiración (NULL = doesn't expire) |
| `active` | BOOLEAN | NO | Coupon is active |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- UNIQUE: `code`
- ÍNDICE: `active`, `expires_at`

**Relaciones:**
- `coupons` → `subscriber_coupons` (1:N)

**Políticas:**
- No soft delete
- Codes are case-insensitive when validating
- Inactive coupon cannot be applied

---

### 6. subscriber_coupons **[CORE - Polimórfico]**

**Descripción:** Record of coupons applied by subscribers (prevents reuse).

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`subscriber_type`** 🆕 | **VARCHAR(255)** | **NO** | **Clase del modelo polimórfico** |
| **`subscriber_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **ID del modelo polimórfico** |
| `coupon_id` | BIGINT UNSIGNED | NO | FK → coupons.id |
| `applied_at` | TIMESTAMP | NO | Application date |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- CLAVE FORÁNEA: `coupon_id` → `coupons.id`
- **UNIQUE: `subscriber_type` + `subscriber_id` + `coupon_id`** (prevents duplicate usage) 🆕
- **ÍNDICE: `subscriber_type`, `subscriber_id`** 🆕

**Relaciones:**
- **Subscriber (polymorphic)** → `subscriber_coupons` (1:N)
- `coupons` → `subscriber_coupons` (1:N)

**Políticas:**
- SIN borrado suave (auditoría)
- A subscriber can have multiple coupons (different ones)
- A subscriber CANNOT reuse the same coupon

---

### 7. referrals **[MÓDULO OPCIONAL - Polimórfico]**

**Descripción:** Referral system with benefit tracking. Only created if `referrals` feature is enabled.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`referrer_type`** 🆕 | **VARCHAR(255)** | **NO** | **Referrer polymorphic model class** |
| **`referrer_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Referrer polymorphic model ID** |
| **`referred_type`** 🆕 | **VARCHAR(255)** | **NO** | **Referred polymorphic model class** |
| **`referred_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Referred polymorphic model ID** |
| `code` | VARCHAR(50) | NO | Unique referral code |
| `referrer_benefit` | JSON | NO | Referrer benefits (discount, tokens, credit) |
| `referred_benefit` | JSON | NO | Referred benefits (discount) |
| `status` | ENUM | NO | pending, completed, expired |
| `completed_at` | TIMESTAMP | SÍ | Completion date |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- **ÍNDICE: `referrer_type`, `referrer_id`** 🆕
- **ÍNDICE: `referred_type`, `referred_id`** 🆕
- UNIQUE: `code`
- ÍNDICE: `status`

**Relaciones:**
- **Subscriber (polymorphic)** as referrer → `referrals` (1:N)
- **Subscriber (polymorphic)** as referred → `referrals` (1:N)

**Políticas:**
- SIN borrado suave (auditoría)
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

### 8. billing_data **[CORE - Polimórfico]**

**Descripción:** Tax/billing data for electronic invoicing.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`billable_type`** 🆕 | **VARCHAR(255)** | **NO** | **Billable polymorphic model class** |
| **`billable_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Billable polymorphic model ID** |
| `country` | ENUM | NO | MX, CO |
| `tax_id` | VARCHAR(50) | NO | RFC (MX) or NIT (CO) |
| `legal_name` | VARCHAR(255) | NO | Legal name |
| `tax_regime` | VARCHAR(100) | SÍ | Tax regime (MX only) |
| `postal_code` | VARCHAR(10) | SÍ | Código postal (MX only) |
| `cfdi_use` | VARCHAR(10) | SÍ | CFDI use (MX only) |
| `person_type` | ENUM | SÍ | natural, legal (CO only) |
| `address` | TEXT | SÍ | Full address (CO only) |
| `city` | VARCHAR(100) | SÍ | City (CO only) |
| `state` | VARCHAR(100) | SÍ | State/Department (CO only) |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- **UNIQUE: `billable_type` + `billable_id`** (1:1 relationship) 🆕
- ÍNDICE: `country`

**Relaciones:**
- **Subscriber (polymorphic)** → `billing_data` (1:1)

**Políticas:**
- NO soft delete
- RFC/NIT validation according to each country format
- MX fields are NULL for CO users and vice versa

---

### 9. invoices **[MÓDULO OPCIONAL - Polimórfico]**

**Descripción:** Electronic invoice requests and records. Only created if `invoicing` feature is enabled.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`invoiceable_type`** 🆕 | **VARCHAR(255)** | **NO** | **Invoiceable polymorphic model class** |
| **`invoiceable_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Invoiceable polymorphic model ID** |
| `payment_id` | BIGINT UNSIGNED | NO | FK → payments.id |
| `file_url` | VARCHAR(500) | SÍ | PDF file path |
| `requested_at` | TIMESTAMP | NO | Request date |
| `sent_at` | TIMESTAMP | SÍ | Sent date |
| `status` | ENUM | NO | requested, processing, completed, failed |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- **ÍNDICE: `invoiceable_type`, `invoiceable_id`** 🆕
- CLAVE FORÁNEA: `payment_id` → `payments.id`
- ÍNDICE: `status`

**Relaciones:**
- **Subscriber (polymorphic)** → `invoices` (1:N)
- `payments` → `invoices` (1:1)

**Políticas:**
- NO soft delete (tax audit)
- A payment can have only one invoice
- User can re-download invoice indefinitely

---

### 10. payment_retries

**Descripción:** Record of failed payment retries.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| `payment_id` | BIGINT UNSIGNED | NO | FK → payments.id |
| `attempt` | INT | NO | Retry number (1, 2, 3) |
| `tried_at` | TIMESTAMP | NO | Retry date and time |
| `result` | TEXT | SÍ | Retry result (success or failure reason) |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- CLAVE FORÁNEA: `payment_id` → `payments.id`
- ÍNDICE: `payment_id`, `tried_at`

**Relaciones:**
- `payments` → `payment_retries` (1:N)

**Políticas:**
- SIN borrado suave (auditoría)
- Maximum 3 attempts per payment
- Each retry is scheduled according to configured days

---

### 11. grace_periods

**Descripción:** Períodos de gracia otorgados por fallos de pago.

**NOTE:** The grace period duration (field `ends_at`) is calculated using:
1. `subscriptions.grace_period_months` if it exists
2. Global configuration `config('subscriptions.grace_period.months')` if NULL

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| `subscription_id` | BIGINT UNSIGNED | NO | FK → subscriptions.id |
| `started_at` | DATE | NO | Fecha de inicio del período de gracia |
| `ends_at` | DATE | NO | Fecha de fin del período de gracia (meses personalizables) |
| `months_owed` | INT | NO | Meses adeudados |
| `amount_owed` | DECIMAL(10,2) | NO | Monto total adeudado |
| `notifications_sent` | INT | NO | Número de notificaciones enviadas |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- CLAVE FORÁNEA: `subscription_id` → `subscriptions.id`
- ÍNDICE: `subscription_id`, `ends_at`

**Relaciones:**
- `subscriptions` → `grace_periods` (1:N, but ideally 1:1 active)

**Políticas:**
- SIN borrado suave (auditoría)
- Duración personalizable: Usa `subscriptions.grace_period_months` o config global (por defecto 2 meses)
- Recordatorios cada 15 días (configurable)
- El suscriptor mantiene acceso completo durante el período de gracia

---

### 12. notifications **[CORE - Polimórfico]**

**Descripción:** Log of all notifications sent (20+ tipos).

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`notifiable_type`** 🆕 | **VARCHAR(255)** | **NO** | **Notifiable polymorphic model class** |
| **`notifiable_id`** 🆕 | **BIGINT UNSIGNED** | **NO** | **Notifiable polymorphic model ID** |
| `type` | VARCHAR(100) | NO | tipo de notificación (20+ tipos) |
| `sent_at` | TIMESTAMP | SÍ | Send date and time |
| `status` | ENUM | NO | pending, sent, failed, bounced |
| `metadata` | JSON | SÍ | Datos adicionales de notificación |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- **ÍNDICE: `notifiable_type`, `notifiable_id`** 🆕
- ÍNDICE: `type`, `status`, `sent_at`

**Relaciones:**
- **Subscriber (polymorphic)** → `notifications` (1:N)

**Políticas:**
- SIN borrado suave (auditoría)
- Allows manual resend if failed
- Complete tracking for metrics

**tipo de notificaciones (20+):**
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

### 13. audit_logs **[CORE - Polimórfico]**

**Descripción:** Audit log of all critical actions.

| Campo | Tipo | Null | Descripción |
|-------|------|------|-------------|
| `id` | BIGINT UNSIGNED | NO | Clave primaria, Auto-incremento |
| **`auditable_type`** 🆕 | **VARCHAR(255)** | **YES** | **Auditable polymorphic model class (NULL for system)** |
| **`auditable_id`** 🆕 | **BIGINT UNSIGNED** | **YES** | **Auditable polymorphic model ID (NULL for system)** |
| `action` | VARCHAR(100) | NO | Acción realizada (create, update, delete, etc.) |
| `entity` | VARCHAR(100) | NO | Affected entity (subscription, payment, etc.) |
| `entity_id` | BIGINT UNSIGNED | NO | Affected record ID |
| `before` | JSON | SÍ | Estado antes del cambio |
| `after` | JSON | SÍ | Estado después del cambio |
| `ip` | VARCHAR(45) | SÍ | IP from which action was performed |
| `created_at` | TIMESTAMP | SÍ | Fecha de creación |
| `updated_at` | TIMESTAMP | SÍ | Fecha de última actualización |

**Índices:**
- CLAVE PRIMARIA: `id`
- **ÍNDICE: `auditable_type`, `auditable_id`** 🆕
- ÍNDICE: `entity`, `entity_id`, `created_at`

**Relaciones:**
- **Subscriber (polymorphic)** → `audit_logs` (1:N)

**Políticas:**
- NO soft delete (permanent audit)
- Immutable (INSERT only)
- Retention: indefinite or according to compliance policies

---

## Relaciones

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

### Relaciones Polimórficas Explanation

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

## Índices Recomendados

### Critical Performance Indexes

**Frequent queries:**

```sql
-- Get subscriptions to renew today
SELECT * FROM subscriptions 
WHERE next_billing_date <= CURDATE() 
AND status = 'active';
-- ÍNDICE: (next_billing_date, status)

-- Get payments requiring 3DS without notification
SELECT * FROM payments 
WHERE requires_3ds = true 
AND authentication_required_notified_at IS NULL;
-- ÍNDICE: (requires_3ds, authentication_required_notified_at)

-- Get subscriber's current tokens
SELECT * FROM tokens_usage 
WHERE subscriber_type = ? AND subscriber_id = ?
ORDER BY period_start DESC 
LIMIT 1;
-- ÍNDICE: (subscriber_type, subscriber_id, period_start)

-- Validate coupon
SELECT * FROM coupons 
WHERE code = ?  
AND active = true 
AND (expires_at IS NULL OR expires_at >= CURDATE());
-- ÍNDICE: (code, active, expires_at)
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

## Políticas de Eliminación

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

## Resumen de Cambios de 3DS y Polimórficos

### Tables Modified for Polymorphic Relationships

**1. subscriptions:**
- ✅ `subscriber_type` (VARCHAR 255) - Clase del modelo polimórfico
- ✅ `subscriber_id` (BIGINT UNSIGNED) - ID del modelo polimórfico
- ✅ Clave foránea eliminada

**2. tokens_usage:**
- ✅ `subscriber_type` (VARCHAR 255)
- ✅ `subscriber_id` (BIGINT UNSIGNED)
- ✅ Clave foránea eliminada

**3. subscriber_coupons (renamed from user_coupons):**
- ✅ `subscriber_type` (VARCHAR 255)
- ✅ `subscriber_id` (BIGINT UNSIGNED)
- ✅ Clave foránea eliminada
- ✅ Tabla renombrada

**4. referrals:**
- ✅ `referrer_type` (VARCHAR 255)
- ✅ `referrer_id` (BIGINT UNSIGNED)
- ✅ `referred_type` (VARCHAR 255)
- ✅ `referred_id` (BIGINT UNSIGNED)
- ✅ Clave foránea eliminadas a users

**5. billing_data:**
- ✅ `billable_type` (VARCHAR 255)
- ✅ `billable_id` (BIGINT UNSIGNED)
- ✅ Clave foránea eliminada

**6. invoices:**
- ✅ `invoiceable_type` (VARCHAR 255)
- ✅ `invoiceable_id` (BIGINT UNSIGNED)
- ✅ Clave foránea eliminada

**7. notifications:**
- ✅ `notifiable_type` (VARCHAR 255)
- ✅ `notifiable_id` (BIGINT UNSIGNED)
- ✅ Clave foránea eliminada

**8. audit_logs:**
- ✅ `auditable_type` (VARCHAR 255, nullable)
- ✅ `auditable_id` (BIGINT UNSIGNED, nullable)
- ✅ Clave foránea eliminada

### Tablas Modificadas para 3DS

**1. subscriptions:**
- ✅ `mit_enabled` (BOOLEAN)
- ✅ `first_payment_3ds_completed` (BOOLEAN)

**2. payments:**
- ✅ `requires_3ds` (BOOLEAN)
- ✅ `three_ds_status` (ENUM)
- ✅ `three_ds_redirect_url` (VARCHAR 500)
- ✅ `three_ds_version` (VARCHAR 10)
- ✅ `authentication_required_notified_at` (TIMESTAMP)
- ✅ ENUM status actualizado: `requires_3ds`, `authenticating`, `authenticated`

**3. notifications:**
- ✅ Nuevo tipo: `payment_authentication_required`

### Nuevos Índices para Relaciones Polimórficas

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

## 📚 Referencias

- [DATABASE_DDL.sql](./DATABASE_DDL.sql) - Scripts SQL completos
- [3DS Integration](./3DS_INTEGRATION.md) - Detalles de integración 3DS
- [API Webhooks](./API_WEBHOOKS.md) - Webhooks que afectan estas tablas
- [Polymorphic Relationships](./POLYMORPHIC_RELATIONSHIPS.md) - Guía de uso

---

**Version:** 2.0  
**Changes:**
- ✅ Tabla users eliminada - el paquete usa relaciones polimórficas
- ✅ Todas las claves foráneas a users convertidas a polimórficas (subscriber_type/subscriber_id, etc.)
- ✅ Renombrado user_coupons a subscriber_coupons
- ✅ Agregado billable_type/billable_id a billing_data
- ✅ Agregado referrer_type/referrer_id y referred_type/referred_id a referrals
- ✅ Agregado notifiable_type/notifiable_id a notifications
- ✅ Agregado invoiceable_type/invoiceable_id a invoices
- ✅ Agregado auditable_type/auditable_id a audit_logs
- ✅ Módulos opcionales marcados: tokens_usage, referrals, invoices
- ✅ Módulos core marcados: subscriptions, payments, coupons, subscriber_coupons
- ✅ Actualizados todos los índices para relaciones polimórficas
- ✅ Agregados campos 3DS en payments y subscriptions
- ✅ Agregado tipo de notificación `payment_authentication_required`
- ✅ Agregados campos de períodos personalizables: trial_days, trial_ends_at, grace_period_months en subscriptions
- ✅ Documentación completa para cada tabla

---

**End of Document**