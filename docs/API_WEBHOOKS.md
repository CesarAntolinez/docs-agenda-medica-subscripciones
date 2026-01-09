# API Endpoints y Webhooks
## Sistema de Suscripciones - Agenda Médica SaaS

**Versión:** 1.1  
**Fecha:** Enero 2026  
**Actualización:** Endpoints y Webhooks 3D Secure (3DS)

---

## 📑 Tabla de Contenidos

1. [Autenticación](#autenticación)
2. [API Endpoints](#api-endpoints)
3. [Webhooks de Openpay](#webhooks-de-openpay)
4. [Webhooks Bancarios](#webhooks-bancarios)
5. [Códigos de Error](#códigos-de-error)
6. [Ejemplos de Uso](#ejemplos-de-uso)
7. [Testing](#testing)

---

## Autenticación

### API del Sistema

**Base URL:**
- Producción: `https://api.plataforma.com/v1`
- Staging: `https://api-staging.plataforma.com/v1`
- Desarrollo: `http://localhost:8000/api/v1`

**Método de Autenticación:**
- **Laravel Sanctum** (SPA Authentication)
- Cookie-based para frontend
- Token-based para integraciones externas

**Headers Requeridos:**
```
Content-Type: application/json
Accept: application/json
X-Requested-With: XMLHttpRequest
Authorization: Bearer {token}  // Solo para API tokens
```

**Obtener Token (Login):**
```http
POST /api/v1/auth/login
Content-Type:  application/json

{
  "email": "usuario@email.com",
  "password":  "password123"
}

Response 200:
{
  "user": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "usuario@email.com",
    "role": "profesional"
  },
  "token": "1|abc123xyz..." // Solo si device_name se proporciona
}
```

---

## API Endpoints

### 1. Suscripciones

#### 1.1 Obtener suscripción actual

```http
GET /api/v1/subscriptions/current
Authorization:  Bearer {token}

Response 200:
{
  "data": {
    "id": 123,
    "plan": {
      "id": 2,
      "name": "Google Tech + IA 100",
      "price_mxn": 499.00,
      "tokens_monthly": 10000
    },
    "status": "active",
    "periodicity": "monthly",
    "next_billing_date": "2026-02-15",
    "tokens":  {
      "used": 3500,
      "total": 10000,
      "available": 6500,
      "percentage": 35
    },
    "trial_ends_at": null,
    "mit_enabled": true,
    "first_payment_3ds_completed": true
  }
}
```

#### 1.2 Crear suscripción (Registro con Trial)

```http
POST /api/v1/subscriptions
Content-Type: application/json

{
  "plan_id": 2,
  "periodicity": "monthly",
  "token_id": "tok_abc123",  // Token de Openpay. js
  "device_session_id": "session_xyz",
  
  // NUEVO: Trial personalizado (opcional)
  "trial_days": 60,  // NULL = usar trial del plan
  
  // NUEVO: Grace period personalizado (opcional)
  "grace_period_months": 3,  // NULL = usar config global (2 meses)
  
  "billing_data": {
    "tax_id": "XAXX010101000",
    "legal_name": "Empresa SA de CV",
    "tax_regime": "612",
    "postal_code": "06600",
    "cfdi_use": "G03"
  }
}

Response 201:
{
  "data": {
    "id": 123,
    "status": "trial",
    "trial_days": 60,  // Personalizado
    "trial_ends_at": "2026-03-10",
    "grace_period_months": 3,  // Personalizado
    "payment":  {
      "id": 456,
      "status": "requires_3ds",  // 🔒 Requiere autenticación
      "requires_3ds": true,
      "three_ds_redirect_url": "https://sandbox-api.openpay.mx/v1/threed-secure/.. .",
      "three_ds_version": "2.0"
    }
  }
}

Response 422 (Validación):
{
  "message": "The given data was invalid.",
  "errors": {
    "plan_id": ["El plan seleccionado no existe"],
    "token_id": ["El token de tarjeta es requerido"]
  }
}
```

#### 1.3 Upgrade de Plan

```http
POST /api/v1/subscriptions/current/upgrade
Content-Type: application/json

{
  "plan_id": 3,
  "confirm_prorated_charge": true
}

Response 200:
{
  "data": {
    "id": 123,
    "plan_id": 3,
    "prorated_charge": {
      "amount": 266.67,
      "currency": "MXN",
      "payment_id": 457,
      "status": "completed"  // O "requires_3ds" si banco lo solicita
    }
  }
}

Response 402 (Requiere 3DS):
{
  "data": {
    "payment":  {
      "id": 457,
      "status": "requires_3ds",
      "three_ds_redirect_url": "https://...",
      "message": "Este pago requiere autenticación de tu banco"
    }
  }
}
```

#### 1.4 Downgrade de Plan (Programado)

```http
POST /api/v1/subscriptions/current/downgrade
Content-Type: application/json

{
  "plan_id": 1
}

Response 200:
{
  "data": {
    "id": 123,
    "current_plan_id": 2,
    "pending_plan_id": 1,
    "pending_plan_change_date": "2026-02-15",
    "message": "El cambio se aplicará el 15 de febrero"
  }
}
```

#### 1.5 Cancelar Suscripción

```http
DELETE /api/v1/subscriptions/current
Content-Type: application/json

{
  "reason": "too_expensive",  // opcional
  "feedback": "No uso todas las funcionalidades"  // opcional
}

Response 200:
{
  "data":  {
    "id": 123,
    "status": "cancelled",
    "ends_at": "2026-02-15",
    "message": "Tu suscripción se cancelará el 15 de febrero.  Mantendrás acceso hasta esa fecha."
  }
}
```

#### 🆕 1.6 Autenticar Pago Pendiente (3DS)

```http
POST /api/v1/payments/{payment_id}/retry-with-auth
Authorization: Bearer {token}

Response 200:
{
  "data": {
    "payment_id": 457,
    "status": "requires_3ds",
    "three_ds_redirect_url": "https://sandbox-api.openpay.mx/v1/threed-secure/...",
    "message": "Completa la autenticación en el modal"
  }
}

Response 403: 
{
  "message": "Este pago no te pertenece"
}

Response 404:
{
  "message":  "Pago no encontrado o ya fue completado"
}
```

#### 🆕 1.7 Verificar Estado de Pago 3DS

```http
GET /api/v1/payments/{payment_id}/status
Authorization: Bearer {token}

Response 200:
{
  "data": {
    "id": 457,
    "status": "completed",  // o "requires_3ds", "failed"
    "three_ds_status": "authenticated",
    "paid_at": "2026-01-15T10:35:00Z",
    "subscription_status": "active"
  }
}
```

---

### 2. Pagos

#### 2.1 Historial de Pagos

```http
GET /api/v1/payments? page=1&per_page=20
Authorization: Bearer {token}

Response 200:
{
  "data": [
    {
      "id": 456,
      "amount":  499.00,
      "currency":  "MXN",
      "method": "card",
      "status": "completed",
      "paid_at": "2026-01-15T10:30:00Z",
      "description": "Renovación - Google Tech + IA 100",
      "invoice_available": false,
      "requires_3ds": false,
      "three_ds_status": "authenticated"
    },
    {
      "id":  455,
      "amount": 1. 00,
      "currency": "MXN",
      "method":  "card",
      "status":  "completed",
      "paid_at": "2026-01-01T12:00:00Z",
      "description": "Validación tarjeta - Trial",
      "requires_3ds": true,
      "three_ds_status": "authenticated"
    }
  ],
  "meta": {
    "current_page": 1,
    "total":  5,
    "per_page": 20
  }
}
```

#### 2.2 Solicitar Orden de Pago Manual (Transferencia)

```http
POST /api/v1/payments/manual-order
Content-Type: application/json

{
  "plan_id": 2,
  "periodicity": "monthly"
}

Response 201:
{
  "data":  {
    "payment_id": 458,
    "reference": "REF-2026-0001-ABC123",
    "amount": 499.00,
    "currency": "MXN",
    "due_date": "2026-01-18",
    "bank_details": {
      "clabe": "012345678901234567",
      "bank":  "BBVA México",
      "beneficiary": "Empresa SA de CV"
    }
  }
}
```

---

### 3. Tokens

#### 3.1 Obtener Tokens Actuales

```http
GET /api/v1/tokens/current
Authorization: Bearer {token}

Response 200:
{
  "data": {
    "period_start": "2026-01-15",
    "period_end": "2026-02-14",
    "used": 3500,
    "total": 10000,
    "available": 6500,
    "percentage_used": 35,
    "alerts_sent": ["50%"]
  }
}
```

#### 3.2 Consumir Tokens (Interno - Usado por otros microservicios)

```http
POST /api/v1/tokens/consume
Content-Type: application/json
Authorization: Bearer {token}

{
  "amount": 100,
  "description": "Análisis de IA - Paciente 123"
}

Response 200:
{
  "data": {
    "used": 3600,
    "available": 6400,
    "transaction_id": "tkn_xyz"
  }
}

Response 403:
{
  "message": "Sin tokens disponibles",
  "available":  0,
  "upgrade_url": "/plans"
}
```

---

### 4. Cupones

#### 4.1 Validar Cupón

```http
POST /api/v1/coupons/validate
Content-Type: application/json

{
  "code": "PROMO2026",
  "plan_id": 2
}

Response 200:
{
  "data": {
    "code": "PROMO2026",
    "type": "percentage",
    "value": 20,
    "duration_months": 3,
    "applicable":  true,
    "discount_preview": {
      "original_price": 499.00,
      "discount_amount": 99.80,
      "final_price": 399.20,
      "currency": "MXN"
    }
  }
}

Response 422:
{
  "message": "Cupón no válido",
  "reason": "expired"  // o "not_found", "already_used", "not_applicable", "limit_reached"
}
```

#### 4.2 Aplicar Cupón

```http
POST /api/v1/subscriptions/current/apply-coupon
Content-Type: application/json

{
  "code": "PROMO2026"
}

Response 200:
{
  "data": {
    "coupon_applied": true,
    "new_price": 399.20,
    "discount_duration": "3 meses",
    "next_billing_amount": 399.20
  }
}
```

---

### 5. Referidos

#### 5.1 Obtener Código de Referido

```http
GET /api/v1/referrals/my-code
Authorization: Bearer {token}

Response 200:
{
  "data": {
    "code": "CESAR2026",
    "link": "https://app.com/register?ref=abc123xyz",
    "total_referrals": 5,
    "completed_referrals": 3,
    "pending_referrals": 2,
    "total_benefits": {
      "discounts": 3,
      "tokens": 3000,
      "credits": 300. 00
    }
  }
}
```

#### 5.2 Historial de Referidos

```http
GET /api/v1/referrals/history
Authorization: Bearer {token}

Response 200:
{
  "data": [
    {
      "id": 10,
      "referred_name": "María López",
      "status": "completed",
      "completed_at": "2026-01-10",
      "benefits_received": {
        "discount":  "20% por 1 mes",
        "tokens":  1000,
        "credit": 100.00
      }
    },
    {
      "id":  11,
      "referred_name": "Pedro García",
      "status": "pending",
      "registered_at": "2026-01-14",
      "trial_ends_at": "2026-01-28"
    }
  ]
}
```

---

### 6. Facturas

#### 6.1 Solicitar Factura

```http
POST /api/v1/invoices/request
Content-Type: application/json

{
  "payment_id": 456
}

Response 201:
{
  "data":  {
    "invoice_id": 789,
    "payment_id":  456,
    "status": "requested",
    "requested_at": "2026-01-16T09:00:00Z",
    "estimated_delivery": "24-48 horas",
    "message": "Tu solicitud fue recibida.  Te enviaremos la factura a tu email."
  }
}

Response 422:
{
  "message": "No se puede solicitar factura",
  "reason": "out_of_time",  // o "missing_billing_data", "already_requested"
  "details": "El límite para solicitar facturas es el mismo mes del pago (México)"
}
```

#### 6.2 Listar Facturas

```http
GET /api/v1/invoices
Authorization: Bearer {token}

Response 200:
{
  "data": [
    {
      "id": 789,
      "payment":  {
        "id": 456,
        "amount": 499.00,
        "date": "2026-01-15"
      },
      "status":  "completed",
      "file_url": "/storage/invoices/2026/01/invoice_789.pdf",
      "requested_at": "2026-01-16T09:00:00Z",
      "sent_at": "2026-01-17T14:30:00Z"
    }
  ]
}
```

#### 6.3 Descargar Factura

```http
GET /api/v1/invoices/{invoice_id}/download
Authorization:  Bearer {token}

Response 200:
Content-Type: application/pdf
Content-Disposition: attachment; filename="factura_789.pdf"

[Binary PDF data]
```

---

## Webhooks de Openpay

### Configuración

**Endpoint del Sistema:**
```
POST https://app.com/webhooks/openpay
```

**Configuración en Openpay Dashboard:**
1. Ingresar a Openpay Dashboard
2. Configuración → Webhooks
3. Agregar URL:   `https://app.com/webhooks/openpay`
4. Seleccionar eventos:  
   - `charge.succeeded`
   - `charge.failed`
   - `charge.cancelled`
   - `charge.refunded`
   - `charge.pending` (para 3DS)

**Validación de Firma HMAC:**

Openpay envía firma en header `X-Openpay-Signature`.

```php
// Backend validation
$signature = request()->header('X-Openpay-Signature');
$payload = request()->getContent();
$secretKey = config('openpay.webhook_secret');

$calculatedSignature = hash_hmac('sha256', $payload, $secretKey);

if (! hash_equals($signature, $calculatedSignature)) {
    abort(401, 'Invalid signature');
}
```

---

### 1. Webhook:  Pago Exitoso

**Evento:** `charge.succeeded`

**Request de Openpay:**
```http
POST https://app.com/webhooks/openpay
Content-Type: application/json
X-Openpay-Signature: hmac_signature_here

{
  "type": "charge.succeeded",
  "event_date": "2026-01-15T10:35:00Z",
  "transaction":  {
    "id": "tr4ns4ct10n1d",
    "amount": 499.00,
    "currency": "MXN",
    "status": "completed",
    "order_id": "payment_456",
    "description": "Renovación - Google Tech + IA 100",
    "customer_id": "cust_abc123",
    "method": "card",
    "card": {
      "type": "debit",
      "brand": "visa",
      "card_number": "************1234",
      "holder_name": "Juan Pérez"
    },
    "3d_secure": {
      "authenticated": true,
      "eci": "05",
      "cavv": "base64_encoded_value"
    },
    "authorization":  "801585",
    "creation_date": "2026-01-15T10:30:00Z",
    "operation_date": "2026-01-15T10:35:00Z"
  }
}
```

**Response del Sistema:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "processed",
  "payment_id": 456,
  "message": "Payment successfully processed"
}
```

**Acciones del Sistema:**
1. Validar firma HMAC
2. Buscar pago por `order_id` o `transaction. id`
3. Actualizar `payments.status = 'completed'`
4. Activar/renovar suscripción
5. Resetear tokens
6. Enviar email de confirmación
7. Marcar para facturación

---

### 2. Webhook: Pago Fallido

**Evento:** `charge.failed`

**Request de Openpay:**
```http
POST https://app.com/webhooks/openpay
Content-Type: application/json
X-Openpay-Signature:  hmac_signature_here

{
  "type": "charge. failed",
  "event_date": "2026-01-15T10:30:00Z",
  "transaction": {
    "id": "tr4ns4ct10n1d",
    "amount": 499.00,
    "currency": "MXN",
    "status": "failed",
    "order_id": "payment_456",
    "error_code": "1001",
    "description": "The card has insufficient funds",
    "category": "request",
    "3d_secure": {
      "authenticated": false,
      "reason": null
    }
  }
}
```

**Códigos de Error Comunes:**

| Código | Descripción | Acción Sistema |
|--------|-------------|----------------|
| `1001` | Fondos insuficientes | Programar reintento |
| `1005` | Tarjeta rechazada | Notificar usuario actualizar tarjeta |
| `1006` | Tarjeta expirada | Notificar usuario actualizar tarjeta |
| `1010` | Tarjeta bloqueada | Notificar contactar banco |
| `3001` | 3DS authentication failed | Ver flujo UC-021 |
| `3002` | 3DS authentication timeout | Ver flujo UC-021 |
| `3005` | 3DS technical error | Reintentar |

**Response del Sistema:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "processed",
  "payment_id":  456,
  "retry_scheduled": true,
  "retry_date": "2026-01-18"
}
```

---

### 🆕 3. Webhook: Pago Pendiente (Requiere 3DS)

**Evento:** `charge.pending`

**Request de Openpay:**
```http
POST https://app.com/webhooks/openpay
Content-Type: application/json
X-Openpay-Signature: hmac_signature_here

{
  "type": "charge.pending",
  "event_date": "2026-01-15T10:30:00Z",
  "transaction": {
    "id": "tr4ns4ct10n1d",
    "amount": 499.00,
    "currency": "MXN",
    "status": "charge_pending",
    "order_id": "payment_456",
    "payment_method": {
      "type": "redirect",
      "url": "https://sandbox-api.openpay.mx/v1/threed-secure/challenge/abc123",
      "requires_3d_secure": true
    },
    "3d_secure": {
      "version": "2.0",
      "challenge_required": true,
      "eci": null
    }
  }
}
```

**Response del Sistema:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "processed",
  "payment_id": 456,
  "requires_user_action": true,
  "message": "User will be notified to complete 3DS authentication"
}
```

**Acciones del Sistema:**
1. Validar firma HMAC
2. Actualizar `payments`:
   - `status = 'requires_3ds'`
   - `three_ds_status = 'pending'`
   - `three_ds_redirect_url` = URL del webhook
   - `three_ds_version = '2.0'`
3. SI es renovación automática: 
   - Enviar Email #20 (Autenticación requerida)
   - Marcar `authentication_required_notified_at`
4. SI es pago iniciado por usuario (upgrade, registro): 
   - Devolver URL en response de API
   - Frontend muestra modal 3DS

---

### 4. Webhook: Pago Reembolsado

**Evento:** `charge.refunded`

**Request de Openpay:**
```http
POST https://app.com/webhooks/openpay
Content-Type: application/json
X-Openpay-Signature: hmac_signature_here

{
  "type":  "charge.refunded",
  "event_date": "2026-01-20T15:00:00Z",
  "transaction": {
    "id": "tr4ns4ct10n1d",
    "amount": 499.00,
    "refund":  {
      "id": "rfnd_xyz",
      "amount": 499.00,
      "authorization": "801585",
      "creation_date": "2026-01-20T15:00:00Z",
      "description": "Solicitud del usuario"
    }
  }
}
```

**Response:**
```http
HTTP/1.1 200 OK

{
  "status": "processed",
  "payment_id":  456,
  "refund_id": "rfnd_xyz"
}
```

---

### Manejo de Reintentos de Webhooks

**Política de Openpay:**
- Si sistema responde 500 o timeout → Openpay reintenta
- Reintentos en:  10 min, 1h, 3h, 6h, 12h, 24h
- Máximo 10 intentos en 24 horas

**Implementación del Sistema:**
```php
// Idempotencia:  No procesar duplicados
public function handleWebhook(Request $request)
{
    $transactionId = $request->input('transaction. id');
    $eventType = $request->input('type');
    
    // Verificar si ya procesamos este webhook
    $alreadyProcessed = WebhookLog::where('transaction_id', $transactionId)
        ->where('event_type', $eventType)
        ->where('status', 'processed')
        ->exists();
    
    if ($alreadyProcessed) {
        Log::info('Webhook duplicado ignorado', ['transaction_id' => $transactionId]);
        return response()->json(['status' => 'already_processed'], 200);
    }
    
    // Procesar webhook... 
    
    // Registrar que fue procesado
    WebhookLog::create([
        'transaction_id' => $transactionId,
        'event_type' => $eventType,
        'payload' => $request->all(),
        'status' => 'processed',
        'processed_at' => now()
    ]);
    
    return response()->json(['status' => 'processed'], 200);
}
```

---

## Webhooks Bancarios

### Transferencias SPEI (México)

Si se implementa confirmación automática de transferencias:

**Endpoint del Sistema:**
```
POST https://app.com/webhooks/spei
```

**Request del Banco/Proveedor:**
```http
POST https://app.com/webhooks/spei
Content-Type: application/json

{
  "event":  "spei.received",
  "timestamp": "2026-01-15T14:30:00Z",
  "transaction": {
    "tracking_key": "REF-2026-0001-ABC123",
    "amount":  499.00,
    "sender_name": "Juan Pérez",
    "sender_account": "012345678901234567",
    "receiver_account": "987654321098765432",
    "concept":  "Pago suscripción"
  }
}
```

**Acciones del Sistema:**
1. Buscar pago por `manual_payment_reference` = `tracking_key`
2. Validar monto coincida
3. Actualizar `payments.status = 'completed'`
4. Activar suscripción
5. Enviar confirmación a usuario

---

## Códigos de Error

### Errores del Sistema (4xx, 5xx)

| Código | Descripción | Solución |
|--------|-------------|----------|
| `400` | Bad Request - JSON inválido | Verificar formato de request |
| `401` | Unauthorized - Token inválido | Renovar token de autenticación |
| `402` | Payment Required - Requiere 3DS | Completar autenticación en modal |
| `403` | Forbidden - Sin permisos | Verificar permisos del usuario |
| `404` | Not Found - Recurso no existe | Verificar ID del recurso |
| `422` | Unprocessable Entity - Validación | Corregir datos según `errors` |
| `429` | Too Many Requests - Rate limit | Esperar antes de reintentar |
| `500` | Internal Server Error | Contactar soporte |
| `503` | Service Unavailable - Mantenimiento | Reintentar más tarde |

### Errores de Openpay

| Código | Descripción | Tipo |
|--------|-------------|------|
| `1000` | Error genérico | Técnico |
| `1001` | Fondos insuficientes | Usuario |
| `1002` | Tarjeta reportada como robada | Usuario/Banco |
| `1003` | Tarjeta rechazada | Usuario/Banco |
| `1004` | Tarjeta expirada | Usuario |
| `1005` | Tarjeta rechazada por el banco | Banco |
| `1006` | CVV inválido | Usuario |
| `1010` | Tarjeta bloqueada | Usuario/Banco |
| `3001` | 3DS authentication failed | Usuario/Banco |
| `3002` | 3DS authentication timeout | Usuario |
| `3003` | 3DS not available | Banco |
| `3005` | 3DS technical error | Técnico |

---

## Ejemplos de Uso

### Ejemplo 1: Flujo Completo de Registro con 3DS

```javascript
// Frontend:  Registro con tarjeta
async function registerWithTrial(formData) {
  try {
    // 1. Tokenizar tarjeta con Openpay. js (frontend)
    const deviceSessionId = OpenPay.deviceData.setup();
    const cardToken = await OpenPay.token.create(cardData);
    
    // 2. Enviar al backend
    const response = await fetch('/api/v1/subscriptions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      body: JSON.stringify({
        plan_id: formData.planId,
        periodicity: formData.periodicity,
        token_id: cardToken.data.id,
        device_session_id: deviceSessionId,
        billing_data: formData.billingData
      })
    });
    
    const data = await response.json();
    
    // 3. Verificar si requiere 3DS
    if (data.data.payment. requires_3ds) {
      // Mostrar modal 3DS
      await show3DSModal(data.data.payment. three_ds_redirect_url, data.data.payment.id);
    } else {
      // Registro completado
      window.location.href = '/dashboard';
    }
    
  } catch (error) {
    console.error('Error en registro:', error);
  }
}

// Función para mostrar modal 3DS
function show3DSModal(url, paymentId) {
  return new Promise((resolve, reject) => {
    const modal = document.getElementById('3ds-modal');
    const iframe = document.getElementById('3ds-iframe');
    
    iframe.src = url;
    modal.style.display = 'block';
    
    // Polling para verificar estado del pago
    const checkInterval = setInterval(async () => {
      const statusResponse = await fetch(`/api/v1/payments/${paymentId}/status`);
      const statusData = await statusResponse.json();
      
      if (statusData.data.status === 'completed') {
        clearInterval(checkInterval);
        modal.style.display = 'none';
        resolve();
        window.location.href = '/dashboard';
      } else if (statusData.data. status === 'failed') {
        clearInterval(checkInterval);
        modal.style.display = 'none';
        reject(new Error('Autenticación fallida'));
      }
    }, 3000);  // Verificar cada 3 segundos
    
    // Timeout de 15 minutos
    setTimeout(() => {
      clearInterval(checkInterval);
      reject(new Error('Timeout de autenticación'));
    }, 15 * 60 * 1000);
  });
}
```

### Ejemplo 2: Backend - Procesar Webhook de Pago Exitoso

```php
// app/Http/Controllers/WebhookController.php

use Illuminate\Http\Request;
use App\Models\Payment;
use App\Events\PaymentSuccessful;

class WebhookController extends Controller
{
    public function handleOpenpay(Request $request)
    {
        // 1. Validar firma HMAC
        if (!$this->validateSignature($request)) {
            Log::warning('Invalid webhook signature', [
                'ip' => $request->ip(),
                'payload' => $request->all()
            ]);
            return response()->json(['error' => 'Invalid signature'], 401);
        }
        
        // 2. Registrar webhook
        Log::info('Webhook received', [
            'type' => $request->input('type'),
            'transaction_id' => $request->input('transaction. id')
        ]);
        
        // 3. Procesar según tipo
        $eventType = $request->input('type');
        
        return match($eventType) {
            'charge.succeeded' => $this->handleChargeSucceeded($request),
            'charge.failed' => $this->handleChargeFailed($request),
            'charge.pending' => $this->handleChargePending($request),
            'charge.refunded' => $this->handleChargeRefunded($request),
            default => response()->json(['status' => 'ignored'], 200)
        };
    }
    
    private function handleChargeSucceeded(Request $request)
    {
        $transactionId = $request->input('transaction.id');
        $orderId = $request->input('transaction.order_id');
        
        // Buscar pago
        $payment = Payment::where('openpay_transaction_id', $transactionId)
            ->orWhere('id', str_replace('payment_', '', $orderId))
            ->first();
        
        if (!$payment) {
            Log::error('Payment not found for webhook', ['transaction_id' => $transactionId]);
            return response()->json(['error' => 'Payment not found'], 404);
        }
        
        // Verificar idempotencia
        if ($payment->status === 'completed') {
            return response()->json(['status' => 'already_processed'], 200);
        }
        
        // Actualizar pago
        $payment->update([
            'status' => 'completed',
            'paid_at' => now(),
            'three_ds_status' => $request->input('transaction.3d_secure. authenticated') 
                ? 'authenticated' 
                : 'not_required'
        ]);
        
        // Disparar evento
        event(new PaymentSuccessful($payment));
        
        return response()->json([
            'status' => 'processed',
            'payment_id' => $payment->id
        ], 200);
    }
    
    private function validateSignature(Request $request): bool
    {
        $signature = $request->header('X-Openpay-Signature');
        $payload = $request->getContent();
        $secretKey = config('openpay.webhook_secret');
        
        $calculatedSignature = hash_hmac('sha256', $payload, $secretKey);
        
        return hash_equals($signature, $calculatedSignature);
    }
}
```

---

## Testing

### Testing de Endpoints

```php
// tests/Feature/SubscriptionApiTest.php

use Tests\TestCase;
use App\Models\User;
use App\Models\Plan;

class SubscriptionApiTest extends TestCase
{
    /** @test */
    public function user_can_create_subscription_with_trial()
    {
        $user = User::factory()->create();
        $plan = Plan::factory()->create();
        
        $response = $this->actingAs($user)
            ->postJson('/api/v1/subscriptions', [
                'plan_id' => $plan->id,
                'periodicity' => 'monthly',
                'token_id' => 'tok_test_card',
                'device_session_id' => 'session_test',
                'billing_data' => [
                    'tax_id' => 'XAXX010101000',
                    'legal_name' => 'Test SA',
                    'tax_regime' => '612',
                    'postal_code' => '06600',
                    'cfdi_use' => 'G03'
                ]
            ]);
        
        $response->assertCreated();
        $response->assertJsonStructure([
            'data' => [
                'id',
                'status',
                'trial_ends_at',
                'payment' => [
                    'id',
                    'status',
                    'requires_3ds'
                ]
            ]
        ]);
    }
}
```

### Testing de Webhooks

```php
// tests/Feature/WebhookTest.php

class WebhookTest extends TestCase
{
    /** @test */
    public function handles_charge_succeeded_webhook()
    {
        $payment = Payment::factory()->create([
            'status' => 'pending',
            'openpay_transaction_id' => 'tr_test_123'
        ]);
        
        $payload = [
            'type' => 'charge.succeeded',
            'transaction' => [
                'id' => 'tr_test_123',
                'status' => 'completed',
                'amount' => 499.00
            ]
        ];
        
        $signature = hash_hmac('sha256', json_encode($payload), config('openpay.webhook_secret'));
        
        $response = $this->postJson('/webhooks/openpay', $payload, [
            'X-Openpay-Signature' => $signature
        ]);
        
        $response->assertOk();
        
        $payment->refresh();
        $this->assertEquals('completed', $payment->status);
    }
    
    /** @test */
    public function rejects_webhook_with_invalid_signature()
    {
        $response = $this->postJson('/webhooks/openpay', [
            'type' => 'charge.succeeded',
            'transaction' => ['id' => 'tr_test']
        ], [
            'X-Openpay-Signature' => 'invalid_signature'
        ]);
        
        $response->assertUnauthorized();
    }
}
```

### Postman Collection (Ejemplo)

```json
{
  "info": {
    "name": "Suscripciones API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"password\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{base_url}}/api/v1/auth/login",
              "host":  ["{{base_url}}"],
              "path": ["api", "v1", "auth", "login"]
            }
          }
        }
      ]
    },
    {
      "name":  "Subscriptions",
      "item": [
        {
          "name":  "Get Current Subscription",
          "request": {
            "method": "GET",
            "header": [
              {
                "key":  "Authorization",
                "value":  "Bearer {{token}}"
              }
            ],
            "url": {
              "raw": "{{base_url}}/api/v1/subscriptions/current",
              "host": ["{{base_url}}"],
              "path": ["api", "v1", "subscriptions", "current"]
            }
          }
        }
      ]
    }
  ]
}
```

---

## 📚 Referencias

- [Openpay API Documentation](https://www.openpay.mx/docs/api/)
- [Openpay 3D Secure](https://www.openpay.mx/docs/3d-secure. html)
- [Laravel API Resources](https://laravel.com/docs/10.x/eloquent-resources)
- [Laravel Sanctum](https://laravel.com/docs/10.x/sanctum)

---

**Versión:** 1.1  
**Cambios:**
- ✅ Agregados endpoints para autenticación 3DS (retry, status)
- ✅ Agregado webhook `charge.pending` para 3DS
- ✅ Actualizado response de creación de suscripción con datos 3DS
- ✅ Agregados códigos de error 3DS de Openpay
- ✅ Ejemplos de uso de flujo 3DS completo
- ✅ Tests para webhooks 3DS

---

**Fin del Documento**