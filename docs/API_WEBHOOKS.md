# 🔌 API y Webhooks
## Sistema de Planes y Suscripciones

---

## 📑 Tabla de Contenidos

1. [Introducción](#introducción)
2. [APIs REST - Endpoints](#apis-rest---endpoints)
3. [Webhooks de Openpay](#webhooks-de-openpay)
4. [Autenticación y Seguridad](#autenticación-y-seguridad)
5. [Códigos de Error](#códigos-de-error)
6. [Rate Limiting](#rate-limiting)

---

## Introducción

Este documento especifica las APIs REST y webhooks del sistema de suscripciones.

**Base URLs:**
- **México:** `https://mx.app.com/api/v1`
- **Colombia:** `https://co.app.com/api/v1`

**Formato:** JSON  
**Charset:** UTF-8  
**Autenticación:** Bearer Token (Laravel Sanctum)

---

## APIs REST - Endpoints

### Auth Module

#### POST /auth/register
Registrar nuevo usuario

**Request:**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!",
  "role": "profesional",
  "country": "MX"
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "role": "profesional",
      "country": "MX"
    },
    "token": "1|abcd1234..."
  },
  "message": "Usuario registrado exitosamente"
}
```

**Errors:** 422 (Validation), 409 (Email exists)

---

#### POST /auth/login
Autenticar usuario

**Request:**
```json
{
  "email": "juan@example.com",
  "password": "SecurePass123!"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "user": { /* user object */ },
    "token": "2|xyz789..."
  }
}
```

---

### Plans Module

#### GET /plans
Listar planes activos

**Query Parameters:**
- `periodicity` (optional): monthly, annual, annual_monthly_billing

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Google Tech + IA 50",
      "description": "Plan básico con 50 tokens mensuales",
      "tokens_monthly": 50,
      "periodicity": ["monthly", "annual"],
      "price_mxn": "500.00",
      "price_cop": "85000.00",
      "trial_days": 14,
      "active": true
    }
  ]
}
```

---

#### GET /plans/{id}
Obtener detalle de plan

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Google Tech + IA 50",
    /* plan details */
  }
}
```

**Errors:** 404 (Not found)

---

### Subscriptions Module

#### POST /subscriptions
Crear nueva suscripción

**Request:**
```json
{
  "plan_id": 1,
  "periodicity": "monthly",
  "card_token": "tok_xyz123",
  "billing_data": {
    "tax_id": "RFC123456ABC",
    "legal_name": "Juan Pérez",
    "tax_regime": "601",
    "postal_code": "01000",
    "cfdi_use": "G03"
  }
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": 1,
      "user_id": 1,
      "plan_id": 1,
      "status": "trialing",
      "starts_at": "2026-01-15T10:00:00Z",
      "next_billing_date": "2026-01-29T10:00:00Z"
    }
  },
  "message": "Suscripción creada. Trial activo por 14 días"
}
```

**Errors:** 400, 422

---

#### GET /subscriptions/current
Obtener suscripción actual del usuario autenticado

**Headers:** `Authorization: Bearer {token}`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": 1,
      "plan": { /* plan object */ },
      "status": "active",
      "next_billing_date": "2026-02-15T10:00:00Z",
      "tokens": {
        "used": 25,
        "total": 50,
        "percentage": 50
      }
    }
  }
}
```

**Errors:** 404 (No subscription)

---

#### PUT /subscriptions/{id}/upgrade
Upgrade de plan

**Request:**
```json
{
  "new_plan_id": 2
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "prorata": {
      "days_remaining": 15,
      "credit": "250.00",
      "new_price": "1000.00",
      "charge_now": "750.00"
    },
    "subscription": { /* updated subscription */ }
  },
  "message": "Upgrade procesado exitosamente"
}
```

**Errors:** 400 (Invalid upgrade), 402 (Payment failed)

---

#### PUT /subscriptions/{id}/downgrade
Downgrade de plan (programado)

**Request:**
```json
{
  "new_plan_id": 1
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "scheduled_change": {
      "current_plan_id": 2,
      "new_plan_id": 1,
      "effective_date": "2026-02-15T10:00:00Z"
    }
  },
  "message": "Downgrade programado para próxima renovación"
}
```

---

#### DELETE /subscriptions/{id}
Cancelar suscripción

**Response 200:**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "status": "cancelled",
      "ends_at": "2026-02-15T10:00:00Z"
    }
  },
  "message": "Suscripción cancelada. Acceso hasta 2026-02-15"
}
```

---

### Payments Module

#### GET /payments
Listar pagos del usuario

**Query Parameters:**
- `status`: successful, failed, pending
- `page`: número de página
- `per_page`: resultados por página (max 100)

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "amount": "500.00",
      "currency": "MXN",
      "method": "card",
      "status": "successful",
      "paid_at": "2026-01-15T10:00:00Z",
      "invoice": {
        "id": 1,
        "status": "sent",
        "file_url": "https://..."
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 10,
    "per_page": 15
  }
}
```

