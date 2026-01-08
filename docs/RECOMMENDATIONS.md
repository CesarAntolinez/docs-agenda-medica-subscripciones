# 🎯 Recomendaciones Técnicas
## Sistema de Planes y Suscripciones

---

## 📑 Tabla de Contenidos

1. [Infraestructura](#infraestructura)
2. [Base de Datos](#base-de-datos)
3. [Laravel Best Practices](#laravel-best-practices)
4. [Seguridad](#seguridad)
5. [Testing](#testing)
6. [Monitoreo](#monitoreo)
7. [Openpay](#openpay)
8. [Emails](#emails)
9. [Datos y Privacidad](#datos-y-privacidad)
10. [Performance](#performance)
11. [Desarrollo](#desarrollo)
12. [Escalabilidad Futura](#escalabilidad-futura)

---

## Infraestructura

### ⚠️ CRÍTICO: Migración a VPS/Cloud

**Problema:** Hosting compartido NO soportará 10,000+ usuarios

**Solución Recomendada:**
- **Proveedor:** DigitalOcean, AWS Lightsail, o Vultr
- **Especificaciones Mínimas:**
  - 4 CPU cores
  - 8 GB RAM
  - 100 GB SSD
  - Bandwidth ilimitado o > 5TB/mes

**Costo Estimado:** $20-40 USD/mes

**Beneficios:**
- Control total del servidor
- Instalación de Redis, Supervisor
- Múltiples queue workers
- Mejor performance y escalabilidad

---

### Separación de Instancias

✅ **Mantener instancias separadas MX/CO:**
- Base de datos independiente por país
- Código base compartido, configuración por ambiente
- Cumplimiento con regulaciones locales
- Facilita troubleshooting específico

---

### CDN

**Implementar CloudFlare:**
- Plan gratuito suficiente para inicio
- Reducir carga del servidor (assets estáticos)
- Protección DDoS
- Cache automático
- HTTPS gratuito

**Configuración:**
```bash
# Configurar DNS en CloudFlare
# Habilitar modo "Proxied" (nube naranja)
# Configurar Page Rules para cache agresivo en /css/, /js/, /img/
```

---

## Base de Datos

### Índices Estratégicos

✅ **Siempre indexar:**
- Columnas en WHERE clauses
- Columnas en JOIN conditions
- Columnas en ORDER BY
- Foreign keys

**Ejemplo:**
```sql
-- Buscar suscripciones para renovar hoy
SELECT * FROM subscriptions 
WHERE next_billing_date = CURDATE() 
AND status = 'active';

-- Requiere:
CREATE INDEX idx_next_billing_status ON subscriptions(next_billing_date, status);
```

---

### Soft Deletes

✅ **Usar en tablas críticas:**
- `users` - mantener histórico
- `subscriptions` - auditoría

❌ **NO usar en:**
- Tablas de tracking (logs, notifications)
- Tablas transaccionales (payments - mejor marcar status)

---

### Backups

**Estrategia Recomendada:**
- **Diarios:** Backup completo automático (3 AM)
- **Incrementales:** Cada 6 horas
- **Retención:** 30 días local, 90 días offsite
- **Testing:** Restaurar backup mensualmente

**Herramientas:**
```bash
# mysqldump con cron
0 3 * * * mysqldump -u root -p dbname > /backups/db_$(date +\%Y\%m\%d).sql

# Alternativa: Laravel Backup
composer require spatie/laravel-backup
```

---

### Read Replicas (Futuro)

Para > 50,000 usuarios, considerar:
- Master para escrituras
- 1-2 replicas para lecturas (reportes, dashboards)
- Laravel soporta conexión múltiple out of the box

---

## Laravel Best Practices

### Versión

⚠️ **Laravel 8 ya NO tiene soporte LTS**

**Recomendaciones:**
1. **Corto plazo:** Iniciar con Laravel 8 si presión de tiempo
2. **Mediano plazo:** Migrar a Laravel 10 (LTS hasta Feb 2025)
3. **Largo plazo:** Laravel 11 (LTS hasta Feb 2026)

---

### Arquitectura

✅ **Implementar:**
- **Service Providers** para configuración modular
- **Form Requests** para validación
- **API Resources** para transformar responses
- **Events & Listeners** para desacoplamiento
- **Jobs** para operaciones asíncronas
- **Middleware** personalizado cuando sea necesario

**Estructura recomendada:**
```
app/
├── Http/
│   ├── Controllers/
│   ├── Middleware/
│   └── Requests/
├── Models/
├── Services/
├── Repositories/ (opcional)
├── Events/
├── Listeners/
└── Jobs/
```

---

### Jobs Asíncronos

✅ **Usar para:**
- Envío de emails
- Procesamiento de webhooks
- Renovaciones automáticas
- Generación de reportes
- Cualquier operación > 2 segundos

**Configuración:**
```php
// config/queue.php
'default' => env('QUEUE_CONNECTION', 'redis'),

'connections' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'default',
        'queue' => env('REDIS_QUEUE', 'default'),
        'retry_after' => 90,
    ],
],
```

**Supervisor config:**
```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=4
user=www-data
```

---

## Seguridad

### No Almacenar Tarjetas

✅ **NUNCA almacenar:**
- Número completo de tarjeta
- CVV
- Fecha de expiración

✅ **Solo almacenar:**
- Token de Openpay (encriptado)
- Últimos 4 dígitos (para mostrar al usuario)

---

### Encriptación

```php
// Model
use Illuminate\Database\Eloquent\Casts\Attribute;

protected function taxId(): Attribute
{
    return Attribute::make(
        get: fn ($value) => decrypt($value),
        set: fn ($value) => encrypt($value),
    );
}

// O con $casts
protected $casts = [
    'tax_id' => 'encrypted',
    'legal_name' => 'encrypted',
];
```

---

### Validación y Sanitización

✅ **Siempre:**
```php
// Form Request
public function rules()
{
    return [
        'email' => 'required|email|max:255|unique:users',
        'name' => 'required|string|max:255',
        'tax_id' => 'required|string|max:20|regex:/^[A-Z0-9]+$/',
    ];
}

protected function prepareForValidation()
{
    $this->merge([
        'email' => strtolower(trim($this->email)),
        'tax_id' => strtoupper(trim($this->tax_id)),
    ]);
}
```

---

### Rate Limiting

```php
// routes/api.php
Route::middleware('throttle:10,1')->group(function () {
    Route::post('/payment', [PaymentController::class, 'process']);
});

// Custom rate limiting
RateLimiter::for('api', function (Request $request) {
    return $request->user()
                ? Limit::perMinute(60)->by($request->user()->id)
                : Limit::perMinute(10)->by($request->ip());
});
```

---

### CORS

```php
// config/cors.php
'paths' => ['api/*'],
'allowed_methods' => ['*'],
'allowed_origins' => [env('FRONTEND_URL')],
'allowed_headers' => ['*'],
'exposed_headers' => [],
'max_age' => 0,
'supports_credentials' => true,
```

---

### Audit Logs

✅ **Loguear siempre:**
- Cambios en suscripciones
- Todos los pagos (éxito y fallo)
- Cambios de plan
- Descuentos aplicados
- Acciones de admin

**Observer pattern:**
```php
// App\Observers\SubscriptionObserver
public function updated(Subscription $subscription)
{
    AuditLog::create([
        'user_id' => auth()->id(),
        'action' => 'subscription.updated',
        'entity' => 'Subscription',
        'entity_id' => $subscription->id,
        'before' => $subscription->getOriginal(),
        'after' => $subscription->getAttributes(),
        'ip' => request()->ip(),
    ]);
}
```

---

### OWASP Top 10

✅ **Checklist de Seguridad:**
- [ ] SQL Injection: Usar Eloquent/Query Builder
- [ ] XSS: Blade auto-escapes, validar inputs
- [ ] CSRF: Token en todos los forms
- [ ] Autenticación rota: Laravel Auth + 2FA (fase 3)
- [ ] Acceso roto: Policies y Gates
- [ ] Configuración insegura: .env nunca en repo
- [ ] XXE: No parsear XML no confiable
- [ ] Deserialización insegura: Validar todos los JSON
- [ ] Componentes vulnerables: `composer audit`
- [ ] Logging insuficiente: Logs estructurados

---

## Testing

### Cobertura Mínima: 70%

**Prioridad en tests:**
1. **Unit Tests:** Lógica de negocio crítica
   - Cálculos de prorrata
   - Validaciones de cupones
   - Cálculos de descuentos
   - Lógica de tokens

2. **Feature Tests:** Flujos completos
   - Registro y trial
   - Proceso de pago
   - Renovación automática
   - Cambios de plan

3. **Browser Tests (Dusk):** UI crítica
   - Checkout completo
   - Gestión de suscripción
   - Aplicar cupón

---

### Ejemplos

```php
// tests/Unit/SubscriptionServiceTest.php
public function test_calculate_monthly_prorata()
{
    $subscription = Subscription::factory()->create([
        'plan_id' => 1, // $500/month
        'next_billing_date' => now()->addDays(15),
    ]);
    
    $newPlan = Plan::factory()->create(['price_mxn' => 1000]);
    
    $prorata = (new SubscriptionService)->calculateProrata($subscription, $newPlan);
    
    $this->assertEquals(750, $prorata); // $1000 - ($500 * 15/30)
}
```

```php
// tests/Feature/PaymentTest.php
public function test_successful_payment_activates_subscription()
{
    $user = User::factory()->create();
    $subscription = Subscription::factory()->trialing()->create(['user_id' => $user->id]);
    
    $response = $this->actingAs($user)
                     ->post('/api/payments', ['card_token' => 'tok_test']);
    
    $response->assertStatus(201);
    $this->assertEquals('active', $subscription->fresh()->status);
}
```

---

### Mocking Openpay

```php
// tests/TestCase.php
protected function mockOpenpaySuccess()
{
    $mock = Mockery::mock(OpenpayService::class);
    $mock->shouldReceive('createCharge')
         ->andReturn([
             'success' => true,
             'transaction_id' => 'tr_test_123',
         ]);
    
    $this->app->instance(OpenpayService::class, $mock);
}
```

---

## Monitoreo

### Laravel Telescope (Desarrollo)

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

**Usar para:**
- Debug de queries
- Requests HTTP
- Jobs ejecutados
- Mails enviados
- Exceptions

---

### Laravel Horizon (Producción)

```bash
composer require laravel/horizon
php artisan horizon:install
```

**Beneficios:**
- Dashboard de queues
- Métricas de jobs
- Reintentos automáticos
- Balance de carga

---

### Sentry (Error Tracking)

```bash
composer require sentry/sentry-laravel
```

**Configuración:**
```php
// config/sentry.php
'dsn' => env('SENTRY_LARAVEL_DSN'),
'environment' => env('APP_ENV'),
'sample_rate' => 1.0,
```

**Beneficios:**
- Tracking de errores en producción
- Stack traces detallados
- Alertas en Slack/Email
- Análisis de tendencias

---

### Logs Estructurados

```php
// Usar contexto en logs
Log::info('Payment processed', [
    'user_id' => $user->id,
    'subscription_id' => $subscription->id,
    'amount' => $payment->amount,
    'transaction_id' => $payment->openpay_transaction_id,
]);
```

---

### Métricas de Negocio

**Dashboard debe mostrar:**
- MRR (Monthly Recurring Revenue)
- ARR (Annual Recurring Revenue)
- Churn rate
- Tasa de conversión trial → pago
- CAC (Customer Acquisition Cost)
- LTV (Lifetime Value)
- ARPU (Average Revenue Per User)

---

## Openpay

### Ambientes

✅ **Sandbox para:**
- Desarrollo local
- Testing
- Staging

✅ **Producción solo cuando:**
- Testing completo en sandbox
- Validación de flujos
- Aprobación de negocio

---

### Webhooks

**Best Practices:**
1. **Validar firma HMAC siempre**
2. **Procesar asíncronamente (queue)**
3. **Idempotencia:** manejar duplicados
4. **Timeout rápido:** < 1 segundo
5. **Retornar 200 OK rápido**
6. **Loguear TODO**

```php
public function handle(Request $request)
{
    // Validar firma
    if (!$this->validateSignature($request)) {
        abort(401);
    }
    
    // Procesar async
    ProcessWebhookJob::dispatch($request->all());
    
    // Responder inmediato
    return response()->json(['status' => 'received'], 200);
}
```

---

### Timeouts

```php
// config/services.php
'openpay' => [
    'timeout' => 30, // segundos
    'retry' => 3,
],
```

---

### Logs de Transacciones

✅ **Loguear cada transacción:**
- Request completo a Openpay
- Response completo
- Timestamp
- Usuario asociado
- Resultado

---

## Emails

### Templates Responsive

✅ **Usar framework email:**
- MJML (recomendado)
- Foundation for Emails
- Templates de Laravel

**Ejemplo MJML:**
```html
<mjml>
  <mj-body>
    <mj-section>
      <mj-column>
        <mj-text>Hola {{ $user->name }}</mj-text>
        <mj-button href="{{ $actionUrl }}">
          Ver Detalle
        </mj-button>
      </mj-column>
    </mj-section>
  </mj-body>
</mjml>
```

---

### Queue

✅ **Siempre enviar emails async:**
```php
Mail::to($user)->queue(new PaymentConfirmationMail($payment));
```

---

### Rate Limiting

Evitar ser marcado como spam:
- Máximo 100 emails/hora por dominio
- Usar SMTP dedicado o servicio (SendGrid, Mailgun)
- SPF, DKIM, DMARC configurados

---

## Datos y Privacidad

### Política de Privacidad

✅ **Debe incluir:**
- Qué datos recolectamos
- Cómo los usamos
- Con quién los compartimos
- Cómo los protegemos
- Derechos del usuario
- Contacto

---

### Consentimiento

```php
// Registro
'terms_accepted' => 'required|accepted',
'privacy_accepted' => 'required|accepted',
```

---

### Derecho al Olvido

**Implementar endpoint:**
```php
// DELETE /api/account
public function destroy(Request $request)
{
    $user = $request->user();
    
    // Cancelar suscripción
    $user->subscription?->cancel();
    
    // Anonimizar o eliminar datos
    $user->delete(); // soft delete
    
    return response()->json(['message' => 'Cuenta eliminada']);
}
```

---

### Exportación de Datos

**GDPR-style:**
```php
// GET /api/account/export
public function export(Request $request)
{
    $user = $request->user();
    
    return response()->json([
        'user' => $user,
        'subscription' => $user->subscription,
        'payments' => $user->payments,
        'invoices' => $user->invoices,
        'tokens_usage' => $user->tokensUsage,
    ]);
}
```

---

### Retención de Datos

**Cumplir con:**
- México: 5 años (fiscal)
- Colombia: 5 años (fiscal)

**No retener más de lo necesario:**
- Logs de aplicación: 1 año
- Audit logs: 5 años
- Datos de usuario eliminado: anonimizar después de retención legal

---

## Performance

### Eager Loading

❌ **Evitar N+1:**
```php
// Malo
$subscriptions = Subscription::all();
foreach ($subscriptions as $sub) {
    echo $sub->user->name; // N+1 query
}

// Bueno
$subscriptions = Subscription::with('user')->all();
foreach ($subscriptions as $sub) {
    echo $sub->user->name; // 1 query
}
```

---

### Cache

```php
// Cache de planes activos (no cambian frecuentemente)
$plans = Cache::remember('plans.active', 3600, function () {
    return Plan::where('active', true)->get();
});

// Cache de configuración
$config = Cache::rememberForever('config.global', function () {
    return Config::all()->pluck('value', 'key');
});
```

---

### Lazy Loading / Paginación

```php
// Para listas largas
$payments = Payment::orderBy('created_at', 'desc')->paginate(50);

// Chunk para procesamiento masivo
Subscription::where('next_billing_date', today())
    ->chunk(100, function ($subscriptions) {
        foreach ($subscriptions as $subscription) {
            ProcessRenewal::dispatch($subscription);
        }
    });
```

---

### Minificación

```bash
# Laravel Mix
npm run production

# Resultado
public/css/app.css → public/css/app.min.css (comprimido + hash)
public/js/app.js → public/js/app.min.js (comprimido + hash)
```

---

### Gzip

**Nginx config:**
```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
gzip_min_length 1000;
```

---

### Query Optimization

**Usar EXPLAIN:**
```sql
EXPLAIN SELECT * FROM subscriptions 
WHERE next_billing_date = '2026-01-15' 
AND status = 'active';
```

**Añadir índices según resultado**

---

## Desarrollo

### Git Flow

✅ **Branches:**
- `main` - Producción
- `develop` - Desarrollo
- `feature/*` - Nuevas características
- `bugfix/*` - Correcciones
- `hotfix/*` - Urgentes en producción

---

### Code Reviews

✅ **Obligatorios para:**
- Merge a `main`
- Merge a `develop`
- Cambios en lógica de pago
- Cambios en seguridad

---

### CI/CD

**GitHub Actions ejemplo:**
```yaml
name: Laravel Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Dependencies
        run: composer install
      - name: Run Tests
        run: php artisan test
```

---

### Environments

- **Local:** Desarrollo individual
- **Development:** Integración continua
- **Staging:** Pre-producción (réplica de prod)
- **Production:** Ambiente live

---

### .env NUNCA en Repo

✅ **.gitignore:**
```
/.env
/.env.*
!/.env.example
```

---

### PHPDoc

```php
/**
 * Calcular prorrata para upgrade de plan
 *
 * @param Subscription $subscription Suscripción actual
 * @param Plan $newPlan Plan destino
 * @return float Monto a cobrar
 * @throws PaymentException
 */
public function calculateProrata(Subscription $subscription, Plan $newPlan): float
{
    // ...
}
```

---

## Escalabilidad Futura

### Microservicios

**Cuando > 100,000 usuarios, considerar:**
- Separar panel admin en microservicio
- Servicio independiente de facturación
- Servicio de notificaciones
- API Gateway (Kong, AWS API Gateway)

---

### Load Balancer

**Para alta disponibilidad:**
- 2+ app servers detrás de load balancer
- Session en Redis (stateless)
- Assets en CDN
- BD centralizada (o cluster)

---

### Database Sharding

**Particionar por país:**
- Shard MX: usuarios mexicanos
- Shard CO: usuarios colombianos
- Lógica de routing por `user.country`

---

### Message Queue

**RabbitMQ o Kafka para:**
- Alto volumen de jobs
- Comunicación entre microservicios
- Event sourcing

---

**Documento:** RECOMMENDATIONS v1.0  
**Fecha:** Enero 2026  
**Próxima Revisión:** Semestral

