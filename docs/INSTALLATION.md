# Guía de Instalación
## Paquete Gestor de Suscripciones Laravel

**Versión:** 2.0  
**Fecha:** Enero 2026

---

## 📑 Tabla de Contenidos

1. [Requisitos](#requisitos)
2. [Instalación vía Composer](#instalación-vía-composer)
3. [Configuración](#configuración)
4. [Configuración de Base de Datos](#configuración-de-base-de-datos)
5. [Configuración del Modelo](#configuración-del-modelo)
6. [Configuración de Pasarela de Pagos](#configuración-de-pasarela-de-pagos)
7. [Configuración de Colas](#configuración-de-colas)
8. [Verificación](#verificación)

---

## Requisitos

### Requisitos del Sistema

- **PHP:** 8.1 o superior
- **Laravel:** 10.x o 11.x
- **Base de Datos:** MySQL 8.0+ / PostgreSQL 13+ / MariaDB 10.5+
- **Extensiones PHP:**
  - PDO
  - Mbstring
  - JSON
  - OpenSSL
  - BCMath (recomendado para cálculos de moneda)

### Recomendado

- **Redis:** Para colas y caché (opcional pero recomendado)
- **Supervisor:** Para workers de cola en producción
- **Composer:** 2.x

---

## Instalación vía Composer

### Paso 1: Instalar el Paquete

```bash
composer require cesarantolinez/laravel-subscription-manager
```

### Paso 2: Publicar Archivos de Configuración

Publicar el archivo de configuración del paquete:

```bash
php artisan vendor:publish --tag=subscription-config
```

Esto crea `config/subscription.php` con la configuración predeterminada.

### Paso 3: Publicar Migraciones

Publicar las migraciones de base de datos:

```bash
php artisan vendor:publish --tag=subscription-migrations
```

**Migraciones de Módulos Opcionales:**

Si deseas usar características opcionales, publica sus migraciones:

```bash
# Publicar migración del módulo de tokens
php artisan vendor:publish --tag=subscription-migrations-tokens

# Publicar migración del módulo de referidos
php artisan vendor:publish --tag=subscription-migrations-referrals

# Publicar migración del módulo de facturación
php artisan vendor:publish --tag=subscription-migrations-invoicing
```

### Paso 4: Publicar Vistas (Opcional)

Si deseas personalizar las plantillas de correo de notificaciones:

```bash
php artisan vendor:publish --tag=subscription-views
```

### Paso 5: Publicar Traducciones (Opcional)

Si deseas personalizar los mensajes de notificaciones:

```bash
php artisan vendor:publish --tag=subscription-lang
```

---

## Configuración

### Paso 1: Configurar Variables de Entorno

Agrega lo siguiente a tu archivo `.env`:

```env
# ============================================================================
# Configuración del Paquete de Suscripciones
# ============================================================================

# Modelo Suscriptor (el modelo que tendrá suscripciones)
SUBSCRIPTION_SUBSCRIBER_MODEL=App\\Models\\User

# Pasarela de Pagos
PAYMENT_GATEWAY=openpay

# Configuración de Openpay (si usas Openpay)
OPENPAY_MERCHANT_ID=your-merchant-id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
OPENPAY_SANDBOX_MODE=true
OPENPAY_COUNTRY=MX  # MX or CO

# Configuración de Stripe (si usas Stripe)
STRIPE_KEY=pk_test_your_key
STRIPE_SECRET=sk_test_your_secret
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Características Opcionales
SUBSCRIPTION_TOKENS_ENABLED=true
SUBSCRIPTION_REFERRALS_ENABLED=true
SUBSCRIPTION_INVOICING_ENABLED=false

# Configuración de Prueba
SUBSCRIPTION_DEFAULT_TRIAL_DAYS=14

# Configuración de Período de Gracia
SUBSCRIPTION_GRACE_PERIOD_MONTHS=2

# Configuración de Reintentos de Pago
SUBSCRIPTION_MAX_PAYMENT_RETRIES=3
SUBSCRIPTION_RETRY_DAYS=3,7,14  # Días entre reintentos

# Configuración de Notificaciones
SUBSCRIPTION_NOTIFICATIONS_ENABLED=true
SUBSCRIPTION_NOTIFICATION_FROM_ADDRESS=noreply@example.com
SUBSCRIPTION_NOTIFICATION_FROM_NAME="Subscription Service"
```

### Paso 2: Configurar Modelo Suscriptor

En tu `config/subscription.php`, verifica el modelo suscriptor:

```php
'subscriber_model' => env('SUBSCRIPTION_SUBSCRIBER_MODEL', 'App\\Models\\User'),
```

---

## Configuración de Base de Datos

### Paso 1: Revisar Migraciones

Antes de ejecutar las migraciones, revisa los archivos de migración publicados en `database/migrations/`:

- Migraciones principales (siempre se ejecutan):
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

- Migraciones opcionales (solo si las características están habilitadas):
  - `xxxx_xx_xx_create_tokens_usage_table.php`
  - `xxxx_xx_xx_create_referrals_table.php`
  - `xxxx_xx_xx_create_invoices_table.php`

### Paso 2: Ejecutar Migraciones

```bash
php artisan migrate
```

Esto creará todas las tablas necesarias en tu base de datos.

### Paso 3: Poblar Planes de Ejemplo (Opcional)

Crear un seeder para tus planes de suscripción:

```bash
php artisan make:seeder SubscriptionPlanSeeder
```

Contenido de ejemplo del seeder:

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
                'description' => 'Perfecto para individuos y equipos pequeños',
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
                'description' => 'Para negocios en crecimiento',
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
                'description' => 'Para grandes organizaciones',
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

Ejecutar el seeder:

```bash
php artisan db:seed --class=SubscriptionPlanSeeder
```

---

## Configuración del Modelo

### Paso 1: Agregar Trait a tu Modelo Suscriptor

Agrega el trait `HasSubscription` a cualquier modelo que desees hacer suscribible.

**Ejemplo: Modelo User**

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class User extends Authenticatable
{
    use HasSubscription;

    // ... resto de tu modelo
}
```

**Ejemplo: Modelo Company**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class Company extends Model
{
    use HasSubscription;

    // ... resto de tu modelo
}
```

**Ejemplo: Modelo Team**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class Team extends Model
{
    use HasSubscription;

    // ... resto de tu modelo
}
```

### Paso 2: Verificar Métodos del Trait

El trait `HasSubscription` proporciona los siguientes métodos:

```php
// Suscribirse a un plan
$user->subscribeToPlan($plan, $periodicity, $cardToken);

// Obtener suscripción activa
$subscription = $user->activeSubscription();

// Verificar estado de suscripción
$user->hasActiveSubscription();
$user->isOnTrial();
$user->isOnGracePeriod();

// Cancelar suscripción
$user->cancelSubscription();

// Obtener historial de suscripciones
$subscriptions = $user->subscriptions;

// Obtener datos de facturación
$billingData = $user->billingData;

// Aplicar cupón
$user->applyCoupon($coupon);

// Obtener notificaciones
$notifications = $user->subscriptionNotifications;
```

---

## Configuración de Pasarela de Pagos

### Configuración de Openpay

#### Paso 1: Crear Cuenta de Openpay

1. Ve a [Openpay](https://www.openpay.mx/) (México) o [Openpay Colombia](https://www.openpay.co/)
2. Crea una cuenta de comerciante
3. Obtén tus credenciales:
   - Merchant ID
   - Private Key
   - Public Key

#### Paso 2: Configurar Openpay

Actualiza tu `.env`:

```env
PAYMENT_GATEWAY=openpay
OPENPAY_MERCHANT_ID=your_merchant_id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
OPENPAY_SANDBOX_MODE=true  # Establecer en false en producción
OPENPAY_COUNTRY=MX  # o CO
```

#### Paso 3: Configurar Webhooks

Configurar webhooks en tu panel de Openpay:

**URL del Webhook:**
```
https://yourdomain.com/api/subscriptions/webhooks/openpay
```

**Eventos a suscribir:**
- `charge.succeeded`
- `charge.failed`
- `charge.refunded`
- `charge.cancelled`

### Configuración de Stripe (Alternativa)

#### Paso 1: Crear Cuenta de Stripe

1. Ve a [Stripe](https://stripe.com/)
2. Crea una cuenta
3. Obtén las claves API desde el Dashboard

#### Paso 2: Configurar Stripe

Actualiza tu `.env`:

```env
PAYMENT_GATEWAY=stripe
STRIPE_KEY=pk_test_your_key
STRIPE_SECRET=sk_test_your_secret
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

#### Paso 3: Configurar Webhooks

Configurar webhooks en el panel de Stripe:

**URL del Webhook:**
```
https://yourdomain.com/api/subscriptions/webhooks/stripe
```

---

## Configuración de Colas

### Paso 1: Configurar Driver de Colas

El paquete utiliza colas para procesamiento en segundo plano. Configura tu driver de colas en `.env`:

```env
QUEUE_CONNECTION=redis  # o database, sqs, etc.
```

### Paso 2: Iniciar Worker de Colas

Para desarrollo:

```bash
php artisan queue:work
```

Para producción, usa Supervisor:

**Crear configuración de supervisor** (`/etc/supervisor/conf.d/laravel-worker.conf`):

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

Recargar Supervisor:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-worker:*
```

---

## Verificación

### Paso 1: Verificar Instalación

Ejecutar el comando de verificación del paquete:

```bash
php artisan subscription:verify
```

Esto verificará:
- ✅ El archivo de configuración existe
- ✅ Las migraciones se ejecutaron exitosamente
- ✅ El modelo suscriptor existe y usa el trait
- ✅ La pasarela de pagos está configurada
- ✅ Las colas están configuradas

### Paso 2: Probar Creación de Suscripción

Probar la creación de una suscripción en `tinker`:

```bash
php artisan tinker
```

```php
// Obtener un usuario y un plan
$user = App\Models\User::first();
$plan = DB::table('plans')->first();

// Suscribir
$subscription = $user->subscribeToPlan($plan);

// Verificar
$user->hasActiveSubscription(); // debería retornar true
```

### Paso 3: Verificar Endpoint del Webhook

Probar que tu endpoint de webhook es accesible:

```bash
curl -X POST https://yourdomain.com/api/subscriptions/webhooks/openpay \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

Debería retornar una respuesta (puede ser un error si la firma es inválida, pero el endpoint debería ser alcanzable).

---

## Solución de Problemas

### Problemas Comunes

**Problema: Las migraciones fallan**
```
Solución: Asegúrate de que tu conexión a la base de datos esté configurada correctamente en .env
Verificar: php artisan migrate:status
```

**Problema: Trait no encontrado**
```
Solución: Ejecuta composer dump-autoload
Comando: composer dump-autoload
```

**Problema: Los trabajos de cola no se procesan**
```
Solución: Asegúrate de que el worker de colas esté ejecutándose
Verificar: ps aux | grep "queue:work"
Iniciar: php artisan queue:work
```

**Problema: Los webhooks no reciben eventos**
```
Solución: 
1. Verifica que la URL del webhook sea accesible públicamente
2. Verifica la validación de firma del webhook
3. Revisa los logs: storage/logs/laravel.log
```

---

## Próximos Pasos

Después de una instalación exitosa:

1. **Configuración:** Ver [CONFIGURATION.md](./CONFIGURATION.md) para opciones de configuración detalladas
2. **Uso:** Ver [POLYMORPHIC_RELATIONSHIPS.md](./POLYMORPHIC_RELATIONSHIPS.md) para ejemplos de uso
3. **Extensión:** Ver [EXTENDING.md](./EXTENDING.md) para opciones de personalización
4. **Base de Datos:** Ver [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) para detalles de la base de datos

---

## Soporte

**Documentación:** https://github.com/CesarAntolinez/laravel-subscription-manager/docs  
**Problemas:** https://github.com/CesarAntolinez/laravel-subscription-manager/issues  
**Discusiones:** https://github.com/CesarAntolinez/laravel-subscription-manager/discussions

---

**Versión:** 2.0  
**Última Actualización:** Enero 2026

---

**Fin del Documento**