---

#### GET /payments/{id}
Detalle de pago

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "subscription_id": 1,
    "amount": "500.00",
    "currency": "MXN",
    "method": "card",
    "status": "successful",
    "openpay_transaction_id": "tr123xyz",
    "paid_at": "2026-01-15T10:00:00Z"
  }
}
```

---

### Tokens Module

#### GET /tokens/usage
Consumo de tokens actual

**Response 200:**
```json
{
  "success": true,
  "data": {
    "period_start": "2026-01-15",
    "period_end": "2026-02-14",
    "used": 25,
    "total": 50,
    "remaining": 25,
    "percentage_used": 50
  }
}
```

---

#### POST /tokens/consume
Consumir tokens

**Request:**
```json
{
  "amount": 5,
  "operation": "ai_generation",
  "metadata": {
    "request_id": "req_123"
  }
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "consumed": 5,
    "remaining": 20,
    "total": 50
  }
}
```

**Errors:** 400 (Insufficient tokens)

---

### Coupons Module

#### POST /coupons/validate
Validar cupón

**Request:**
```json
{
  "code": "PROMO20",
  "plan_id": 1
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "coupon": {
      "code": "PROMO20",
      "type": "percentage",
      "value": 20,
      "duration_months": 3
    },
    "discount": {
      "original_price": "500.00",
      "discount_amount": "100.00",
      "final_price": "400.00"
    }
  }
}
```

**Response 400 (Invalid):**
```json
{
  "success": false,
  "error": {
    "code": "COUPON_INVALID",
    "message": "Cupón no válido o expirado"
  }
}
```

---

### Invoices Module

#### POST /invoices
Solicitar factura

**Request:**
```json
{
  "payment_id": 1
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "invoice": {
      "id": 1,
      "payment_id": 1,
      "status": "pending",
      "requested_at": "2026-01-16T10:00:00Z"
    }
  },
  "message": "Solicitud de factura recibida"
}
```

**Errors:** 400 (Datos fiscales incompletos), 422 (Fuera de límite)

---

#### GET /invoices
Listar facturas

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "payment_id": 1,
      "status": "sent",
      "file_url": "https://storage.app.com/invoices/inv_001.pdf",
      "requested_at": "2026-01-16T10:00:00Z",
      "sent_at": "2026-01-17T15:00:00Z"
    }
  ]
}
```

---

#### GET /invoices/{id}/download
Descargar factura PDF

**Response:** Redirect to PDF URL or binary PDF

---

## Webhooks de Openpay

### Endpoint de Recepción

**URL:** `POST https://app.com/webhooks/openpay`

**Headers:**
- `Content-Type: application/json`
- `X-Openpay-Signature: {hmac_signature}`

### Eventos Soportados

#### 1. charge.succeeded

**Descripción:** Cargo exitoso

**Payload:**
```json
{
  "type": "charge.succeeded",
  "event_date": "2026-01-15T10:00:00Z",
  "transaction": {
    "id": "tr123xyz",
    "amount": 500.00,
    "currency": "MXN",
    "status": "completed",
    "customer_id": "cus_abc123",
    "order_id": "sub_1",
    "authorization": "801585",
    "method": "card",
    "card": {
      "type": "credit",
      "brand": "visa",
      "card_number": "411111XXXXXX1111"
    }
  }
}
```

**Acciones del Sistema:**
1. Buscar payment por transaction.id o order_id
2. Actualizar payment.status = "successful"
3. Actualizar payment.paid_at = event_date
4. Actualizar subscription según contexto (activar, renovar)
5. Resetear tokens si es renovación
6. Disparar evento PaymentSuccessful
7. Enviar email de confirmación
8. Crear solicitud de factura automática
9. Retornar HTTP 200

---

#### 2. charge.failed

**Descripción:** Cargo fallido

**Payload:**
```json
{
  "type": "charge.failed",
  "event_date": "2026-01-15T10:00:00Z",
  "transaction": {
    "id": "tr456xyz",
    "amount": 500.00,
    "currency": "MXN",
    "status": "failed",
    "customer_id": "cus_abc123",
    "order_id": "sub_1",
    "error_code": "3001",
    "error_message": "Tarjeta rechazada",
    "method": "card"
  }
}
```

**Acciones del Sistema:**
1. Buscar payment
2. Actualizar payment.status = "failed"
3. Incrementar payment.attempt
4. Crear registro en payment_retries
5. Si attempt < 3: Programar reintento
6. Si attempt = 3: Iniciar período de gracia
7. Disparar evento PaymentFailed
8. Enviar email notificando fallo
9. Retornar HTTP 200

---

#### 3. charge.refunded

**Descripción:** Cargo reembolsado

**Payload:**
```json
{
  "type": "charge.refunded",
  "event_date": "2026-01-16T10:00:00Z",
  "transaction": {
    "id": "tr123xyz",
    "amount": 500.00,
    "refund": {
      "id": "ref_789",
      "amount": 500.00,
      "description": "Reembolso solicitado por cliente"
    }
  }
}
```

**Acciones del Sistema:**
1. Buscar payment
2. Actualizar payment.status = "refunded"
3. Ajustar subscription si es necesario
4. Enviar email de confirmación de reembolso
5. Audit log
6. Retornar HTTP 200

---

### Seguridad de Webhooks

#### Validación de Firma HMAC

```php
// Ejemplo de validación en Laravel
public function handle(Request $request)
{
    $signature = $request->header('X-Openpay-Signature');
    $payload = $request->getContent();
    $secret = config('services.openpay.webhook_secret');
    
    $expected = hash_hmac('sha256', $payload, $secret);
    
    if (!hash_equals($expected, $signature)) {
        abort(401, 'Invalid signature');
    }
    
    // Procesar webhook...
}
```

#### Validación de IP

**IPs Autorizadas de Openpay:**
- México: 54.88.51.5, 52.23.114.12
- Colombia: (consultar documentación Openpay CO)

```php
$allowedIPs = ['54.88.51.5', '52.23.114.12'];
$requestIP = $request->ip();

if (!in_array($requestIP, $allowedIPs)) {
    abort(403, 'Unauthorized IP');
}
```

#### Timeout y Reintentos

**Configuración Openpay:**
- Timeout: 10 segundos
- Reintentos: hasta 10 veces
- Intervalo exponencial: 1min, 5min, 30min, 1h, 6h, 12h, 24h

**Best Practice:**
- Procesar webhook asíncronamente (queue)
- Retornar HTTP 200 rápidamente (< 1 segundo)
- Idempotencia: manejar webhooks duplicados

---

#### Logs de Webhooks

Registrar todos los webhooks recibidos:

```php
DB::table('webhook_logs')->insert([
    'type' => $event['type'],
    'payload' => json_encode($event),
    'signature' => $signature,
    'ip' => $request->ip(),
    'processed' => true,
    'created_at' => now(),
]);
```

---

## Autenticación y Seguridad

### Bearer Token (Laravel Sanctum)

**Obtención del Token:**
- Llamar a `/auth/login` o `/auth/register`
- Recibir token en respuesta
- Usar en header de requests subsecuentes

**Uso:**
```
Authorization: Bearer 1|abcd1234efgh5678...
```

### CSRF Protection

Para requests desde frontend web:
```javascript
// Laravel automáticamente verifica CSRF token
// Incluir en meta tag:
<meta name="csrf-token" content="{{ csrf_token() }}">

// En requests AJAX:
headers: {
    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
}
```

---

## Códigos de Error

| Código | Significado | Descripción |
|--------|-------------|-------------|
| **200** | OK | Request exitoso |
| **201** | Created | Recurso creado exitosamente |
| **400** | Bad Request | Request inválido |
| **401** | Unauthorized | No autenticado |
| **403** | Forbidden | No autorizado |
| **404** | Not Found | Recurso no encontrado |
| **422** | Unprocessable Entity | Validación fallida |
| **429** | Too Many Requests | Rate limit excedido |
| **500** | Internal Server Error | Error del servidor |
| **503** | Service Unavailable | Servicio temporalmente no disponible |

### Formato de Error

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Los datos proporcionados son inválidos",
    "errors": {
      "email": ["El email ya está en uso"],
      "password": ["La contraseña debe tener al menos 8 caracteres"]
    }
  }
}
```

---

## Rate Limiting

### Límites por Endpoint

| Endpoint | Límite | Ventana |
|----------|--------|---------|
| `/auth/login` | 5 requests | 1 minuto |
| `/auth/register` | 3 requests | 5 minutos |
| `/payments/*` | 10 requests | 1 minuto |
| API General | 60 requests | 1 minuto |
| Webhooks | Sin límite | - |

### Headers de Rate Limit

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1642253400
```

### Respuesta al Exceder Límite

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Demasiados requests. Intenta nuevamente en 60 segundos",
    "retry_after": 60
  }
}
```

---

**Documento:** API_WEBHOOKS v1.0  
**Fecha:** Enero 2026  
**Próxima Revisión:** Post MVP
