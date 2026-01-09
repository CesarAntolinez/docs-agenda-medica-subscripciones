# Casos de Uso Detallados
## Sistema de Suscripciones - Agenda Médica SaaS

**Versión:** 1.2  
**Fecha:** Enero 2026  
**Actualización:** Casos de uso 3D Secure (3DS) + Períodos Personalizables

---

## 📑 Tabla de Contenidos

### Casos de Uso MVP (19 originales)
1. [UC-001: Registro de nuevo usuario con trial](#uc-001-registro-de-nuevo-usuario-con-trial)
2. [UC-002: Renovación automática exitosa](#uc-002-renovación-automática-exitosa)
3. [UC-003: Renovación automática fallida - Reintentos](#uc-003-renovación-automática-fallida---reintentos)
4. [UC-004: Período de gracia por fallo de pago](#uc-004-período-de-gracia-por-fallo-de-pago)
5. [UC-005: Pago manual con transferencia](#uc-005-pago-manual-con-transferencia)
6. [UC-006: Upgrade inmediato de plan](#uc-006-upgrade-inmediato-de-plan)
7. [UC-007: Downgrade programado de plan](#uc-007-downgrade-programado-de-plan)
8. [UC-008: Aplicar cupón de descuento](#uc-008-aplicar-cupón-de-descuento)
9. [UC-009: Referir a un amigo](#uc-009-referir-a-un-amigo)
10. [UC-010: Consumo de tokens y alertas](#uc-010-consumo-de-tokens-y-alertas)
11. [UC-011: Solicitar factura electrónica](#uc-011-solicitar-factura-electrónica)
12. [UC-012: Cancelación de suscripción](#uc-012-cancelación-de-suscripción)
13. [UC-013: Reactivación después de bloqueo](#uc-013-reactivación-después-de-bloqueo)
14. [UC-014: Admin - Gestionar plan de usuario](#uc-014-admin---gestionar-plan-de-usuario)
15. [UC-015: Admin - Crear cupón de descuento](#uc-015-admin---crear-cupón-de-descuento)
16. [UC-016: Admin - Procesar reembolso](#uc-016-admin---procesar-reembolso)
17. [UC-017: Admin - Subir y enviar factura](#uc-017-admin---subir-y-enviar-factura)
18. [UC-018: Webhook de pago exitoso desde Openpay](#uc-018-webhook-de-pago-exitoso-desde-openpay)
19. [UC-019: Webhook de pago fallido desde Openpay](#uc-019-webhook-de-pago-fallido-desde-openpay)

### 🆕 Casos de Uso 3DS (nuevos)
20. [UC-020: Autenticación 3DS en primer pago](#uc-020-autenticación-3ds-en-primer-pago)
21. [UC-021: Renovación automática con fallo por 3DS](#uc-021-renovación-automática-con-fallo-por-3ds)
22. [UC-022: Usuario autentica pago pendiente](#uc-022-usuario-autentica-pago-pendiente)

### 🆕 Casos de Uso Períodos Personalizables (nuevos)
23. [UC-023: Aplicar Trial Personalizado (Admin)](#uc-023-aplicar-trial-personalizado-admin)
24. [UC-024: Ajustar Grace Period Personalizado (Admin)](#uc-024-ajustar-grace-period-personalizado-admin)

---

## UC-001: Registro de nuevo usuario con trial

**Identificador:** UC-001  
**Nombre:** Registro de nuevo usuario con trial  
**Actores:** Usuario nuevo, Sistema, Openpay, Banco Emisor  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Un usuario nuevo se registra en la plataforma seleccionando un plan, completa sus datos, agrega una tarjeta con autenticación 3DS y activa su período de trial.

### Precondiciones
- Usuario NO tiene cuenta existente
- Usuario tiene tarjeta de crédito/débito válida
- Usuario tiene acceso a método de autenticación bancaria (SMS, app, biometría)

### Flujo Principal
1. Usuario accede a la página de planes de suscripción
2. Sistema muestra 3 planes disponibles con características, precios y periodicidades
3. Usuario selecciona plan deseado (ej: "Google Tech + IA 100")
4. Usuario selecciona periodicidad (mensual, anual, anual con cobros mensuales)
5. Sistema redirige a formulario de registro
6. Usuario completa datos personales: 
   - Nombre completo
   - Email
   - Contraseña
   - Rol (profesional, consultorio, asistente, paciente)
7. Sistema envía email de verificación
8. Usuario verifica email haciendo clic en el enlace
9. Sistema solicita datos fiscales según país: 
   - **México:** RFC, Razón social, Régimen fiscal, Código postal, Uso CFDI
   - **Colombia:** NIT, Razón social, Tipo persona, Dirección, Ciudad, Departamento
10. Usuario completa datos fiscales
11. Sistema valida datos fiscales según normativa del país
12. Sistema muestra formulario de pago con tarjeta
13. Usuario ingresa datos de tarjeta (número, CVV, fecha de expiración)
14. Sistema tokeniza tarjeta con Openpay. js (frontend)
15. Sistema solicita cargo de validación ($0 o $1) a Openpay con `use_3d_secure=true`
16. Openpay verifica con banco emisor si requiere 3DS
17. **Openpay responde que requiere 3DS** (caso más común)
18. Sistema muestra modal/iframe con página del banco
19. Usuario ve opciones de autenticación del banco (SMS, app, biometría)
20. Usuario selecciona método y completa autenticación
21. Banco confirma identidad del usuario
22. Openpay procesa cargo de validación
23. **Sistema recibe webhook `charge. succeeded` de Openpay**
24. Sistema guarda token de tarjeta en campo `subscriptions.card_token`
25. Sistema marca `subscriptions.first_payment_3ds_completed = true`
26. Sistema marca `subscriptions.mit_enabled = true`
27. Sistema crea suscripción con `status = 'trial'`
28. Sistema asigna tokens del plan en tabla `tokens_usage`
29. Sistema envía email de bienvenida (#1)
30. Sistema redirige a dashboard del usuario
31. Usuario puede comenzar a usar la plataforma

### Flujos Alternativos

**7a.  Email ya existe en el sistema**
- 7a. 1. Sistema muestra error:  "Este email ya está registrado"
- 7a.2. Sistema ofrece opción "¿Ya tienes cuenta?  Inicia sesión"
- 7a.3. Usuario hace clic en iniciar sesión
- 7a.4. Sistema redirige a página de login
- FIN del caso de uso

**11a. Datos fiscales incompletos o inválidos**
- 11a.1. Sistema valida datos según normativa del país
- 11a.2. Sistema muestra mensajes de error específicos por campo
- 11a.3. Usuario corrige datos
- 11a.4. CONTINÚA en paso 11

**20a. Usuario falla autenticación 3DS**
- 20a.1. Banco rechaza autenticación (código SMS incorrecto, canceló en app, etc.)
- 20a.2. Sistema recibe webhook `charge.failed` con razón `3ds_authentication_failed`
- 20a.3. Sistema muestra mensaje: "Autenticación fallida. ¿Deseas reintentar?"
- 20a.4. Usuario selecciona "Sí, reintentar"
- 20a.5. CONTINÚA en paso 15 (nuevo intento de cobro)

**20b. Usuario abandona modal 3DS (cierra ventana)**
- 20b.1. Sistema detecta cierre de modal sin completar
- 20b.2. Sistema muestra mensaje: "No completaste la autenticación.   ¿Deseas intentar de nuevo?"
- 20b. 3. Usuario selecciona opción
- 20b.4. SI selecciona "Sí" → CONTINÚA en paso 15
- 20b.5. SI selecciona "No" → FIN del caso de uso (registro no completado)

**20c.  Timeout de autenticación (15 minutos)**
- 20c.1. Sistema detecta que pasaron 15 minutos sin respuesta
- 20c. 2. Sistema marca pago como `failed` con razón `timeout`
- 20c.3. Sistema muestra mensaje: "La autenticación expiró. ¿Deseas intentar de nuevo?"
- 20c.4. CONTINÚA en flujo alternativo 20a. 4

**20d. Error técnico al cargar página del banco**
- 20d. 1. Modal no puede cargar página del banco (timeout, error servidor)
- 20d.2. Sistema muestra mensaje: "Error técnico. Intenta con otra tarjeta o contacta soporte"
- 20d. 3. Usuario puede: 
  - Reintentar con misma tarjeta → CONTINÚA en paso 15
  - Usar otra tarjeta → CONTINÚA en paso 13
  - Cancelar → FIN del caso de uso

**23a. Sistema NO recibe webhook en tiempo esperado (edge case)**
- 23a.1. Pasan 5 minutos sin recibir webhook de Openpay
- 23a.2. Sistema hace polling a API de Openpay para verificar estado del cargo
- 23a.3. SI cargo está completado → CONTINÚA en paso 24
- 23a.4. SI cargo falló → CONTINÚA en flujo alternativo 20a
- 23a.5. SI cargo aún está pendiente → Espera otros 5 minutos y repite polling

### Postcondiciones

**Éxito:**
- Usuario registrado en tabla `users` con `email_verified_at` != NULL
- Datos fiscales guardados en tabla `billing_data`
- Suscripción creada con `status = 'trial'`
- Token de tarjeta guardado en `subscriptions.card_token`
- `subscriptions.first_payment_3ds_completed = true`
- `subscriptions.mit_enabled = true`
- Registro de tokens creado en `tokens_usage` con `used=0`, `total=tokens_del_plan`
- Email de bienvenida enviado
- Usuario puede acceder a dashboard y consumir tokens

**Fallo:**
- Usuario NO registrado o parcialmente registrado
- NO hay suscripción activa
- NO hay tarjeta guardada
- Usuario puede reintentar el proceso completo

### Reglas de Negocio
- RN-001: Trial SIEMPRE requiere tarjeta guardada con autenticación 3DS
- RN-002: No se cobra durante el trial (cargo de $0 o $1 solo para validar tarjeta)
- RN-003: Días de trial son configurables por plan
- RN-004: Tokens durante trial = tokens completos del plan
- RN-005: Email debe ser único en el sistema
- RN-006: Datos fiscales son obligatorios antes de agregar tarjeta
- RN-007: Autenticación 3DS exitosa habilita MIT para pagos futuros

### Excepciones
- EX-001: Si servicio de Openpay no está disponible → Mostrar mensaje de mantenimiento
- EX-002: Si servicio de email no está disponible → Registro continúa, reintento de email después
- EX-003: Si banco emisor no soporta 3DS → Sistema rechaza la tarjeta (3DS es obligatorio)

### Notas Adicionales
- Tiempo estimado: 3-5 minutos
- Conversión esperada: 70-80% (con 3DS optimizado)
- Mensajes durante autenticación deben ser tranquilizadores:  "Es por tu seguridad"
- Preferir 3DS 2.0 (modal) sobre 3DS 1.0 (redirect) para mejor UX

---

## UC-002: Renovación automática exitosa

**Identificador:** UC-002  
**Nombre:** Renovación automática exitosa  
**Actores:** CronJob, Sistema, Openpay, Banco Emisor  
**Prioridad:** Crítica  
**Estado:** Activo  

### Descripción
El sistema renueva automáticamente una suscripción al llegar la fecha de cobro, usando MIT (exención de 3DS) para pagos recurrentes. 

### Precondiciones
- Suscripción existe con `status = 'active'` o `'trial'`
- `subscriptions.next_billing_date` = HOY
- Usuario tiene tarjeta guardada (`subscriptions.card_token` != NULL)
- `subscriptions.first_payment_3ds_completed = true`
- `subscriptions.mit_enabled = true`

### Flujo Principal
1. **CronJob diario** se ejecuta a las 00:00 AM
2. Sistema consulta suscripciones donde `next_billing_date <= HOY` AND `status IN ('active', 'trial')`
3. Para cada suscripción encontrada:
4. Sistema crea registro en tabla `payments`:
   - `status = 'pending'`
   - `amount` = precio del plan según país y periodicidad
   - `currency` = MXN o COP
   - `method = 'card'`
   - `attempt = 1`
5. Sistema solicita cargo a Openpay con: 
   - `source_id` = `subscriptions.card_token`
   - `merchant_initiated = true`
   - `mit_type = 'recurring'`
   - `use_3d_secure = false` (exención MIT)
6. **Openpay procesa cargo SIN solicitar 3DS** (MIT aceptado)
7. Openpay aprueba cargo inmediatamente
8. **Sistema recibe webhook `charge.succeeded`**
9. Sistema actualiza registro `payments`:
   - `status = 'completed'`
   - `paid_at = NOW()`
10. Sistema actualiza suscripción:
    - Si era `trial` → `status = 'active'`
    - `next_billing_date` = +1 mes o +1 año según periodicidad
11. Sistema actualiza o crea registro en `tokens_usage`:
    - `used = 0` (resetea a cero)
    - `total` = tokens del plan
    - `period_start` = HOY
    - `period_end` = próxima fecha de cobro - 1 día
12. Sistema envía email de confirmación de pago (#2)
13. Sistema marca para generación de factura (crear registro en `invoices` con `status = 'requested'`)

### Flujos Alternativos

**6a. Banco rechaza MIT y requiere 3DS**
- Ver UC-021 (flujo completo de renovación con 3DS requerido)

**7a.  Cargo rechazado por fondos insuficientes**
- Ver UC-003 (flujo de reintentos)

**7b. Cargo rechazado por tarjeta expirada**
- Ver UC-003 (flujo de reintentos)

### Postcondiciones

**Éxito:**
- Pago registrado en `payments` con `status = 'completed'`
- Suscripción renovada
- `subscriptions.next_billing_date` actualizada
- Tokens reseteados a cantidad del plan
- Email de confirmación enviado
- Factura marcada para generación

**Fallo:**
- Pago en `payments` con `status = 'failed'`
- Suscripción NO renovada, pasa a `status = 'past_due'`
- Se inicia flujo de reintentos (UC-003)

### Reglas de Negocio
- RN-008: MIT solo aplica si primer pago tuvo 3DS exitoso
- RN-009: Renovación se intenta el mismo día de `next_billing_date`
- RN-010: Tokens NO usados del período anterior se pierden (no acumulan)
- RN-011: Email de confirmación se envía solo si pago fue exitoso
- RN-012: Factura se genera después de pago confirmado

### Excepciones
- EX-004: Si Openpay no responde en 30 segundos → Reintentar después de 1 hora
- EX-005: Si webhook no llega en 5 minutos → Hacer polling a API de Openpay

### Notas Adicionales
- Tasa de éxito esperada con MIT: >85%
- Si banco siempre rechaza MIT para un usuario → Considerar notificar para autenticación manual

---

## UC-003: Renovación automática fallida - Reintentos

**Identificador:** UC-003  
**Nombre:** Renovación automática fallida - Reintentos  
**Actores:** CronJob, Sistema, Openpay, Usuario  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Cuando falla un pago de renovación (por fondos, tarjeta expirada, etc.), el sistema ejecuta hasta 3 reintentos automáticos antes de entrar en período de gracia.

### Precondiciones
- Intento de renovación falló (UC-002 o UC-021)
- Razón del fallo: fondos insuficientes, tarjeta expirada, error técnico (NO es fallo por 3DS requerido)
- `payments.status = 'failed'`
- `payments.attempt < 3`

### Flujo Principal
1. Sistema detecta pago fallido
2. Sistema guarda registro en `payment_retries`:
   - `payment_id` = ID del pago fallido
   - `attempt` = número de intento
   - `tried_at` = timestamp
   - `result` = razón del fallo (ej: "insufficient_funds")
3. Sistema actualiza suscripción:  `status = 'past_due'`
4. Sistema envía email de fallo de pago (#4) con:
   - Razón del fallo
   - Fecha del próximo reintento
   - Instrucciones para actualizar tarjeta o pagar manualmente
5. Sistema calcula fecha del reintento:
   - Intento 1 → +3 días
   - Intento 2 → +5 días adicionales (total 8 días desde fallo inicial)
   - Intento 3 → +7 días adicionales (total 15 días desde fallo inicial)
6. Sistema programa job `ProcessPaymentRetry` para la fecha calculada
7. **En la fecha programada:**
8. CronJob ejecuta `ProcessPaymentRetry`
9. Sistema crea nuevo registro en `payments` con:
   - `subscription_id` = mismo
   - `attempt` = intento anterior + 1
   - `status = 'pending'`
10. Sistema solicita cargo a Openpay nuevamente (mismo flujo UC-002)
11. **SI cobro es exitoso:**
    - CONTINÚA con flujo exitoso de UC-002
    - FIN del caso de uso
12. **SI cobro falla de nuevo:**
    - Sistema verifica:  `attempt < 3`?
    - SI SÍ → CONTINÚA en paso 2 (nuevo reintento)
    - SI NO (ya fueron 3 intentos) → CONTINÚA en paso 13
13. **Después de 3 fallos:**
14. Sistema inicia período de gracia (UC-004)

### Flujos Alternativos

**4a. Usuario actualiza tarjeta antes del reintento**
- 4a. 1. Usuario accede a su perfil
- 4a. 2. Usuario actualiza tarjeta (pasa por flujo 3DS de UC-020)
- 4a.3. Sistema guarda nuevo token en `subscriptions.card_token`
- 4a.4. Sistema cancela reintentos programados
- 4a.5. Sistema intenta cobro inmediato con nueva tarjeta
- 4a.6. SI exitoso → Renovación completada, FIN
- 4a.7. SI falla → CONTINÚA con reintentos normales

**4b. Usuario paga manualmente con transferencia**
- 4b. 1. Usuario solicita pago manual (UC-005)
- 4b.2. Usuario completa transferencia
- 4b.3. Sistema confirma pago
- 4b.4. Sistema cancela reintentos programados
- 4b.5. Sistema renueva suscripción
- 4b.6. FIN del caso de uso

### Postcondiciones

**Éxito (en algún reintento):**
- Pago completado
- Suscripción renovada
- Reintentos cancelados

**Fallo (3 intentos agotados):**
- 3 registros en `payment_retries`
- Suscripción pasa a período de gracia (UC-004)
- Usuario notificado

### Reglas de Negocio
- RN-013: Máximo 3 intentos automáticos
- RN-014: Días entre reintentos: 3, 5, 7
- RN-015: Usuario mantiene acceso durante reintentos (aún no entra en gracia)
- RN-016: Si usuario actualiza tarjeta, reintentos se cancelan e intenta inmediato

### Excepciones
- EX-006: Si los 3 reintentos fallan por la misma razón (ej: tarjeta expirada), considerar notificación especial

### Notas Adicionales
- Tasa de recuperación esperada: 40-50% (muchos usuarios actualizan tarjeta)
- Email de reintento debe ser claro sobre la acción requerida

---

## UC-004: Período de gracia por fallo de pago

**Identificador:** UC-004  
**Nombre:** Período de gracia por fallo de pago  
**Actores:** Sistema, Usuario  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Después de 3 fallos de pago, el usuario entra en un período de gracia de 2 meses donde mantiene acceso completo, pero acumula deuda. 

### Precondiciones
- 3 intentos de cobro fallidos (UC-003 completado sin éxito)
- `payments.attempt = 3` y `status = 'failed'`
- Suscripción en `status = 'past_due'`

### Flujo Principal
1. Sistema detecta que se agotaron los 3 reintentos
2. Sistema crea registro en tabla `grace_periods`:
   - `subscription_id` = ID de la suscripción
   - `started_at` = HOY
   - `ends_at` = HOY + 2 meses
   - `months_owed` = 1 (primer mes adeudado)
   - `amount_owed` = precio del plan
   - `notifications_sent` = 0
3. Sistema actualiza suscripción:  `status = 'grace_period'`
4. Sistema envía email de entrada en gracia (#6) con:
   - Explicación del período de gracia
   - Monto adeudado
   - Fecha límite (2 meses)
   - Instrucciones para pagar
   - **Usuario mantiene acceso completo**
5. Sistema programa recordatorios cada 15 días (configurable)
6. **Cada 15 días:**
7. CronJob ejecuta `SendGracePeriodReminder`
8. Sistema envía email recordatorio (#7-N)
9. Sistema incrementa `grace_periods. notifications_sent`
10. **Si usuario paga durante gracia:**
    - Sistema procesa pago (manual o actualiza tarjeta)
    - Sistema marca suscripción como `status = 'active'`
    - Sistema cierra `grace_periods` (actualiza con fecha de pago)
    - Sistema envía email de reactivación (#19)
    - FIN del caso de uso
11. **Si pasan 2 meses sin pago:**
12. Sistema actualiza suscripción:  `status = 'blocked'`
13. **Usuario pierde acceso a la plataforma**
14. Sistema registra deuda acumulada en `grace_periods.amount_owed`
15. Sistema envía email final de bloqueo
16. Usuario puede reactivar pagando deuda completa (UC-013)

### Flujos Alternativos

**10a. Usuario actualiza tarjeta y autoriza cobro**
- 10a. 1. Usuario accede a perfil
- 10a.2. Usuario actualiza tarjeta (flujo 3DS)
- 10a.3. Sistema intenta cobrar monto adeudado
- 10a.4. SI exitoso → Reactivación (paso 10)
- 10a.5. SI falla → Mantiene en gracia, intenta de nuevo en próximo recordatorio

**10b. Usuario paga con transferencia**
- 10b.1. Usuario solicita orden de pago manual (UC-005)
- 10b.2. Usuario paga por transferencia el monto adeudado
- 10b.3. Sistema confirma pago
- 10b.4. CONTINÚA en paso 10 (reactivación)

**11a. Plan anual con cobros mensuales - Deuda acumula**
- 11a. 1. Cada mes adicional sin pago incrementa: 
  - `grace_periods.months_owed` +1
  - `grace_periods.amount_owed` += precio mensual
- 11a.2. Después de 2 meses:  Bloqueo (paso 12)
- 11a.3. Usuario debe pagar TODOS los meses adeudados para reactivar

### Postcondiciones

**Pago durante gracia:**
- Suscripción reactivada
- `status = 'active'`
- Deuda saldada
- Acceso restaurado

**Bloqueo después de 2 meses:**
- `status = 'blocked'`
- Acceso bloqueado
- Deuda registrada
- Usuario debe pagar deuda completa para reactivar

### Reglas de Negocio
- RN-017: Período de gracia = 2 meses fijos
- RN-018: Usuario mantiene acceso COMPLETO durante gracia (puede usar tokens)
- RN-019: Recordatorios cada 15 días (configurable)
- RN-020: Después de 2 meses sin pago → Bloqueo automático
- RN-021: Deuda debe pagarse completa para reactivar (no hay pago parcial)

### Excepciones
- EX-007: Si usuario está en plan anual con cobros mensuales, el compromiso de 12 meses persiste

### Notas Adicionales
- Tasa de recuperación durante gracia: 30-40%
- Mensajes deben ser empáticos pero claros sobre la fecha límite
- Considerar ofrecer plan de pagos para deudas grandes (fase futura)

---

## UC-005: Pago manual con transferencia

**Identificador:** UC-005  
**Nombre:** Pago manual con transferencia bancaria  
**Actores:** Usuario, Sistema, Admin (validación manual)  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Usuario que no tiene tarjeta o prefiere no agregar puede pagar su suscripción con transferencia bancaria.

### Precondiciones
- Usuario seleccionó plan o necesita renovar suscripción
- Usuario selecciona método de pago "Transferencia bancaria"

### Flujo Principal
1. Usuario en paso de selección de método de pago
2. Usuario selecciona "Transferencia bancaria" (SPEI en MX, PSE/Transferencia en CO)
3. Sistema muestra confirmación de plan y monto
4. Usuario confirma
5. Sistema genera orden de pago con:
   - Referencia única (ej: `REF-2026-0001-ABC123`)
   - Monto exacto
   - Moneda
   - Fecha límite de pago
6. Sistema crea registro en `payments`:
   - `method = 'bank_transfer'`
   - `status = 'pending'`
   - `manual_payment_reference` = referencia generada
7. Sistema muestra instrucciones en pantalla según país:
   
   **México (SPEI):**
   - CLABE interbancaria
   - Beneficiario
   - Banco
   - Referencia única
   - Monto
   - Fecha límite
   
   **Colombia:**
   - Número de cuenta
   - Tipo de cuenta
   - Banco
   - NIT beneficiario
   - Referencia única
   - Monto
   - Fecha límite

8. Sistema envía email con instrucciones completas (#5)
9. Usuario realiza transferencia desde su banco/app bancaria
10. **Confirmación automática (si webhook disponible):**
    - Banco envía webhook de confirmación
    - Sistema valida referencia única
    - CONTINÚA en paso 15
11. **Confirmación manual (si NO hay webhook):**
    - Admin revisa depósitos bancarios diariamente
    - Admin busca transacción con referencia única
    - Admin encuentra transacción
    - Admin accede a panel de órdenes de pago pendientes
12. Admin selecciona orden de pago correspondiente
13. Admin valida: 
    - Monto coincide
    - Referencia coincide
    - Fecha dentro del límite
14. Admin marca orden como "Confirmada" en el sistema
15. **Sistema procesa confirmación:**
16. Sistema actualiza `payments`:
    - `status = 'completed'`
    - `paid_at = NOW()`
17. Sistema activa o renueva suscripción
18. Sistema asigna tokens
19. Sistema envía email de confirmación (#2)
20. Sistema marca para facturación
21. Usuario puede acceder a la plataforma

### Flujos Alternativos

**9a. Usuario NO paga antes de la fecha límite**
- 9a.1. Sistema ejecuta CronJob diario de verificación de órdenes expiradas
- 9a. 2. Sistema detecta `payments.created_at + días_límite < HOY`
- 9a.3. Sistema actualiza `payments.status = 'cancelled'`
- 9a.4. Sistema envía email de orden expirada
- 9a.5. Usuario puede generar nueva orden → CONTINÚA en paso 2

**9b. Usuario paga monto incorrecto**
- 9b.1. Admin detecta que monto no coincide
- 9b.2. Admin contacta al usuario vía email/teléfono
- 9b.3. Usuario puede: 
  - Transferir la diferencia faltante
  - Solicitar devolución y generar nueva orden
- 9b.4. Una vez solucionado → CONTINÚA en paso 15

**9c. Usuario paga sin incluir referencia o con referencia incorrecta**
- 9c.1. Admin no puede identificar el pago automáticamente
- 9c. 2. Admin contacta al usuario
- 9c.3. Usuario proporciona comprobante de pago
- 9c.4. Admin valida manualmente y asocia el pago
- 9c. 5. CONTINÚA en paso 15

**11a. Usuario pregunta si su pago fue recibido**
- 11a.1. Usuario contacta soporte
- 11a.2.  Soporte revisa estado en panel admin
- 11a.3. SI confirmado → Informar al usuario
- 11a. 4. SI NO confirmado → Solicitar comprobante y revisar con admin

### Postcondiciones

**Éxito:**
- Pago confirmado en `payments` con `status = 'completed'`
- Suscripción activa
- Tokens asignados
- Usuario notificado

**Expiración:**
- Orden de pago cancelada
- Usuario puede generar nueva orden

### Reglas de Negocio
- RN-022: Fecha límite varía según tipo: 
  - Trial: 24 horas
  - Renovación: 3 días
  - Pago único: 7 días
- RN-023: Monto debe ser EXACTO (no mayor ni menor)
- RN-024: Referencia es obligatoria para confirmación automática
- RN-025: Usuario puede agregar tarjeta después para automatizar futuros pagos

### Excepciones
- EX-008: Si banco tarda más de 48 horas en procesar → Extender límite si usuario contacta soporte

### Notas Adicionales
- Tiempo promedio de confirmación: 24-48 horas
- Considerar implementar webhook bancario para automatizar (reduce carga de admin)

---

## UC-006: Upgrade inmediato de plan

**Identificador:** UC-006  
**Nombre:** Upgrade inmediato de plan  
**Actores:** Usuario, Sistema, Openpay, Banco Emisor  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Usuario quiere subir a un plan superior inmediatamente para obtener más tokens.  El sistema cobra la diferencia prorrateada y puede requerir autenticación 3DS.

### Precondiciones
- Usuario tiene suscripción activa
- Existe plan superior disponible
- Usuario tiene tarjeta guardada O puede agregar una nueva

### Flujo Principal
1. Usuario accede a sección "Cambiar plan" desde su dashboard
2. Sistema muestra plan actual y planes superiores disponibles
3. Usuario selecciona plan superior (ej: de "IA 50" a "IA 100")
4. Sistema calcula prorrata: 
   - Días restantes del período actual
   - Diferencia de precio entre planes
   - Cargo = (Precio nuevo - Precio actual) × (Días restantes / Días totales)
5. Sistema muestra resumen del upgrade:
   ```
   Plan actual: Google Tech + IA 50 ($299 MXN/mes)
   Plan nuevo: Google Tech + IA 100 ($499 MXN/mes)
   Días restantes: 15 días
   
   Cargo hoy: $100 MXN (prorrata 15 días)
   Próximo cobro (15 de febrero): $499 MXN
   
   Tokens actuales: 500 usados / 5,000 totales
   Tokens después de upgrade: 0 usados / 10,000 totales (disponibles HOY)
   ```
6. Usuario confirma upgrade
7. Sistema crea registro en `payments`:
   - `amount` = cargo de prorrata
   - `status = 'pending'`
   - `method = 'card'`
8. Sistema solicita cargo a Openpay
9. Openpay verifica con banco emisor
10. **Banco puede requerir 3DS** (según monto y políticas)
11. SI requiere 3DS: 
    - Sistema muestra modal 3DS
    - Usuario autentica
    - Sistema recibe webhook de confirmación
12. SI NO requiere 3DS: 
    - Cargo se procesa inmediatamente
13. **Cargo completado exitosamente**
14. Sistema actualiza suscripción:
    - `plan_id` = nuevo plan
    - `next_billing_date` se mantiene
15. Sistema actualiza tokens:
    - `tokens_usage. used = 0`
    - `tokens_usage.total` = tokens del nuevo plan
16. Sistema envía email de confirmación de upgrade (#9)
17. Sistema muestra mensaje de éxito y redirige a dashboard
18. Usuario ve inmediatamente los nuevos tokens disponibles

### Flujos Alternativos

**6a. Usuario cancela antes de confirmar**
- 6a. 1. Usuario hace clic en "Cancelar"
- 6a.2. Sistema descarta cálculo de prorrata
- 6a. 3. FIN del caso de uso (sin cambios)

**11a.  Autenticación 3DS falla**
- 11a.1. Usuario falla o cancela autenticación
- 11a.2. Sistema muestra error
- 11a.3. Sistema ofrece opciones: 
  - Reintentar
  - Actualizar tarjeta
  - Cancelar upgrade
- 11a.4. Usuario selecciona opción
- 11a.5. SI reintentar → CONTINÚA en paso 8
- 11a.6. SI actualizar tarjeta → Flujo de actualizar tarjeta (UC-020)
- 11a.7. SI cancelar → FIN (sin cambios)

**13a.  Cargo rechazado por fondos insuficientes**
- 13a.1. Openpay devuelve error de fondos
- 13a.2. Sistema muestra mensaje:  "Fondos insuficientes"
- 13a.3. Sistema ofrece opciones:
  - Intentar con otra tarjeta
  - Pagar con transferencia (genera orden de pago manual)
  - Cancelar
- 13a.4. Usuario selecciona opción
- 13a.5. Procesa según selección

### Postcondiciones

**Éxito:**
- Suscripción actualizada al nuevo plan
- Pago de prorrata completado
- Tokens reseteados a cantidad del nuevo plan
- Usuario notificado
- Próximo cobro será por monto completo del nuevo plan

**Fallo:**
- Suscripción permanece en plan actual
- No se realizó cargo
- Tokens permanecen iguales

### Reglas de Negocio
- RN-026: Upgrade es inmediato (se aplica el mismo día)
- RN-027: Se cobra prorrata solo por días restantes
- RN-028: Tokens se resetean a 0 usados / Total del nuevo plan (NO se suman)
- RN-029: Próximo cobro será por monto completo del nuevo plan
- RN-030: Puede requerir 3DS según monto y políticas del banco

### Excepciones
- EX-009: Si el upgrade es dentro de las últimas 48 horas del período → Cobrar monto completo del nuevo plan (evita cálculos complejos)

### Notas Adicionales
- Tiempo estimado:  1-3 minutos (incluyendo 3DS si aplica)
- Cálculo de prorrata debe ser transparente y mostrado antes de confirmar

---

## UC-007: Downgrade programado de plan

**Identificador:** UC-007  
**Nombre:** Downgrade programado de plan  
**Actores:** Usuario, Sistema, CronJob  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Usuario quiere bajar a un plan inferior.  El cambio se programa para el fin del período actual (no se aplica inmediatamente).

### Precondiciones
- Usuario tiene suscripción activa
- Existe plan inferior disponible

### Flujo Principal
1. Usuario accede a sección "Cambiar plan"
2. Sistema muestra plan actual y planes inferiores disponibles
3. Usuario selecciona plan inferior (ej: de "IA 100" a "IA 50")
4. Sistema muestra advertencia y detalles: 
   ```
   ⚠️ IMPORTANTE: 
   
   Plan actual: Google Tech + IA 100 ($499 MXN/mes)
   Plan nuevo:   Google Tech + IA 50 ($299 MXN/mes)
   
   El cambio se aplicará:  28 de febrero (fin de período actual)
   Hasta entonces:  Puedes seguir usando tu plan actual
   Tokens actuales: 3,000 usados / 10,000 totales
   
   Desde el 1 de marzo: 
   - Plan:  Google Tech + IA 50
   - Cobro mensual: $299 MXN
   - Tokens:   5,000 mensuales
   
   Puedes cancelar este cambio en cualquier momento antes del 28 de febrero. 
   ```
5. Usuario confirma downgrade programado
6. Sistema actualiza suscripción:
   - `pending_plan_id` = ID del plan inferior
   - `pending_plan_change_date` = fin del período actual
   - `status` se mantiene como `'active'`
7. Sistema envía email de confirmación (#9) con detalles del cambio programado
8. Sistema muestra indicador en dashboard:  "Cambio de plan programado para [fecha]"
9. Usuario puede seguir usando el plan actual normalmente hasta la fecha programada
10. **En la fecha programada:**
11. CronJob diario detecta suscripciones con `pending_plan_change_date = HOY`
12. Sistema aplica el cambio:
    - `plan_id` = `pending_plan_id`
    - `pending_plan_id` = NULL
    - `pending_plan_change_date` = NULL
    - `next_billing_date` = HOY + 1 mes (o según periodicidad)
13. Sistema actualiza tokens para el próximo período: 
    - `tokens_usage.total` = tokens del nuevo plan (menor cantidad)
14.  Próximo cobro será por el monto del nuevo plan (menor)
15. Sistema envía email confirmando que el cambio se aplicó
16. Usuario ve el nuevo plan y tokens en su dashboard

### Flujos Alternativos

**5a. Usuario cancela antes de confirmar**
- 5a. 1. Usuario hace clic en "Cancelar"
- 5a.2. FIN del caso de uso (sin cambios programados)

**10a. Usuario cancela el cambio programado antes de la fecha**
- 10a. 1. Usuario accede a su perfil
- 10a. 2. Usuario ve indicador: "Cambio programado para [fecha]"
- 10a.3. Usuario hace clic en "Cancelar cambio programado"
- 10a. 4. Sistema muestra confirmación: "¿Estás seguro?  Mantendrás tu plan actual."
- 10a. 5. Usuario confirma cancelación
- 10a.6. Sistema actualiza suscripción:
  - `pending_plan_id` = NULL
  - `pending_plan_change_date` = NULL
- 10a.7. Sistema envía email confirmando cancelación
- 10a.8. FIN del caso de uso (se mantiene plan actual)

**11a. Usuario hace upgrade antes de que se aplique el downgrade**
- 11a. 1. Usuario solicita upgrade (UC-006)
- 11a.2. Sistema cancela automáticamente el downgrade programado
- 11a.3. Sistema aplica upgrade inmediato
- 11a.4. FIN del caso de uso de downgrade (fue superado por upgrade)

### Postcondiciones

**Éxito:**
- Cambio programado guardado en suscripción
- Usuario notificado
- Indicador visible en dashboard
- En la fecha programada: Plan cambia automáticamente

**Cancelación:**
- Cambio programado eliminado
- Usuario permanece en plan actual

### Reglas de Negocio
- RN-031: Downgrade NO se aplica inmediatamente (siempre es programado)
- RN-032: Usuario puede seguir usando plan actual hasta fin de período
- RN-033: Usuario puede cancelar el cambio programado en cualquier momento antes de la fecha
- RN-034: Si usuario hace upgrade antes de downgrade programado → Upgrade cancela downgrade
- RN-035: Próximo cobro será por monto del nuevo plan (menor)

### Excepciones
- EX-010: Si usuario está en plan anual con cobros mensuales → Debe completar 12 meses antes de permitir downgrade

### Notas Adicionales
- Downgrade programado evita pérdida de dinero del usuario (no cobra menos inmediatamente)
- Usuario puede cambiar de opinión fácilmente antes de la fecha

---

## UC-020: Autenticación 3DS en primer pago

**Identificador:** UC-020 🆕  
**Nombre:** Autenticación 3D Secure en primer pago  
**Actores:** Usuario, Sistema, Openpay, Banco Emisor  
**Prioridad:** Crítica  
**Estado:** Activo  

### Descripción
Proceso completo de autenticación 3D Secure cuando un usuario agrega una tarjeta por primera vez o actualiza su tarjeta de pago. 

### Precondiciones
- Usuario está en proceso de agregar tarjeta (registro, actualización, o upgrade)
- Usuario tiene acceso a método de autenticación del banco (SMS, app, biometría)
- Servicio de Openpay está disponible

### Flujo Principal
1. Usuario completa formulario de tarjeta: 
   - Número de tarjeta
   - Fecha de expiración (MM/AA)
   - CVV
   - Nombre del titular
2. Sistema ejecuta `Openpay.js` en frontend para tokenizar tarjeta
3. `Openpay.js` envía datos sensibles directamente a servidores de Openpay (PCI compliant)
4. Openpay devuelve token de tarjeta al frontend
5. Frontend envía token al backend (NO envía datos de tarjeta reales)
6. Backend recibe token y datos del usuario
7. Backend genera `device_session_id` con Openpay SDK
8. Backend solicita cargo de validación a Openpay API: 
   ```json
   {
     "source_id": "tok_abc123",
     "method": "card",
     "amount": 1. 00,
     "currency": "MXN",
     "description": "Validación de tarjeta - Trial",
     "use_3d_secure": true,
     "device_session_id": "session_xyz",
     "redirect_url": "https://app.com/payments/3ds-callback/{{PAYMENT_ID}}"
   }
   ```
9. Openpay procesa solicitud y consulta con banco emisor
10. **Banco emisor requiere 3DS** (caso más común)
11. Openpay devuelve respuesta: 
    ```json
    {
      "id": "tr4n54ct10n1d",
      "status": "charge_pending",
      "payment_method": {
        "type": "redirect",
        "url": "https://sandbox-api.openpay.mx/v1/threed-secure/challenge/.. .",
        "requires_3d_secure": true
      },
      "3d_secure":  {
        "version": "2.0",
        "challenge_required": true
      }
    }
    ```
12. Backend actualiza `payments`:
    - `status = 'requires_3ds'`
    - `three_ds_status = 'pending'`
    - `three_ds_redirect_url` = URL del banco
    - `three_ds_version = '2.0'`
13. Backend devuelve respuesta al frontend con URL de autenticación
14. **Frontend muestra modal 3DS:**
    - Opción A (3DS 2.0 - Preferido): Iframe dentro de modal
    - Opción B (3DS 1.0 - Fallback): Redirect completo
15. Modal muestra mensaje tranquilizador:
    ```
    🔒 Autenticación de seguridad requerida
    
    Tu banco necesita verificar que realmente eres tú.
    Este proceso es estándar y protege tu dinero.
    
    [Cargando página del banco...]
    ```
16. Modal/iframe carga página del banco emisor
17. **Usuario ve opciones de autenticación del banco:**
    - Opción 1: Código por SMS
    - Opción 2: Confirmar en app bancaria
    - Opción 3: Biometría (huella, Face ID)
18. Usuario selecciona método (ej: SMS)
19. Banco envía código SMS al celular del usuario
20. Usuario ingresa código en la página del banco
21. Banco valida código
22. **Código correcto:**
23. Banco confirma identidad del usuario
24. Banco notifica a Openpay que autenticación fue exitosa
25. **Openpay envía webhook al backend:**
    ```json
    {
      "type": "charge. succeeded",
      "event_date": "2026-01-09T10:35:00Z",
      "data": {
        "id": "tr4n54ct10n1d",
        "status": "completed",
        "3d_secure":  {
          "authenticated": true,
          "eci":  "05",
          "cavv": "base64_value"
        }
      }
    }
    ```
26. Backend procesa webhook:
    - Valida firma HMAC del webhook
    - Busca payment por `openpay_transaction_id`
    - Actualiza `payments`:
      - `status = 'completed'`
      - `three_ds_status = 'authenticated'`
      - `paid_at = NOW()`
27. Backend cierra modal/iframe en frontend (vía WebSocket o polling)
28. Frontend muestra mensaje de éxito:
    ```
    ✅ Tarjeta validada exitosamente
    
    Tu tarjeta ha sido guardada de forma segura.
    Ya puedes continuar. 
    ```
29. Backend guarda token de tarjeta en `subscriptions. card_token`
30. Backend marca `subscriptions.first_payment_3ds_completed = true`
31. Backend marca `subscriptions.mit_enabled = true` (habilita pagos recurrentes sin 3DS)
32. Sistema continúa con flujo correspondiente (registro, upgrade, etc.)

### Flujos Alternativos

**20a. Usuario ingresa código incorrecto**
- 20a.1. Banco rechaza código
- 20a. 2. Banco muestra mensaje:  "Código incorrecto.  Intentos restantes: X"
- 20a.3. Usuario puede: 
  - Reintentar (máximo 3 intentos según banco)
  - Solicitar reenvío de código
- 20a.4. SI agota 3 intentos → CONTINÚA en flujo alternativo 22a

**21a.  Timeout de autenticación (15 minutos)**
- 21a.1. Pasan 15 minutos sin respuesta del usuario
- 21a.2. Banco cancela sesión de autenticación
- 21a. 3. Openpay envía webhook `charge.failed` con razón `timeout`
- 21a.4. Backend actualiza `payments`:
  - `status = 'failed'`
  - `three_ds_status = 'timeout'`
  - `error_message = '3DS authentication timeout'`
- 21a.5. Frontend cierra modal y muestra error
- 21a.6. Sistema ofrece:
  - "Reintentar autenticación" → CONTINÚA en paso 8
  - "Usar otra tarjeta" → CONTINÚA en paso 1
  - "Cancelar" → FIN del caso de uso

**22a.  Usuario falla autenticación (rechaza, cancela, error)**
- 22a.1. Banco rechaza autenticación
- 22a. 2. Openpay envía webhook `charge.failed`:
    ```json
    {
      "type": "charge.failed",
      "data": {
        "id": "tr4n54ct10n1d",
        "status": "failed",
        "error_code": "3001",
        "description": "3D Secure authentication failed",
        "3d_secure": {
          "authenticated": false,
          "reason": "user_cancelled"
        }
      }
    }
    ```
- 22a.3. Backend actualiza `payments`:
  - `status = 'failed'`
  - `three_ds_status = 'failed'`
  - `error_code = '3001'`
  - `error_message = '3D Secure authentication failed'`
- 22a.4. Frontend muestra mensaje claro:
    ```
    ❌ No se pudo completar la autenticación
    
    Razón: [Cancelaste / Código incorrecto / Error del banco]
    
    ¿Qué deseas hacer?
    • Reintentar autenticación
    • Intentar con otra tarjeta
    • Contactar soporte
    ```
- 22a.5. Usuario selecciona opción
- 22a.6. Sistema procesa según selección

**16a. Error al cargar página del banco (timeout de red)**
- 16a.1. Modal no puede cargar URL del banco (timeout después de 30 segundos)
- 16a.2. Frontend muestra error:
    ```
    ❌ Error de conexión
    
    No pudimos conectar con tu banco. 
    Esto puede ser un problema temporal.
    
    • Reintentar
    • Usar otra tarjeta
    • Contactar soporte
    ```
- 16a.3. Usuario selecciona opción
- 16a.4. SI reintentar → CONTINÚA en paso 8
- 16a. 5. SI otra tarjeta → CONTINÚA en paso 1

**25a.  Webhook no llega en tiempo esperado (5 minutos)**
- 25a.1. Pasan 5 minutos después de autenticación exitosa sin recibir webhook
- 25a.2. Backend hace polling a Openpay API: 
    ```
    GET /v1/charges/{transaction_id}
    ```
- 25a.3. Openpay devuelve estado actual del cargo
- 25a.4. SI estado es `completed` → CONTINÚA en paso 26
- 25a.5. SI estado es `failed` → CONTINÚA en flujo alternativo 22a
- 25a.6. SI estado es `pending` → Espera otros 5 minutos y repite polling

### Postcondiciones

**Éxito:**
- Tarjeta validada con autenticación 3DS
- Token guardado en `subscriptions.card_token`
- `first_payment_3ds_completed = true`
- `mit_enabled = true` (habilita pagos recurrentes)
- Registro en `payments` con `three_ds_status = 'authenticated'`
- Usuario puede continuar con flujo (registro, upgrade, etc.)

**Fallo:**
- Tarjeta NO guardada
- Usuario debe reintentar o usar otra tarjeta
- Registro en `payments` con `three_ds_status = 'failed'` o `'timeout'`

### Reglas de Negocio
- RN-036: 3DS es OBLIGATORIO en todos los primeros pagos
- RN-037: Autenticación exitosa habilita MIT para futuros pagos
- RN-038: Timeout de autenticación:  15 minutos
- RN-039: Preferir 3DS 2.0 (iframe) sobre 3DS 1.0 (redirect)
- RN-040: Webhook de Openpay debe validarse con firma HMAC
- RN-041: Si webhook no llega en 5 minutos → Hacer polling a API

### Excepciones
- EX-011: Si banco NO soporta 3DS → Rechazar tarjeta (3DS es obligatorio)
- EX-012: Si Openpay API no responde en 30 segundos → Mostrar error técnico y reintentar
- EX-013: Si usuario no tiene celular para SMS → Banco debe ofrecer método alternativo (app, biometría)

### Notas Adicionales
- **Conversión esperada:** 85-92% (con 3DS 2.0)
- **Tiempo promedio:** 30 segundos - 2 minutos
- **Abandono:** 8-15% (usuarios que cancelan en autenticación)
- Mensajes deben ser tranquilizadores:  "Es por tu seguridad", "Proceso estándar"
- Evitar términos técnicos como "3DS" o "tokenización" en mensajes al usuario

---

## UC-021: Renovación automática con fallo por 3DS

**Identificador:** UC-021 🆕  
**Nombre:** Renovación automática con fallo por requerimiento de 3DS  
**Actores:** CronJob, Sistema, Openpay, Banco Emisor, Usuario  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Durante una renovación automática, el banco emisor rechaza MIT y requiere autenticación 3DS del usuario. El sistema notifica al usuario y le da 24 horas para autenticar. 

### Precondiciones
- Suscripción con `next_billing_date = HOY`
- `subscriptions.mit_enabled = true`
- CronJob de renovaciones en ejecución

### Flujo Principal
1. CronJob inicia proceso de renovación automática (UC-002)
2. Sistema solicita cargo a Openpay con MIT (sin 3DS)
3. Openpay consulta con banco emisor
4. **Banco emisor rechaza MIT y requiere 3DS** (decisión del banco)
5. Openpay devuelve respuesta: 
   ```json
   {
     "id": "tr4n54ct10n1d",
     "status": "charge_pending",
     "payment_method": {
       "type": "redirect",
       "url": "https://banco. com/3ds/.. .",
       "requires_3d_secure": true
     },
     "error_code": "3002",
     "description": "3D Secure authentication required"
   }
   ```
6. Sistema detecta que requiere 3DS
7. Sistema actualiza `payments`:
   - `status = 'requires_3ds'`
   - `three_ds_status = 'pending'`
   - `three_ds_redirect_url` = URL del banco
   - `requires_3ds = true`
8. Sistema actualiza suscripción:  `status = 'past_due'` (temporal)
9. **Sistema envía Email #20:  "Acción requerida - Autentica tu pago":**
   ```
   Asunto: 🔒 Acción requerida:  Autentica tu pago de suscripción
   
   Hola [Nombre],
   
   Tu pago de renovación de [Plan] por $[Monto] [Moneda] requiere 
   autenticación adicional por seguridad de tu banco.
   
   Por favor, haz clic en el botón de abajo para completar la 
   autenticación en tu banco (toma menos de 1 minuto):
   
   [Botón grande:  Autenticar mi pago ahora]
   → Link:  https://app.com/payments/authenticate/{{PAYMENT_ID}}
   
   ⏰ Tiempo límite: 24 horas
   
   Si no completas la autenticación, tu suscripción entrará en 
   período de gracia y podrías perder acceso a tus tokens.
   
   ¿Por qué necesito autenticar? 
   Tu banco requiere verificar tu identidad para mayor seguridad 
   de tus pagos.  Es un proceso simple y seguro.
   
   ¿Necesitas ayuda?  Contacta a soporte. 
   
   Saludos,
   Equipo [Plataforma]
   ```
10. Sistema marca `authentication_required_notified_at = NOW()`
11. **Usuario recibe email y toma acción (ver UC-022 para flujo completo)**
12. SI usuario autentica exitosamente en 24 horas: 
    - Pago se completa
    - Suscripción se renueva
    - `status = 'active'`
    - FIN del caso de uso (éxito)
13. SI usuario NO autentica en 24 horas:
    - CONTINÚA en paso 14
14. **Timeout de 24 horas sin acción del usuario:**
15. CronJob ejecuta `CheckPending3DSPayments`
16. Sistema detecta pagos con: 
    - `status = 'requires_3ds'`
    - `authentication_required_notified_at < NOW() - 24 horas`
17. Sistema marca pago como fallido: 
    - `status = 'failed'`
    - `three_ds_status = 'timeout'`
    - `error_message = 'User did not complete 3DS authentication in 24h'`
18. Sistema cuenta este fallo como "Intento 1"
19. Sistema inicia flujo de reintentos (UC-003)
20. Sistema envía email de fallo de pago (#4)

### Flujos Alternativos

**12a. Usuario autentica después de 24h pero antes de 3 días (reintento 1)**
- 12a.1. Usuario hace clic en email después de 24h
- 12a.2. Sistema muestra mensaje: "El tiempo límite expiró, pero puedes reintentar"
- 12a.3. Sistema genera nuevo intento de cobro
- 12a.4.  CONTINÚA con flujo de autenticación (UC-022)

**5a.  Banco acepta MIT (no requiere 3DS)**
- 5a.1. Este es el flujo normal exitoso (UC-002)
- 5a.2. No se requiere autenticación del usuario
- 5a.3. FIN del caso de uso (éxito sin 3DS)

### Postcondiciones

**Usuario autentica a tiempo:**
- Pago completado
- Suscripción renovada
- Acceso continúa normal

**Usuario NO autentica:**
- Pago marcado como fallido
- Se inicia flujo de reintentos
- Usuario notificado de fallo

### Reglas de Negocio
- RN-042: Usuario tiene 24 horas para autenticar desde que recibe email
- RN-043: Si no autentica en 24h → cuenta como fallo y entra en reintentos
- RN-044: Banco decide si requiere 3DS (sistema no puede forzar MIT)
- RN-045: Email #20 debe enviarse inmediatamente (en menos de 5 minutos)
- RN-046: Usuario mantiene acceso a plataforma durante 24h de espera

### Excepciones
- EX-014: Si email #20 no se envía (problema SMTP) → Reintentar envío cada hora
- EX-015: Si banco siempre requiere 3DS para un usuario → Considerar marcar para autenticación manual proactiva

### Notas Adicionales
- **Tasa de respuesta en 24h esperada:** 60-70%
- **Tasa de autenticación exitosa (de los que intentan):** 85-90%
- Email debe tener subject line claro y urgente
- Link en email debe ser acceso directo (no requerir navegación adicional)

---

## UC-022: Usuario autentica pago pendiente

**Identificador:** UC-022 🆕  
**Nombre:** Usuario autentica pago pendiente 3DS  
**Actores:** Usuario, Sistema, Openpay, Banco Emisor  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Usuario hace clic en email de autenticación requerida y completa el proceso 3DS para autorizar un pago pendiente.

### Precondiciones
- Pago existe con `status = 'requires_3ds'`
- Usuario recibió Email #20 (UC-021)
- Usuario tiene acceso a método de autenticación del banco

### Flujo Principal
1. Usuario abre Email #20 en su dispositivo (móvil o desktop)
2. Usuario lee contenido del email
3. Usuario hace clic en botón "Autenticar mi pago ahora"
4. Sistema verifica si usuario está logueado
5. SI NO está logueado: 
   - Sistema redirige a página de login
   - Usuario ingresa email y contraseña
   - Sistema autentica y continúa
6. Sistema carga página de autenticación de pago: 
   ```
   /payments/authenticate/{{PAYMENT_ID}}
   ```
7. Sistema valida:  
   - Pago pertenece al usuario logueado
   - Pago tiene `status = 'requires_3ds'`
   - Pago no ha expirado (creado hace menos de 7 días)
8. **Sistema muestra página de información:**
   ```
   🔒 Autenticación de pago requerida
   
   Tu pago de suscripción necesita ser autorizado por tu banco
   
   Plan: Google Tech + IA 100
   Monto: $499.00 MXN
   Fecha: 15 de enero, 2026
   Estado: Pendiente de autenticación
   
   ¿Por qué necesito hacer esto? 
   
   🛡️ Tu banco requiere verificar que realmente eres tú quien 
   está autorizando este pago. Es un proceso estándar de 
   seguridad bancaria que protege tu dinero de fraude.
   
   ✅ Es seguro y solo toma 1 minuto
   ⏱️ Verás opciones como: código SMS, app bancaria, o huella digital
   
   [Botón grande azul: Autenticar mi pago de $499.00 MXN]
   
   ¿Necesitas ayuda?   [Chat con soporte]
   ```
9. Usuario lee información y hace clic en botón de autenticación
10. Sistema solicita a Openpay reintentar el cargo con 3DS habilitado: 
    ```json
    POST /v1/charges/{{TRANSACTION_ID}}/retry
    {
      "use_3d_secure": true,
      "redirect_url": "https://app.com/payments/3ds-callback/{{PAYMENT_ID}}"
    }
    ```
11. Openpay procesa solicitud y devuelve URL de autenticación actualizada
12. Sistema actualiza `payments. three_ds_status = 'authenticating'`
13. **Sistema muestra modal 3DS** (igual que UC-020)
14. Modal muestra mensaje de carga:
    ```
    🔒 Conectando con tu banco...
    
    Por favor espera un momento mientras cargamos 
    la página de autenticación de tu banco.
    ```
15. Modal/iframe carga página del banco emisor
16. **Página del banco se muestra en el modal**
17. Usuario ve opciones de autenticación:
    - Código por SMS
    - Confirmación en app bancaria  
    - Biometría (huella, Face ID)
18. Usuario selecciona método (ej: App bancaria)
19. Usuario abre app del banco en su móvil
20. App muestra notificación:  "Autorizar pago de $499.00 MXN"
21. Usuario revisa detalles del pago
22. Usuario confirma con biometría (huella o Face ID)
23. **App confirma autorización**
24. Banco notifica a Openpay que autenticación fue exitosa
25. Openpay procesa el cargo
26. **Openpay envía webhook `charge. succeeded`** al backend
27. Backend procesa webhook (valida firma)
28. Backend actualiza `payments`:
    - `status = 'completed'`
    - `three_ds_status = 'authenticated'`
    - `paid_at = NOW()`
29. Backend actualiza suscripción:
    - `status = 'active'`
    - `next_billing_date` = +1 mes o +1 año
30. Backend resetea tokens en `tokens_usage`
31. Backend cierra modal 3DS en frontend (vía WebSocket o polling)
32. **Frontend muestra mensaje de éxito:**
    ```
    ✅ ¡Pago completado exitosamente!
    
    Tu suscripción ha sido renovada. 
    
    Plan: Google Tech + IA 100
    Monto pagado: $499.00 MXN
    Tokens disponibles: 10,000
    Próximo cobro: 15 de febrero, 2026
    
    [Botón:  Ir a mi dashboard]
    ```
33. Sistema envía email de confirmación de pago (#2)
34. Usuario hace clic en "Ir a mi dashboard"
35. Sistema muestra dashboard con tokens renovados
36. Usuario puede continuar usando la plataforma normalmente

### Flujos Alternativos

**22a. Usuario rechaza/cancela en la app bancaria**
- 22a. 1. Usuario hace clic en "Rechazar" o "Cancelar" en app
- 22a. 2. Banco notifica a Openpay que autenticación fue rechazada
- 22a.3. Openpay envía webhook `charge.failed` con razón `user_cancelled`
- 22a.4. Backend actualiza `payments`:
  - `status = 'failed'`
  - `three_ds_status = 'failed'`
  - `error_message = 'User cancelled 3DS authentication'`
- 22a.5. Frontend cierra modal y muestra mensaje: 
    ```
    ❌ Autenticación cancelada
    
    Cancelaste la autorización del pago en tu banco.
    
    ¿Qué deseas hacer? 
    • Reintentar autenticación
    • Actualizar tarjeta de pago
    • Contactar soporte
    ```
- 22a.6. Usuario selecciona opción
- 22a.7. SI reintentar → CONTINÚA en paso 10
- 22a.8. SI actualizar tarjeta → Flujo de actualizar tarjeta (UC-020)
- 22a.9. SI contactar soporte → Abrir chat de soporte

**22b.  Timeout de autenticación (15 minutos en modal)**
- 22b.1.  Pasan 15 minutos sin respuesta del usuario
- 22b. 2. Modal muestra timeout: 
    ```
    ⏱️ Tiempo agotado
    
    La sesión de autenticación expiró por inactividad.
    
    ¿Deseas intentar de nuevo?
    ```
- 22b.3. Usuario hace clic en "Sí, intentar de nuevo"
- 22b.4. CONTINÚA en paso 10

**15a. Error al cargar página del banco**
- 15a. 1. Modal no puede cargar URL (error 500, timeout)
- 15a.2. Modal muestra error:
    ```
    ❌ Error de conexión
    
    No pudimos conectar con tu banco. 
    Esto puede ser un problema temporal.
    
    • Reintentar
    • Contactar soporte
    ```
- 15a.3. Usuario selecciona reintentar
- 15a.4. CONTINÚA en paso 10

**7a.  Pago ya fue procesado (usuario hace clic múltiple en email)**
- 7a.1. Sistema detecta `payments.status = 'completed'`
- 7a.2. Sistema muestra mensaje:
    ```
    ✅ Este pago ya fue completado
    
    Tu pago fue procesado exitosamente el [fecha]. 
    
    [Ir a mi dashboard]
    ```
- 7a.3. FIN del caso de uso

**7b. Pago ha expirado (más de 7 días)**
- 7b.1. Sistema detecta que pago fue creado hace más de 7 días
- 7b.2. Sistema muestra mensaje:
    ```
    ⚠️ Este intento de pago expiró
    
    Por favor contacta a soporte para resolver el estado 
    de tu suscripción.
    
    [Contactar soporte]
    ```
- 7b.3. FIN del caso de uso

**4a. Usuario accede desde otro dispositivo (no tiene sesión)**
- 4a.1. Usuario hace clic en link de email desde dispositivo diferente
- 4a.2. Sistema no encuentra sesión activa
- 4a.3. Sistema redirige a login con parámetro de retorno:  
    ```
    /login?return_to=/payments/authenticate/{{PAYMENT_ID}}
    ```
- 4a.4. Usuario ingresa credenciales
- 4a.5. Sistema autentica y redirige a página de autenticación de pago
- 4a. 6. CONTINÚA en paso 7

### Postcondiciones

**Éxito:**
- Pago completado con `status = 'completed'`
- Suscripción renovada con `status = 'active'`
- Tokens reseteados
- Email de confirmación enviado
- Usuario puede usar plataforma normalmente

**Fallo:**
- Pago permanece en `status = 'failed'`
- Usuario puede reintentar
- Si agota reintentos → Entra en período de gracia (UC-004)

### Reglas de Negocio
- RN-047: Usuario puede reintentar autenticación múltiples veces
- RN-048: Link de email es válido por 7 días
- RN-049: Usuario debe estar logueado para autenticar
- RN-050: Solo el usuario dueño del pago puede autenticarlo
- RN-051: Si pago ya fue completado → Mostrar mensaje confirmatorio

### Excepciones
- EX-016: Si usuario no recuerda contraseña → Flujo de recuperación de contraseña
- EX-017: Si banco está en mantenimiento → Mostrar mensaje y pedir reintentar más tarde

### Notas Adicionales
- **Tasa de éxito esperada:** 85-90% (de los que intentan)
- **Tiempo promedio:** 1-3 minutos
- Link debe funcionar en cualquier dispositivo (responsive)
- Considerar deep linking a app bancaria si usuario está en móvil

---

## UC-023: Aplicar Trial Personalizado (Admin)

**Identificador:** UC-023 🆕  
**Nombre:** Aplicar trial personalizado a suscripción  
**Actores:** Administrador, Sistema  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Admin ajusta manualmente el período de trial de un usuario (promoción, corrección, cliente especial).

### Precondiciones
- Admin autenticado con permisos
- Suscripción existe
- Usuario en estado `trial` o antes de activar suscripción

### Flujo Principal
1. Admin accede a panel de gestión de suscripciones
2. Busca usuario por email/ID
3. Selecciona "Ajustar Trial"
4. Sistema muestra:
   - Trial actual: X días (del plan)
   - Trial personalizado: NULL (sin personalización)
5. Admin ingresa nuevo valor: 60 días
6. Sistema valida (0-365 días)
7. Sistema actualiza `subscriptions.trial_days = 60`
8. Sistema recalcula `trial_ends_at = starts_at + 60 días`
9. Sistema registra en audit_logs
10. Sistema envía email al usuario notificando extensión
11. Usuario recibe 60 días de trial en lugar de 30

### Flujo Alternativo 1: Eliminar Trial
- En paso 5, admin ingresa `0`
- Sistema elimina trial → suscripción pasa a `active` inmediatamente
- Sistema intenta primer cobro

### Flujo Alternativo 2: Restaurar Trial del Plan
- En paso 5, admin selecciona "Usar trial del plan"
- Sistema actualiza `trial_days = NULL`
- Sistema recalcula `trial_ends_at` usando `plan.trial_days`

### Postcondiciones
- `subscriptions.trial_days` actualizado
- `subscriptions.trial_ends_at` recalculado
- Usuario notificado
- Audit log registrado

### Reglas de Negocio
- RN-052: Solo admin puede modificar trials manualmente
- RN-053: Valor válido: 0-365 días o NULL
- RN-054: Si trial ya expiró, no se puede extender (crear nueva suscripción)

### Excepciones
- EX-018: Si suscripción ya está activa → No permitir cambio de trial
- EX-019: Si valor fuera de rango → Mostrar error de validación

### Notas Adicionales
- Casos de uso comunes: promociones especiales, compensación por problemas técnicos
- Registrar justificación en audit_logs para cumplimiento

---

## UC-024: Ajustar Grace Period Personalizado (Admin)

**Identificador:** UC-024 🆕  
**Nombre:** Ajustar período de gracia personalizado  
**Actores:** Administrador, Sistema  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Admin ajusta manualmente el período de gracia para un cliente específico (premium, problemático, excepcional).

### Precondiciones
- Admin autenticado
- Suscripción existe
- Suscripción puede estar en cualquier estado

### Flujo Principal
1. Admin accede a configuración de suscripción
2. Busca usuario
3. Selecciona "Ajustar Grace Period"
4. Sistema muestra:
   - Grace period actual: 2 meses (config global)
   - Grace period personalizado: NULL
5. Admin ingresa nuevo valor: 6 meses (cliente premium)
6. Sistema valida (0-12 meses)
7. Sistema actualiza `subscriptions.grace_period_months = 6`
8. Sistema registra en audit_logs con justificación
9. Si hay grace period activo:
   - Sistema recalcula `grace_periods.ends_at`
   - Sistema actualiza fechas de recordatorios
10. Usuario tendrá 6 meses de gracia en futuros fallos de pago

### Flujo Alternativo: Sin Grace (Bloqueo Inmediato)
- En paso 5, admin ingresa `0`
- Sistema marca `grace_period_months = 0`
- En futuros fallos, suscripción pasa directamente a `blocked`

### Postcondiciones
- Grace period personalizado aplicado
- Audit log completo
- Si grace activo, fechas actualizadas

### Reglas de Negocio
- RN-055: Valor válido: 0-12 meses o NULL
- RN-056: 0 = bloqueo inmediato sin grace
- RN-057: NULL = usar config global (2 meses)
- RN-058: Cambios aplican a futuros grace periods, no retroactivos (excepto si ya hay uno activo)

### Excepciones
- EX-020: Si valor fuera de rango → Mostrar error de validación
- EX-021: Si grace period activo y se reduce tiempo → Confirmar con admin

### Notas Adicionales
- Casos de uso: clientes premium (mayor tolerancia), clientes problemáticos (menor tolerancia)
- Registrar justificación obligatoria en audit_logs

---

## UC-008: Aplicar cupón de descuento

**Identificador:** UC-008  
**Nombre:** Aplicar cupón de descuento  
**Actores:** Usuario, Sistema  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Usuario aplica un cupón de descuento al seleccionar un plan de suscripción.

### Precondiciones
- Usuario está en proceso de selección de plan
- Usuario tiene código de cupón válido

### Flujo Principal
1. Usuario selecciona plan deseado
2. Sistema muestra precio del plan y campo opcional "Código de cupón"
3. Usuario ingresa código de cupón (ej: `PROMO2026`)
4. Usuario hace clic en "Aplicar cupón"
5. Sistema valida cupón en backend (llamada API):
   - Cupón existe en tabla `coupons`
   - `active = true`
   - `expires_at IS NULL` OR `expires_at >= HOY`
   - `applicable_plans IS NULL` OR incluye el plan seleccionado
   - Usuario NO lo ha usado antes (verificar tabla `user_coupons`)
   - `current_usage < usage_limit` OR `usage_limit IS NULL`
6. **Cupón es válido**
7. Sistema calcula descuento según tipo: 
   - SI `type = 'percentage'` → Descuento = Precio × (value / 100)
   - SI `type = 'fixed'` → Descuento = value
8. Sistema muestra precio actualizado: 
   ```
   Plan: Google Tech + IA 100
   Precio original: $499.00 MXN/mes
   Cupón:  PROMO2026 (-20%)
   Descuento: -$99.80 MXN
   ─────────────────────────
   Precio final: $399.20 MXN/mes
   
   Duración del descuento: 3 meses
   Después del mes 3, pagarás $499.00 MXN
   ```
9. Usuario confirma y continúa con el pago
10. Sistema guarda cupón aplicado en `user_coupons`:
    - `user_id` = ID del usuario
    - `coupon_id` = ID del cupón
    - `applied_at` = NOW()
11. Sistema incrementa `coupons. current_usage` +1
12. Sistema aplica descuento en el cargo
13. Usuario paga monto con descuento
14. Sistema envía email de confirmación mencionando el descuento

### Flujos Alternativos

**6a.  Cupón no existe**
- 6a.1. Sistema no encuentra cupón con ese código
- 6a.2. Sistema muestra error:  "Cupón no encontrado"
- 6a.3. Usuario puede: 
  - Reintentar con otro código
  - Continuar sin cupón

**6b. Cupón inactivo**
- 6b. 1. Cupón existe pero `active = false`
- 6b.2. Sistema muestra error: "Este cupón ya no está disponible"

**6c. Cupón expirado**
- 6c.1. `expires_at < HOY`
- 6c.2. Sistema muestra error: "Este cupón expiró el [fecha]"

**6d. Cupón no aplica al plan seleccionado**
- 6d.1. `applicable_plans` no incluye el plan seleccionado
- 6d.2. Sistema muestra error: "Este cupón no aplica al plan seleccionado"
- 6d.3. Sistema puede sugerir planes aplicables

**6e. Usuario ya usó el cupón**
- 6e.1. Existe registro en `user_coupons` para este usuario y cupón
- 6e. 2. Sistema muestra error:  "Ya usaste este cupón anteriormente"

**6f. Cupón alcanzó límite de usos**
- 6f. 1. `current_usage >= usage_limit`
- 6f.2. Sistema muestra error: "Este cupón alcanzó su límite de usos"

**9a. Usuario quiere quitar el cupón antes de confirmar**
- 9a. 1. Usuario hace clic en "Quitar cupón" o ícono X
- 9a.2. Sistema recalcula precio sin descuento
- 9a. 3. Usuario puede aplicar otro cupón o continuar sin descuento

### Postcondiciones

**Éxito:**
- Cupón aplicado correctamente
- Descuento reflejado en el pago
- Registro en `user_coupons`
- `current_usage` del cupón incrementado

**Fallo:**
- Cupón no aplicado
- Usuario paga precio completo o puede intentar con otro cupón

### Reglas de Negocio
- RN-052: Usuario puede usar un cupón solo una vez
- RN-053: Solo un cupón activo por usuario a la vez
- RN-054: Cupones de duración temporal aplican por N meses, luego precio normal
- RN-055: Cupones permanentes aplican mientras mantenga suscripción
- RN-056: Código de cupón es case-insensitive (PROMO2026 = promo2026)

### Excepciones
- EX-018: Si usuario cancela y regresa, NO puede reusar el mismo cupón

---

## UC-009: Referir a un amigo

**Identificador:** UC-009  
**Nombre:** Referir a un amigo  
**Actores:** Referidor (usuario actual), Referido (nuevo usuario), Sistema  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Usuario invita a amigos mediante su código único de referido.  Ambos obtienen beneficios cuando el referido hace su primer pago.

### Precondiciones
- Usuario tiene suscripción activa
- Usuario accede a sección de referidos

### Flujo Principal
1. Usuario accede a "Referidos" desde su dashboard
2. Sistema muestra información del programa: 
   ```
   🎁 Invita a tus amigos y gana beneficios
   
   Por cada amigo que se suscriba usando tu código:
   
   Tú ganas: 
   • 20% de descuento en tu próximo mes
   • 1,000 tokens extra
   • $100 MXN de crédito
   
   Tu amigo gana:
   • 10% de descuento en su primer mes
   ```
3. Sistema genera o muestra código único del usuario:
   - Código:  `CESAR2026`
   - Link: `https://app.com/register?ref=abc123xyz`
4. Sistema muestra botones de compartir:
   - WhatsApp
   - Email
   - Copiar link
5. Usuario hace clic en "Compartir por WhatsApp"
6. Sistema genera mensaje pre-llenado:
   ```
   ¡Hola!   Te invito a probar [Plataforma],  
   una app genial para gestionar tu consultorio médico. 
   
   Usa mi código CESAR2026 o este link para obtener 10% de descuento:
   https://app.com/register?ref=abc123xyz
   
   ¡Espero que te sirva! 
   ```
7. Usuario comparte mensaje por WhatsApp con su amigo
8. **Amigo recibe mensaje y hace clic en el link**
9. Sistema abre página de registro con parámetro `? ref=abc123xyz`
10. Sistema valida código de referido:
    - Código existe en tabla `referrals`
    - Referidor está activo
    - Código no ha expirado
11. Sistema muestra banner en página de registro:
    ```
    🎁 ¡Tienes un descuento! 
    
    Tu amigo César te invitó.   
    Obtén 10% de descuento en tu primer mes.
    ```
12. Amigo completa registro normal (UC-001)
13. Sistema crea registro en `referrals`:
    - `referrer_id` = ID de César
    - `referred_id` = ID del amigo
    - `code` = CESAR2026
    - `status = 'pending'`
    - `referrer_benefit` = JSON con beneficios
    - `referred_benefit` = JSON con descuento 10%
14. Amigo activa trial y usa la plataforma
15. **Amigo hace su primer pago** (al finalizar trial)
16. Sistema detecta pago exitoso de usuario referido
17. Sistema actualiza `referrals.status = 'completed'`
18. Sistema actualiza `referrals.completed_at = NOW()`
19. **Sistema otorga beneficios al REFERIDOR (César):**
    - Crea cupón de 20% por 1 mes
    - Agrega 1,000 tokens extra a su cuenta (registro en tabla separada)
    - Agrega $100 MXN de crédito para futuras facturas
20. **Sistema otorga beneficio al REFERIDO (amigo):**
    - Aplica descuento de 10% en su primer cobro
21. Sistema envía email al referidor (#10):
    ```
    🎉 ¡Tu amigo se suscribió! 
    
    Tu amigo Juan completó su primer pago. 
    
    Tus beneficios ya están disponibles:
    • 20% de descuento en tu próximo cobro
    • 1,000 tokens extra agregados a tu cuenta
    • $100 MXN de crédito disponible
    
    ¡Gracias por compartir! 
    ```
22. Sistema envía email al referido (#11):
    ```
    ¡Gracias por unirte! 
    
    Tu descuento del 10% ya fue aplicado.
    Pagarás $[monto] en lugar de $[monto_original].
    
    ¡Disfruta la plataforma!
    ```
23. Referidor ve en su dashboard de referidos: 
    - Total referidos: 5
    - Beneficios ganados: $500 MXN
    - Tokens extra: 5,000

### Flujos Alternativos

**10a.  Código de referido no es válido**
- 10a.1. Código no existe o está expirado
- 10a. 2. Sistema ignora el parámetro
- 10a.3. Registro continúa normalmente sin beneficios

**15a. Amigo cancela trial sin pagar**
- 15a.1. Trial expira sin conversión a pago
- 15a.2. Sistema actualiza `referrals.status = 'expired'`
- 15a.3. NO se otorgan beneficios a ninguno
- 15a.4. FIN del caso de uso

**15b. Amigo paga pero el pago falla**
- 15b. 1. Primer intento de pago falla
- 15b.2. Sistema espera a que pago sea exitoso (reintentos)
- 15b.3. SI pago eventualmente es exitoso → CONTINÚA en paso 17
- 15b.4. SI todos los reintentos fallan → CONTINÚA en 15a.2

**19a. Referidor alcanzó límite de referidos**
- 19a.1. `referrals` WHERE `referrer_id` = César COUNT >= límite configurado (ej: 10)
- 19a.2. Sistema NO permite más referidos
- 19a. 3. Sistema oculta opción de referir en dashboard
- 19a.4. Link de referido muestra mensaje:   "Este usuario alcanzó su límite de referidos"

### Postcondiciones

**Referido paga:**
- Registro en `referrals` con `status = 'completed'`
- Beneficios otorgados a ambos
- Emails de confirmación enviados

**Referido no paga:**
- Registro en `referrals` con `status = 'expired'`
- Sin beneficios

### Reglas de Negocio
- RN-057: Beneficios se otorgan solo al PRIMER pago del referido
- RN-058: Un usuario referido solo puede usar un código (no múltiples)
- RN-059: Referidor puede invitar múltiples amigos (hasta límite configurable)
- RN-060: Código de referido es único por usuario y permanente
- RN-061: Beneficios son configurables por admin

### Excepciones
- EX-019: Si referido ya tenía cuenta → Código no aplica

## UC-010: Consumo de tokens y alertas

**Identificador:** UC-010  
**Nombre:** Consumo de tokens y alertas automáticas  
**Actores:** Usuario, Sistema  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Usuario consume tokens al utilizar funcionalidades de IA y recibe alertas automáticas cuando alcanza ciertos umbrales de consumo. 

### Precondiciones
- Usuario tiene suscripción activa
- Usuario tiene tokens disponibles en el período actual

### Flujo Principal
1. Usuario accede a funcionalidad que consume tokens (ej: análisis de IA)
2. Sistema verifica tokens disponibles:  
   - Consulta `tokens_usage` WHERE `user_id` = usuario AND `period_end >= HOY`
   - Calcula:  `disponibles = total - used`
3. SI `disponibles > 0`:
4. Sistema ejecuta funcionalidad solicitada
5. Sistema incrementa `tokens_usage. used` +N (según tokens que consume la funcionalidad)
6. Sistema calcula porcentaje consumido:  `(used / total) * 100`
7. **Sistema verifica umbrales de alerta:**
8. SI porcentaje >= 50% AND no se ha enviado alerta de 50%:
   - Sistema envía Email #13 (Tokens 50%)
   - Sistema registra en `notifications` que se envió alerta
9. SI porcentaje >= 75% AND no se ha enviado alerta de 75%:
   - Sistema envía Email #14 (Tokens 75%)
   - Sistema registra notificación
10. SI porcentaje >= 90% AND no se ha enviado alerta de 90%:
    - Sistema envía Email #15 (Tokens 90%)
    - Sistema registra notificación
11. SI porcentaje >= 100%:
    - Sistema envía Email #16 (Tokens 100% - sin tokens)
    - Sistema bloquea funcionalidades que consumen tokens
    - Sistema muestra mensaje: 
      ```
      ⚠️ Sin tokens disponibles
      
      Agotaste tus 10,000 tokens de este mes.
      
      Opciones: 
      • Espera hasta el 15 de febrero para renovación automática
      • Haz upgrade ahora para obtener más tokens inmediatamente
      
      [Botón:  Ver planes superiores]
      ```
    - Sistema registra notificación
12. Sistema muestra en dashboard barra de progreso actualizada:
    ```
    Tokens del mes
    ████████░░ 8,500 / 10,000 (85%)
    
    Próxima renovación: 15 de febrero
    ```
13. Usuario puede continuar usando funcionalidades que NO consumen tokens

### Flujos Alternativos

**3a. Usuario sin tokens disponibles**
- 3a. 1. Sistema detecta `disponibles = 0`
- 3a.2. Sistema muestra mensaje de tokens agotados (paso 11)
- 3a.3. Sistema bloquea ejecución de funcionalidad
- 3a.4. Usuario puede: 
  - Esperar renovación
  - Hacer upgrade inmediato (UC-006)

**7a. Usuario hace upgrade durante el mes**
- 7a.1.  Tokens se resetean a plan nuevo (UC-006)
- 7a.2.  Alertas de tokens se resetean (pueden enviarse de nuevo)

### Postcondiciones

**Consumo normal:**
- Tokens decrementados correctamente
- Alertas enviadas según umbrales
- Usuario notificado oportunamente

**Tokens agotados:**
- Funcionalidades de IA bloqueadas
- Usuario sabe cuándo se renuevan
- Opción de upgrade disponible

### Reglas de Negocio
- RN-062: Alertas se envían solo una vez por umbral por período
- RN-063: Tokens se resetean el primer día del período de facturación
- RN-064: Tokens no usados NO se acumulan (se pierden)
- RN-065: Al agotar tokens, usuario mantiene acceso a funcionalidades básicas

### Excepciones
- EX-020: Si cálculo de tokens falla → No bloquear funcionalidad, registrar error y notificar admin

### Notas Adicionales
- Actualización de tokens debe ser en tiempo real (no batch)
- Barra de progreso debe ser visual y clara
- Emails de alerta deben ser informativos, no alarmantes

---

## UC-011: Solicitar factura electrónica

**Identificador:** UC-011  
**Nombre:** Solicitar factura electrónica  
**Actores:** Usuario, Sistema, Admin  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Usuario solicita factura electrónica de un pago realizado dentro del límite de tiempo permitido.

### Precondiciones
- Usuario completó un pago
- Pago está dentro del límite de tiempo para facturación: 
  - **México:** Mismo mes del pago
  - **Colombia:** Hasta 5 días después del pago
- Usuario tiene datos fiscales completos

### Flujo Principal
1. Usuario accede a sección "Facturas" desde su dashboard
2. Sistema muestra historial de pagos del usuario
3. Sistema indica qué pagos son facturable:
   ```
   Historial de pagos
   
   ✅ 15 ene 2026 - $499.00 MXN - [Solicitar factura]
   ⏱️ 10 ene 2026 - $299.00 MXN - [Solicitar factura] (vence 31 ene)
   ❌ 20 dic 2025 - $499.00 MXN - Fuera de tiempo
   📄 15 dic 2025 - $499.00 MXN - Factura disponible [Descargar]
   ```
4. Usuario hace clic en "Solicitar factura" de un pago específico
5. Sistema verifica límite de tiempo:  
   - **México:** `payment. created_at >= primer día del mes actual`
   - **Colombia:** `payment.created_at >= HOY - 5 días`
6. **Límite válido**
7. Sistema verifica datos fiscales en tabla `billing_data`
8. SI datos fiscales están completos:
   - CONTINÚA en paso 12
9. SI datos fiscales están incompletos: 
10. Sistema muestra formulario de datos fiscales según país
11. Usuario completa datos fiscales y guarda
12. Sistema muestra resumen de factura a solicitar:
    ```
    Solicitud de factura
    
    Pago: 15 de enero, 2026
    Monto: $499.00 MXN
    Plan: Google Tech + IA 100
    
    Datos fiscales:
    RFC:  XAXX010101000
    Razón social:  Empresa SA de CV
    Régimen:  612
    Uso CFDI: G03
    
    La factura se enviará a:  usuario@email.com
    
    [Confirmar solicitud]
    ```
13. Usuario confirma solicitud
14. Sistema crea registro en tabla `invoices`:
    - `user_id` = ID del usuario
    - `payment_id` = ID del pago
    - `status = 'requested'`
    - `requested_at = NOW()`
    - `sent_at = NULL`
    - `file_url = NULL`
15. Sistema envía email de confirmación al usuario:
    ```
    📧 Email:   Solicitud de factura recibida
    
    Hola [Nombre],
    
    Recibimos tu solicitud de factura para el pago de $499.00 MXN 
    del 15 de enero. 
    
    Tu factura será generada en las próximas 24-48 horas y te la 
    enviaremos a este mismo correo. 
    
    Gracias por tu paciencia.
    ```
16. Sistema notifica a admin (email o dashboard) de nueva solicitud pendiente
17. **Admin genera factura en sistema externo:**
    - **México:** PAC (ej: Facturama, FacturAPI)
    - **Colombia:** Plataforma DIAN (ej: Siigo, Alegra)
18. Admin descarga PDF de la factura generada
19. Admin accede a panel de facturas pendientes en admin dashboard
20. Admin selecciona solicitud pendiente
21. Admin sube PDF de factura al sistema (formulario de upload)
22. Sistema guarda archivo en storage:  `/storage/invoices/2026/01/invoice_123.pdf`
23. Sistema actualiza registro en `invoices`:
    - `file_url = '/storage/invoices/2026/01/invoice_123.pdf'`
    - `sent_at = NOW()`
    - `status = 'completed'`
24. **Sistema envía email al usuario con factura adjunta (#12):**
    ```
    📧 Email:  Tu factura está lista
    
    Hola [Nombre],
    
    Tu factura ya está disponible. 
    
    Adjunto: invoice_123.pdf
    
    También puedes descargarla desde tu panel en cualquier momento.
    
    [Descargar factura]
    ```
25. Usuario recibe email, descarga factura
26. Usuario puede volver a descargar desde su panel en cualquier momento

### Flujos Alternativos

**5a. Solicitud fuera del límite de tiempo**
- 5a.1. Sistema detecta que pago está fuera del límite
- 5a.2. Sistema muestra mensaje: 
   ```
   ❌ Fuera de tiempo
   
   México: Las facturas deben solicitarse en el mismo mes del pago. 
   Este pago fue el 20 de diciembre y ya estamos en enero.
   
   Por favor contacta a soporte si necesitas ayuda.
   ```
- 5a.3. FIN del caso de uso

**17a. Error al generar factura en sistema externo**
- 17a.1. PAC/DIAN devuelve error (datos incorrectos, servicio caído, etc.)
- 17a.2. Admin marca solicitud como `status = 'failed'`
- 17a.3. Admin contacta al usuario para corregir datos
- 17a.4. Usuario corrige datos fiscales
- 17a.5. Admin reintenta generación
- 17a.6. CONTINÚA en paso 18

### Postcondiciones

**Éxito:**
- Factura generada y entregada
- Registro en `invoices` con `status = 'completed'`
- PDF disponible para descarga indefinida

**Fallo (fuera de tiempo):**
- Solicitud rechazada
- Usuario informado del motivo

### Reglas de Negocio
- RN-066: Límite México:  Mismo mes del pago
- RN-067: Límite Colombia:  5 días hábiles después del pago
- RN-068: Datos fiscales deben estar completos antes de solicitar
- RN-069: Factura se genera externamente (PAC en MX, DIAN en CO)
- RN-070: PDF se guarda indefinidamente para re-descarga

### Excepciones
- EX-021: Si servicio de PAC/DIAN está caído → Notificar usuario que habrá retraso

### Notas Adicionales
- Tiempo de generación: 24-48 horas típicamente
- Considerar integración API con PAC/DIAN para automatizar (reduce carga de admin)

---

## UC-012: Cancelación de suscripción

**Identificador:** UC-012  
**Nombre:** Cancelación de suscripción  
**Actores:** Usuario, Sistema  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Usuario decide cancelar su suscripción.  El acceso se mantiene hasta el fin del período pagado.

### Precondiciones
- Usuario tiene suscripción activa (`status = 'active'`)

### Flujo Principal
1. Usuario accede a "Configuración de suscripción" desde su perfil
2. Sistema muestra información actual: 
   ```
   Tu suscripción actual
   
   Plan: Google Tech + IA 100
   Precio: $499.00 MXN/mes
   Próximo cobro: 15 de febrero, 2026
   Tokens:  3,500 / 10,000 usados
   
   [Botón: Cancelar suscripción]
   ```
3. Usuario hace clic en "Cancelar suscripción"
4. Sistema muestra modal de confirmación con advertencias:
   ```
   ⚠️ ¿Estás seguro de cancelar? 
   
   Si cancelas: 
   • Mantendrás acceso hasta el 15 de febrero
   • Podrás usar tus 6,500 tokens restantes
   • NO se cobrará tu próximo pago
   • Tus datos se conservarán por 90 días por si decides regresar
   
   Queremos mejorar:  ¿Por qué cancelas?  (opcional)
   [ ] Muy caro
   [ ] No uso todas las funcionalidades
   [ ] Encontré otra opción
   [ ] Otro:  ___________
   
   [Cancelar suscripción]  [No, mantener suscripción]
   ```
5. Usuario opcionalmente selecciona razón de cancelación
6. Usuario confirma cancelación
7. **Sistema verifica tipo de plan:**
8. SI plan es Mensual o Anual (sin compromiso):
   - CONTINÚA en paso 9
9. Sistema actualiza suscripción: 
   - `status = 'cancelled'`
   - `ends_at` = fecha del próximo cobro original
   - `next_billing_date = NULL` (no habrá más cobros)
10. Sistema registra razón de cancelación en tabla `audit_logs` (si se proporcionó)
11. Sistema envía Email #8 (Cancelación de suscripción):
    ```
    📧 Lamentamos verte partir
    
    Hola [Nombre],
    
    Confirmamos la cancelación de tu suscripción. 
    
    Todavía tienes acceso completo hasta:  15 de febrero, 2026
    Tokens disponibles: 6,500
    
    Si cambias de opinión, puedes reactivar tu suscripción antes 
    del 15 de febrero sin perder tu plan actual.
    
    Después del 15 de febrero, deberás crear una nueva suscripción.
    
    ¿Nos ayudas?  Comparte tu feedback:  [Encuesta]
    
    Gracias por haber sido parte de [Plataforma]. 
    ```
12. Usuario sigue usando plataforma normalmente hasta `ends_at`
13. **En la fecha `ends_at`:**
14. CronJob diario detecta suscripciones con `status = 'cancelled'` AND `ends_at = HOY`
15. Sistema bloquea acceso del usuario
16. Sistema muestra mensaje en login:
    ```
    Tu suscripción expiró el 15 de febrero
    
    ¿Quieres regresar? 
    • Ver planes disponibles
    • Contactar soporte
    ```

### Flujos Alternativos

**8a. Plan Anual con cobros mensuales (con compromiso de 12 meses)**
- 8a.1. Sistema detecta `periodicity = 'annual_monthly_billing'`
- 8a.2. Sistema calcula meses restantes del compromiso
- 8a.3. Sistema muestra advertencia especial:
    ```
    ⚠️ Plan anual con compromiso
    
    Tu plan tiene un compromiso de 12 meses.
    Meses completados: 4 / 12
    Meses restantes: 8
    
    Si cancelas:
    • Debes pagar los 8 meses restantes ($3,992.00 MXN total)
    • O puedes mantener la suscripción y seguir usando el servicio
    
    ¿Qué prefieres?
    • Pagar meses restantes y cancelar
    • Mantener suscripción activa
    ```
- 8a.4. Usuario decide
- 8a.5. SI decide pagar → Sistema genera cargo de penalización
- 8a.6. SI decide mantener → Cancela el proceso de cancelación

**12a. Usuario reactiva antes de `ends_at`**
- 12a.1. Usuario accede a perfil antes de que expire
- 12a.2. Sistema muestra opción "Reactivar suscripción"
- 12a.3. Usuario hace clic
- 12a.4. Sistema actualiza: 
  - `status = 'active'`
  - `ends_at = NULL`
  - `next_billing_date` = fecha original de cobro
- 12a.5. Sistema envía email de reactivación (#19)
- 12a.6. Próximo cobro ocurre normalmente

### Postcondiciones

**Cancelación exitosa:**
- `status = 'cancelled'`
- Acceso mantenido hasta `ends_at`
- No más cobros programados
- Datos conservados 90 días

**Reactivación:**
- `status = 'active'`
- Cobros se reanudan
- Mismo plan mantenido

### Reglas de Negocio
- RN-071: Cancelación NO es inmediata (acceso hasta fin de período pagado)
- RN-072: Usuario puede reactivar antes de `ends_at` sin crear nueva suscripción
- RN-073: Después de `ends_at`, debe crear nueva suscripción (puede perder precio/descuentos)
- RN-074: Plan anual con compromiso requiere pago de meses restantes
- RN-075: Datos se conservan 90 días después de `ends_at`

### Excepciones
- EX-022: Si usuario está en período de gracia → Cancelar limpia la deuda

### Notas Adicionales
- Tasa de reactivación antes de `ends_at`: 15-20%
- Encuesta de salida es valiosa para mejoras del producto

---

## UC-013: Reactivación después de bloqueo

**Identificador:** UC-013  
**Nombre:** Reactivación después de bloqueo por falta de pago  
**Actores:** Usuario, Sistema, Openpay  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Usuario bloqueado por falta de pago (después de período de gracia) puede reactivar su suscripción pagando la deuda acumulada.

### Precondiciones
- Suscripción con `status = 'blocked'`
- Existe registro en `grace_periods` con deuda acumulada
- Usuario quiere reactivar el servicio

### Flujo Principal
1. Usuario intenta acceder a la plataforma
2. Sistema detecta `subscriptions. status = 'blocked'`
3. Sistema muestra página de bloqueo:
   ```
   ⚠️ Suscripción bloqueada por falta de pago
   
   Tu acceso fue bloqueado por pagos pendientes.
   
   Deuda acumulada: $998.00 MXN (2 meses)
   • Enero 2026: $499.00 MXN
   • Febrero 2026: $499.00 MXN
   
   Para reactivar tu suscripción, debes pagar el monto adeudado.
   
   [Pagar y reactivar]  [Contactar soporte]
   ```
4. Usuario hace clic en "Pagar y reactivar"
5. Sistema muestra opciones de pago:
   ```
   Monto a pagar: $998.00 MXN
   
   Método de pago:
   • Tarjeta de crédito/débito guardada (****  1234)
   • Actualizar tarjeta
   • Transferencia bancaria
   ```
6. Usuario selecciona "Tarjeta guardada"
7. Sistema confirma: 
   ```
   ¿Confirmas el pago de $998.00 MXN con tu tarjeta?
   
   Esto cubrirá tu deuda y reactivará tu suscripción. 
   Tu próximo cobro será el 15 de marzo por $499.00 MXN.
   
   [Confirmar pago]
   ```
8. Usuario confirma
9. Sistema solicita cargo a Openpay por monto total de deuda
10. **Puede requerir 3DS** (ver UC-020)
11. Usuario completa autenticación si es requerida
12. **Cargo exitoso**
13. Sistema actualiza `grace_periods`:
    - Marca como pagado (o elimina registro)
14. Sistema crea registros en `payments` por cada mes adeudado
15. Sistema actualiza suscripción:
    - `status = 'active'`
    - `next_billing_date` = HOY + 1 mes (o según periodicidad)
16. Sistema resetea tokens en `tokens_usage`
17. Sistema envía Email #19 (Reactivación):
    ```
    📧 ¡Bienvenido de vuelta! 
    
    Hola [Nombre],
    
    Tu suscripción ha sido reactivada exitosamente.
    
    Pago recibido: $998.00 MXN
    Plan: Google Tech + IA 100
    Tokens disponibles: 10,000
    Próximo cobro: 15 de marzo, 2026
    
    ¡Nos alegra tenerte de vuelta!
    ```
18. Usuario puede acceder a la plataforma inmediatamente

### Flujos Alternativos

**6a. Usuario selecciona "Actualizar tarjeta"**
- 6a.1. Usuario ingresa nueva tarjeta
- 6a.2. Pasa por flujo 3DS (UC-020)
- 6a.3. CONTINÚA en paso 9 con nueva tarjeta

**6b. Usuario selecciona "Transferencia bancaria"**
- 6b.1. Sistema genera orden de pago manual (UC-005)
- 6b.2. Usuario paga por transferencia
- 6b.3. Admin confirma pago
- 6b.4.  CONTINÚA en paso 13

**12a.  Cargo rechazado**
- 12a.1. Openpay rechaza cargo (fondos, tarjeta expirada, etc.)
- 12a.2. Sistema muestra error:
    ```
    ❌ No se pudo procesar el pago
    
    Razón: [Fondos insuficientes / Tarjeta inválida]
    
    ¿Qué deseas hacer?
    • Intentar con otra tarjeta
    • Pagar con transferencia
    • Contactar soporte
    ```
- 12a.3. Usuario selecciona opción
- 12a.4. Sistema procesa según selección

**12b. Usuario solo puede pagar parcialmente**
- 12b. 1. Usuario contacta soporte
- 12b.2. Soporte puede ofrecer plan de pagos (discrecional)
- 12b.3. Usuario paga primer monto
- 12b. 4. Sistema reactiva con acuerdo de pago del resto
- 12b.5. Sistema programa cobros de meses restantes

### Postcondiciones

**Éxito:**
- Deuda saldada
- Suscripción reactivada con `status = 'active'`
- Tokens disponibles
- Próximo cobro programado
- Usuario puede usar plataforma

**Fallo:**
- Deuda permanece
- `status = 'blocked'`
- Usuario sin acceso

### Reglas de Negocio
- RN-076: Reactivación requiere pago COMPLETO de deuda acumulada
- RN-077: Después de reactivar, próximo cobro es en 1 mes (período completo)
- RN-078: Tokens se resetean a cantidad del plan al reactivar
- RN-079: Plan de pagos parciales es discrecional de soporte

### Excepciones
- EX-023: Si deuda es muy grande (>6 meses) → Ofrecer descuento especial o plan de pagos

### Notas Adicionales
- Tasa de reactivación:   30-40% de usuarios bloqueados
- Ofrecer incentivos (ej: 1 mes gratis) puede mejorar conversión

---

## UC-014: Admin - Gestionar plan de usuario

**Identificador:** UC-014  
**Nombre:** Admin - Gestionar plan de usuario manualmente  
**Actores:** Admin, Sistema  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Administrador puede cambiar el plan de un usuario, ajustar tokens, cancelar o reactivar suscripciones desde el panel admin.

### Precondiciones
- Admin está logueado en panel de administración
- Admin tiene permisos de "Superadmin" o "Admin"

### Flujo Principal
1. Admin accede a panel de administración
2. Admin navega a sección "Gestión de Usuarios"
3. Admin busca usuario por email, nombre o ID
4. Sistema muestra lista de resultados
5. Admin selecciona usuario específico
6. Sistema muestra detalle completo del usuario: 
   ```
   Usuario: Juan Pérez (juan@email.com)
   País: México
   Rol: Profesional
   
   Suscripción actual:
   Plan: Google Tech + IA 100
   Estado: Activo
   Próximo cobro: 15 de febrero ($499.00 MXN)
   Tokens: 7,500 / 10,000 usados
   
   Historial de pagos:  [Ver todos]
   Facturas: [Ver todas]
   
   Acciones:
   [Cambiar plan] [Ajustar tokens] [Cancelar suscripción] 
   [Reactivar] [Ver historial]
   ```
7. Admin hace clic en "Cambiar plan"
8. Sistema muestra formulario: 
   ```
   Cambiar plan de usuario
   
   Plan actual: Google Tech + IA 100 ($499/mes)
   
   Nuevo plan:   [Dropdown con todos los planes]
   Aplicar:  
   • Inmediatamente (cobra/devuelve prorrata)
   • En próxima renovación
   
   Razón (opcional): ______________
   
   [Guardar cambio]
   ```
9. Admin selecciona nuevo plan:  "Google Tech + IA 200"
10. Admin selecciona "Inmediatamente"
11. Sistema calcula prorrata automáticamente y muestra:
    ```
    Resumen del cambio:
    
    Plan actual: Google Tech + IA 100 ($499/mes)
    Nuevo plan: Google Tech + IA 200 ($899/mes)
    Días restantes: 20
    
    Cargo adicional: $266.67 (prorrata 20 días)
    Tokens actuales: 7,500 / 10,000
    Tokens después: 0 / 20,000
    
    ⚠️ Esto generará un cargo inmediato en la tarjeta del usuario. 
    
    [Confirmar cambio]  [Cancelar]
    ```
12. Admin confirma cambio
13. Sistema procesa:
    - Solicita cargo de prorrata a Openpay
    - Actualiza `subscriptions.plan_id`
    - Resetea tokens en `tokens_usage`
    - Registra acción en `audit_logs`:
      - `user_id` = ID del admin
      - `action = 'plan_change_admin'`
      - `entity = 'subscription'`
      - `before` = JSON del plan anterior
      - `after` = JSON del plan nuevo
14. Sistema envía email al usuario notificando el cambio: 
    ```
    📧 Cambio en tu suscripción
    
    Hola Juan,
    
    Tu plan fue actualizado por nuestro equipo de soporte.
    
    Plan anterior: Google Tech + IA 100
    Plan nuevo: Google Tech + IA 200
    
    Tokens disponibles: 20,000
    Cargo procesado: $266.67 MXN
    Próximo cobro: 15 de febrero ($899.00 MXN)
    
    Si tienes dudas, contacta a soporte.
    ```
15. Sistema muestra confirmación al admin:
    ```
    ✅ Plan cambiado exitosamente
    
    Usuario: Juan Pérez
    Nuevo plan: Google Tech + IA 200
    Cargo procesado: $266.67 MXN
    
    [Ver detalle del usuario]
    ```

### Flujos Alternativos

**10a. Admin selecciona "En próxima renovación"**
- 10a.1. Sistema no cobra prorrata
- 10a. 2. Sistema programa cambio igual que downgrade de usuario (UC-007)
- 10a.3. `pending_plan_id` = nuevo plan
- 10a.4. Usuario mantiene plan actual hasta renovación

**13a.  Cargo de prorrata falla**
- 13a.1.  Openpay rechaza cargo
- 13a.2. Sistema muestra error al admin
- 13a.3. Admin puede: 
  - Aplicar cambio sin cobrar (perdona prorrata)
  - Programar para próxima renovación
  - Contactar al usuario para actualizar tarjeta

**7a. Admin selecciona "Ajustar tokens manualmente"**
- 7a.1. Sistema muestra formulario: 
    ```
    Ajustar tokens de Juan Pérez
    
    Tokens actuales: 7,500 / 10,000 usados
    
    Nueva cantidad: 
    • Usados: [____]
    • Total: [____]
    
    Razón: _______________
    (Ej: Compensación por error, Bono especial)
    
    [Guardar ajuste]
    ```
- 7a.2. Admin ingresa nuevos valores
- 7a.3. Sistema actualiza `tokens_usage`
- 7a.4. Sistema registra en `audit_logs`
- 7a.5. Opcionalmente envía email al usuario

**7b. Admin selecciona "Cancelar suscripción"**
- 7b.1. Flujo similar a UC-012 pero iniciado por admin
- 7b.2. Admin puede indicar razón
- 7b.3. Sistema notifica al usuario

**7c. Admin selecciona "Reactivar"**
- 7c.1. Si suscripción está bloqueada o cancelada
- 7c.2. Admin puede reactivar sin requerir pago (discrecional)
- 7c.3. Sistema actualiza `status = 'active'`
- 7c.4. Sistema resetea tokens
- 7c.5. Sistema notifica al usuario

### Postcondiciones

**Éxito:**
- Cambio aplicado correctamente
- Usuario notificado
- Acción registrada en auditoría
- Cargo procesado si aplica

**Fallo:**
- Cambio no aplicado
- Admin notificado del error
- Usuario no afectado

### Reglas de Negocio
- RN-080: Admin puede hacer cambios que usuario no puede (ej: cambiar sin cobro)
- RN-081: Todas las acciones de admin deben quedar en `audit_logs`
- RN-082: Razón del cambio es opcional pero recomendada
- RN-083: Usuario siempre debe ser notificado de cambios en su cuenta

### Excepciones
- EX-024: Solo Superadmin y Admin tienen estos permisos (no Soporte ni Finanzas)

### Notas Adicionales
- Admin debe poder ver historial completo de cambios previos
- Interfaz debe ser clara para evitar errores

---

## UC-015: Admin - Crear cupón de descuento

**Identificador:** UC-015  
**Nombre:** Admin - Crear cupón de descuento  
**Actores:** Admin, Sistema  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Administrador crea cupones de descuento para campañas de marketing o casos especiales.

### Precondiciones
- Admin está logueado con permisos de "Superadmin" o "Admin"

### Flujo Principal
1. Admin accede a panel admin → Sección "Cupones"
2. Admin hace clic en "Crear nuevo cupón"
3. Sistema muestra formulario:
   ```
   Crear cupón de descuento
   
   Código:  [________] (Ejemplo: PROMO2026)
   
   Tipo de descuento:
   • Porcentaje: [__]%
   • Monto fijo: $[____] [MXN/COP]
   
   Duración: 
   • Permanente (mientras mantenga suscripción)
   • Temporal:  [__] meses
   
   Aplica a:
   • Todos los planes
   • Planes específicos:  [Checkboxes de planes]
   
   Límites:
   • Usos totales: [____] (vacío = ilimitado)
   • Fecha de expiración: [____] (opcional)
   
   Estado: [Activo / Inactivo]
   
   [Crear cupón]
   ```
4. Admin completa formulario:
   - Código:  `VERANO2026`
   - Tipo: Porcentaje 25%
   - Duración:  3 meses
   - Aplica a: Todos los planes
   - Límite: 100 usos
   - Expira: 31 de marzo, 2026
   - Estado: Activo
5. Sistema valida: 
   - Código es único (no existe otro con mismo código)
   - Código es alfanumérico (sin espacios ni caracteres especiales)
   - Valor es positivo
   - Si duración es temporal, meses > 0
   - Si hay límite de usos, número > 0
6. **Validaciones exitosas**
7. Sistema crea registro en tabla `coupons`:
   ```sql
   INSERT INTO coupons (
     code, type, value, duration_months, 
     applicable_plans, usage_limit, current_usage,
     expires_at, active
   ) VALUES (
     'VERANO2026', 'percentage', 25.00, 3,
     NULL, 100, 0,
     '2026-03-31', true
   );
   ```
8. Sistema registra acción en `audit_logs`
9. Sistema muestra confirmación:
   ```
   ✅ Cupón creado exitosamente
   
   Código: VERANO2026
   Descuento:  25% por 3 meses
   Usos:  0 / 100
   Expira: 31 de marzo, 2026
   Estado: Activo
   
   Link para compartir: 
   https://app.com/register?coupon=VERANO2026
   
   [Copiar código] [Ver todos los cupones]
   ```
10. Admin puede copiar código para compartir en marketing

### Flujos Alternativos

**5a.  Código ya existe**
- 5a. 1. Sistema detecta código duplicado
- 5a.2. Sistema muestra error: "Este código ya existe.  Elige otro."
- 5a.3. Admin modifica código
- 5a. 4. CONTINÚA en paso 5

**5b.  Validación falla (valor negativo, formato incorrecto)**
- 5b.1. Sistema muestra mensajes de error específicos por campo
- 5b.2. Admin corrige
- 5b.3. CONTINÚA en paso 5

**10a. Admin quiere generar códigos únicos en lote**
- 10a. 1. Admin hace clic en "Generar códigos en lote"
- 10a.2. Sistema muestra formulario:
    ```
    Generar cupones en lote
    
    Cantidad:  [__] cupones
    Prefijo: [____] (Ej: PROMO-)
    
    Configuración (aplica a todos):
    • Tipo: [Porcentaje / Monto fijo]
    • Valor: [__]
    • Duración: [__] meses
    • Un uso por cupón
    • Expira: [____]
    
    [Generar]
    ```
- 10a.3. Admin completa y confirma
- 10a.4. Sistema genera N cupones con códigos únicos (ej:  PROMO-AB12, PROMO-CD34...)
- 10a.5. Sistema permite descargar CSV con todos los códigos

### Postcondiciones

**Éxito:**
- Cupón creado en tabla `coupons`
- Cupón disponible para uso inmediato
- Acción registrada en auditoría
- Admin puede compartir código

**Fallo:**
- Cupón no creado
- Errores de validación mostrados

### Reglas de Negocio
- RN-084: Códigos son case-insensitive al validar
- RN-085: Códigos deben ser únicos en el sistema
- RN-086: Un cupón puede tener múltiples restricciones (planes, límite, fecha)
- RN-087: Admin puede crear cupones de un solo uso (usage_limit = 1)

### Excepciones
- EX-025: Solo Admin y Superadmin pueden crear cupones

### Notas Adicionales
- Considerar analytics de cupones (tasa de conversión, ingresos generados)
- Admin debe poder editar cupones existentes (con precaución si ya están en uso)

---

## UC-016: Admin - Procesar reembolso

**Identificador:** UC-016  
**Nombre:** Admin - Procesar reembolso  
**Actores:** Admin, Sistema, Openpay  
**Prioridad:** Media  
**Estado:** Activo  

### Descripción
Admin procesa un reembolso para un pago realizado por un usuario.

### Precondiciones
- Admin está logueado con permisos apropiados
- Existe un pago completado que es elegible para reembolso
- Política de reembolso permite el reembolso (ej: dentro de 30 días)

### Flujo Principal
1. Admin recibe solicitud de reembolso de usuario (vía email, ticket, chat)
2. Admin accede a panel admin → "Gestión de Pagos"
3. Admin busca el pago por ID, email de usuario, o fecha
4. Sistema muestra resultado de búsqueda
5. Admin selecciona el pago específico
6. Sistema muestra detalle del pago:
   ```
   Pago #12345
   
   Usuario: Juan Pérez (juan@email.com)
   Fecha: 15 de enero, 2026
   Monto: $499.00 MXN
   Estado: Completado
   Método:  Tarjeta ****  1234
   Plan: Google Tech + IA 100
   Openpay ID: tr4ns4ct10n1d
   
   [Procesar reembolso]
   ```
7. Admin hace clic en "Procesar reembolso"
8. Sistema valida elegibilidad:
   - Pago tiene `status = 'completed'`
   - NO ha sido reembolsado previamente
   - Está dentro del período permitido (30 días)
9. **Elegible para reembolso**
10. Sistema muestra formulario:
    ```
    Procesar reembolso
    
    Monto original: $499.00 MXN
    
    Tipo de reembolso:
    • Total: $499.00 MXN
    • Parcial: $[____] MXN
    
    Razón:  _________________
    (Ej: Solicitud del usuario, Error en cobro, Compensación)
    
    ⚠️ Esto reembolsará el monto a la tarjeta del usuario.
    El proceso puede tardar 5-10 días hábiles.
    
    [Confirmar reembolso]  [Cancelar]
    ```
11. Admin selecciona "Total" e ingresa razón
12. Admin confirma reembolso
13. Sistema solicita reembolso a Openpay API: 
    ```php
    $refund = $openpay->refunds->create([
      'charge_id' => 'tr4ns4ct10n1d',
      'description' => 'Solicitud del usuario',
      'amount' => 499.00
    ]);
    ```
14. **Openpay procesa reembolso exitosamente**
15. Sistema actualiza `payments`:
    - `status = 'refunded'`
16. Sistema ajusta suscripción del usuario:
    - Si fue pago de renovación → `status = 'cancelled'`
    - Si fue upgrade → Revierte al plan anterior
17. Sistema registra en `audit_logs`:
    - Admin que procesó reembolso
    - Razón del reembolso
    - Monto
18. Sistema envía email al usuario: 
    ```
    📧 Reembolso procesado
    
    Hola Juan,
    
    Tu reembolso ha sido procesado exitosamente. 
    
    Monto:  $499.00 MXN
    Fecha: 20 de enero, 2026
    Método: Regresará a tu tarjeta ****  1234
    
    El reembolso puede tardar 5-10 días hábiles en reflejarse en tu estado de cuenta.
    
    Si tienes dudas, contacta a soporte. 
    ```
19. Sistema muestra confirmación al admin:
    ```
    ✅ Reembolso procesado
    
    Usuario: Juan Pérez
    Monto: $499.00 MXN
    Openpay Refund ID: rfnd_xyz
    
    El usuario recibirá el monto en 5-10 días hábiles.
    ```

### Flujos Alternativos

**8a.  Pago NO es elegible para reembolso**
- 8a.1. Sistema detecta que pago fue hace más de 30 días
- 8a.2. Sistema muestra advertencia: 
    ```
    ⚠️ Fuera de política de reembolso
    
    Este pago fue hace 45 días.  
    Nuestra política permite reembolsos solo dentro de 30 días. 
    
    ¿Deseas proceder de todos modos?  (requiere autorización especial)
    
    [Sí, proceder]  [Cancelar]
    ```
- 8a.3. Admin con permisos especiales puede proceder
- 8a.4. CONTINÚA en paso 10

**14a. Openpay rechaza reembolso**
- 14a.1. Openpay devuelve error (ej: fondos insuficientes en cuenta merchant)
- 14a.2. Sistema muestra error al admin: 
    ```
    ❌ Error al procesar reembolso
    
    Razón: [Descripción del error de Openpay]
    
    Acciones:
    • Reintentar más tarde
    • Contactar soporte de Openpay
    • Procesar reembolso manual (transferencia)
    ```
- 14a.3. Admin decide acción

**16a. Reembolso parcial**
- 16a. 1. Admin selecciona monto parcial (ej: $200 de $499)
- 16a.2. Sistema procesa solo el monto parcial
- 16a.3. Suscripción permanece activa (si aplica)
- 16a.4. Se registra reembolso parcial en auditoría

### Postcondiciones

**Éxito:**
- Pago marcado como `refunded`
- Dinero devuelto a usuario (proceso de 5-10 días)
- Suscripción ajustada según corresponda
- Usuario notificado
- Acción registrada en auditoría

**Fallo:**
- Reembolso no procesado
- Pago permanece en estado original
- Admin notificado del error

### Reglas de Negocio
- RN-088: Reembolsos dentro de 30 días son automáticos
- RN-089: Reembolsos fuera de 30 días requieren aprobación especial
- RN-090: Reembolso puede ser total o parcial
- RN-091: Usuario debe ser notificado siempre de reembolsos
- RN-092: Reembolso tarda 5-10 días hábiles en reflejarse

### Excepciones
- EX-026: Si tarjeta del usuario está cerrada → Openpay puede rechazar reembolso
- EX-027: Solo Superadmin y Admin pueden procesar reembolsos

### Notas Adicionales
- Considerar tracking de tasa de reembolsos (indicador de problemas)
- Política de reembolso debe estar documentada y comunicada

---

## UC-017: Admin - Subir y enviar factura

**Identificador:** UC-017  
**Nombre:** Admin - Subir y enviar factura electrónica  
**Actores:** Admin, Sistema  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Admin genera factura en sistema externo (PAC/DIAN), sube el PDF al sistema y lo envía al usuario.

### Precondiciones
- Existe solicitud de factura con `status = 'requested'`
- Admin generó factura en sistema externo (PAC en MX, DIAN en CO)
- Admin tiene archivo PDF de la factura

### Flujo Principal
1. Admin accede a panel admin → "Facturas Pendientes"
2. Sistema muestra lista de solicitudes pendientes:
   ```
   Facturas pendientes
   
   #1234 - Juan Pérez - $499.00 MXN - 15 ene 2026 - [Procesar]
   #1235 - María López - $299.00 MXN - 14 ene 2026 - [Procesar]
   ```
3. Admin selecciona solicitud #1234
4. Sistema muestra detalle:
   ```
   Solicitud de factura #1234
   
   Usuario: Juan Pérez (juan@email.com)
   Pago: $499.00 MXN del 15 de enero, 2026
   Plan: Google Tech + IA 100
   
   Datos fiscales:
   RFC:  XAXX010101000
   Razón social:  Empresa SA de CV
   Régimen:  612
   Uso CFDI: G03
   
   Solicitada:  16 de enero, 2026
   Estado: Pendiente
   
   [Subir factura]
   ```
5. Admin hace clic en "Subir factura"
6. Sistema muestra formulario de upload:
   ```
   Subir factura para Juan Pérez
   
   Archivo PDF: [Seleccionar archivo]
   
   Verificar: 
   • Monto coincide:  $499.00 MXN
   • Fecha correcta: 15 de enero, 2026
   • Datos fiscales correctos
   
   [Subir y enviar]  [Cancelar]
   ```
7. Admin selecciona archivo PDF desde su computadora
8. Admin hace clic en "Subir y enviar"
9. Sistema valida archivo:
   - Es archivo PDF
   - Tamaño < 10 MB
   - Nombre de archivo válido
10. **Validaciones exitosas**
11. Sistema sube archivo a storage:
    - Ruta: `/storage/invoices/2026/01/invoice_1234.pdf`
    - Genera URL accesible
12. Sistema actualiza registro en `invoices`:
    - `file_url = '/storage/invoices/2026/01/invoice_1234.pdf'`
    - `sent_at = NOW()`
    - `status = 'completed'`
13. Sistema registra en `audit_logs` quién subió la factura
14. **Sistema envía email al usuario (#12) con factura adjunta:**
    ```
    📧 Email:   Tu factura está lista
    
    Hola Juan,
    
    Tu factura del pago de $499.00 MXN ya está disponible. 
    
    Adjunto: invoice_1234.pdf
    
    También puedes descargarla desde tu panel en cualquier momento: 
    https://app.com/profile/invoices
    
    Gracias por tu preferencia. 
    ```
15. Sistema marca solicitud como completada en lista de pendientes
16. Sistema muestra confirmación al admin:
    ```
    ✅ Factura enviada exitosamente
    
    Usuario: Juan Pérez
    Email enviado a:  juan@email.com
    Archivo: invoice_1234.pdf
    
    [Ver siguiente pendiente]
    ```

### Flujos Alternativos

**9a. Archivo no es PDF o excede tamaño**
- 9a.1. Sistema valida y detecta error
- 9a.2. Sistema muestra error:
    ```
    ❌ Archivo inválido
    
    • Solo se permiten archivos PDF
    • Tamaño máximo: 10 MB
    
    Por favor selecciona un archivo válido.
    ```
- 9a.3. Admin selecciona archivo correcto
- 9a.4. CONTINÚA en paso 9

**14a. Error al enviar email**
- 14a.1. Servicio SMTP falla
- 14a.2. Sistema registra error en logs
- 14a.3. Sistema muestra advertencia al admin:
    ```
    ⚠️ Factura subida pero email no se envió
    
    La factura fue guardada correctamente pero hubo 
    un error al enviar el email.
    
    Acciones:
    • Reintentar envío de email
    • Notificar al usuario manualmente
    ```
- 14a.4. Admin puede reintentar envío

**7a. Admin se equivoca de archivo**
- 7a. 1. Admin sube archivo incorrecto
- 7a. 2. Admin se da cuenta antes de que usuario descargue
- 7a. 3. Admin puede volver a subir archivo correcto
- 7a.4. Sistema sobrescribe archivo anterior
- 7a.5. Sistema NO reenvía email (evita spam)

### Postcondiciones

**Éxito:**
- Factura subida a storage
- Registro en `invoices` actualizado a `completed`
- Email enviado al usuario con PDF adjunto
- Factura disponible para descarga en panel de usuario
- Acción registrada en auditoría

**Fallo parcial:**
- Factura subida pero email no enviado
- Admin debe reintentar o notificar manualmente

### Reglas de Negocio
- RN-093: Solo archivos PDF son permitidos
- RN-094: Tamaño máximo de archivo: 10 MB
- RN-095: Archivo se guarda en estructura organizada por año/mes
- RN-096: Usuario puede descargar factura indefinidamente
- RN-097: Admin debe verificar datos antes de subir

### Excepciones
- EX-028: Si storage está lleno → Admin debe contactar DevOps

### Notas Adicionales
- Considerar integración API con PAC/DIAN para automatizar completamente
- Archivo debe estar optimizado (evitar escaneos pesados)

---

## UC-018: Webhook de pago exitoso desde Openpay

**Identificador:** UC-018  
**Nombre:** Procesar webhook de pago exitoso desde Openpay  
**Actores:** Openpay, Sistema  
**Prioridad:** Crítica  
**Estado:** Activo  

### Descripción
Sistema recibe y procesa webhook de Openpay cuando un pago es exitoso.

### Precondiciones
- Sistema tiene endpoint de webhooks configurado y accesible
- Openpay está configurado para enviar webhooks a la URL del sistema
- Webhook contiene firma HMAC válida

### Flujo Principal
1. **Openpay procesa un pago exitosamente**
2. Openpay envía POST request al endpoint de webhooks del sistema: 
   ```
   POST https://app.com/webhooks/openpay
   
   Headers:
   Content-Type: application/json
   X-Openpay-Signature: hmac_signature_here
   
   Body: 
   {
     "type": "charge.succeeded",
     "event_date": "2026-01-15T10:30:00Z",
     "data": {
       "id": "tr4ns4ct10n1d",
       "status": "completed",
       "amount": 499.00,
       "currency": "MXN",
       "order_id": "payment_12345",
       "customer_id": "cust_abc",
       "method": "card",
       "card":  {
         "card_number": "************1234",
         "brand": "visa"
       },
       "3d_secure": {
         "authenticated": true,
         "eci": "05"
       }
     }
   }
   ```
3. Sistema recibe request en `WebhookController@handleOpenpay`
4. **Sistema valida firma HMAC:**
   - Obtiene header `X-Openpay-Signature`
   - Calcula HMAC del body usando secret key de Openpay
   - Compara firma recibida con firma calculada
5. **Firma es válida**
6. Sistema registra webhook en logs para auditoría
7. Sistema extrae datos del webhook:
   - `type = 'charge.succeeded'`
   - `transaction_id = 'tr4ns4ct10n1d'`
   - `order_id = 'payment_12345'`
8. Sistema busca pago en BD por `openpay_transaction_id` o `order_id`
9. **Pago encontrado**
10. Sistema verifica estado actual del pago:
    - SI `status` ya es `'completed'` → Webhook duplicado, FIN (idempotencia)
    - SI `status` es `'pending'`, `'processing'`, `'requires_3ds'` → CONTINÚA
11. **Sistema actualiza registro en `payments`:**
    ```sql
    UPDATE payments SET
      status = 'completed',
      paid_at = NOW(),
      three_ds_status = 'authenticated',  -- si aplica
      updated_at = NOW()
    WHERE openpay_transaction_id = 'tr4ns4ct10n1d';
    ```
12. Sistema dispara evento Laravel:  `PaymentSuccessful`
13. **Listeners del evento se ejecutan:**

    **Listener 1: ProcessSubscriptionActivation**
    - Actualiza suscripción asociada: 
      - SI `status = 'trial'` → `status = 'active'`
      - SI `status = 'past_due'` → `status = 'active'`
      - SI `status = 'grace_period'` → `status = 'active'` (cierra período de gracia)
      - Actualiza `next_billing_date` según periodicidad
      - Marca `first_payment_3ds_completed = true` si es primer pago
      - Marca `mit_enabled = true` si es primer pago

    **Listener 2: ResetTokens**
    - Actualiza o crea registro en `tokens_usage`:
      - `used = 0`
      - `total` = tokens del plan
      - `period_start = HOY`
      - `period_end` = next_billing_date - 1 día

    **Listener 3: SendPaymentConfirmation**
    - Envía Email #2 (Confirmación de pago) al usuario

    **Listener 4: MarkForInvoicing**
    - Si país requiere facturación automática, crea solicitud en `invoices`

14. Sistema responde a Openpay con HTTP 200 OK:
    ```json
    {
      "status": "processed",
      "payment_id": 12345
    }
    ```
15. **Openpay recibe respuesta exitosa y no reintenta webhook**

### Flujos Alternativos

**4a. Firma HMAC inválida**
- 4a.1. Sistema detecta que firmas no coinciden
- 4a.2. Sistema registra intento sospechoso en logs de seguridad
- 4a. 3. Sistema responde HTTP 401 Unauthorized
- 4a.4. Sistema NO procesa el webhook
- 4a.5. Sistema alerta a DevOps (posible ataque)
- 4a.6. FIN

**8a. Pago NO encontrado en BD**
- 8a. 1. No existe registro con ese `openpay_transaction_id`
- 8a.2. Sistema registra webhook huérfano en logs
- 8a.3. Sistema responde HTTP 404 Not Found
- 8a. 4. Sistema alerta a admin para investigación manual
- 8a.5. FIN

**14a. Error al procesar (excepción en código)**
- 14a.1.  Ocurre error durante procesamiento (BD caída, error lógica)
- 14a.2. Sistema registra error completo en logs
- 14a.3. Sistema responde HTTP 500 Internal Server Error
- 14a.4. **Openpay reintenta webhook** (hasta 10 veces en 24 horas)
- 14a.5. Sistema eventualmente procesa cuando error se resuelve

**10a. Webhook duplicado (idempotencia)**
- 10a.1. Pago ya está en `status = 'completed'`
- 10a.2. Sistema registra en logs que es webhook duplicado
- 10a. 3. Sistema NO ejecuta lógica de negocio de nuevo
- 10a.4. Sistema responde HTTP 200 OK (evita reintentos de Openpay)
- 10a.5. FIN

### Postcondiciones

**Éxito:**
- Pago marcado como `completed`
- Suscripción activada/renovada
- Tokens reseteados
- Usuario notificado por email
- Webhook registrado en logs

**Fallo:**
- Webhook rechazado (firma inválida)
- O webhook en cola para reintento (error 500)

### Reglas de Negocio
- RN-098:  SIEMPRE validar firma HMAC de webhooks
- RN-099: Implementar idempotencia (no procesar duplicados)
- RN-100: Responder rápido a Openpay (< 5 segundos)
- RN-101: Registrar TODOS los webhooks en logs (auditoría)
- RN-102: Si error 500, permitir que Openpay reintente

### Excepciones
- EX-029: Si endpoint de webhook está caído → Openpay reintenta automáticamente

### Notas Adicionales
- Openpay reintenta webhooks fallidos cada:  10 min, 1h, 3h, 6h, 12h, 24h
- Endpoint de webhook debe ser robusto y monitoreado 24/7
- Considerar queue jobs para procesamiento asíncrono si lógica es pesada

---

## UC-019: Webhook de pago fallido desde Openpay

**Identificador:** UC-019  
**Nombre:** Procesar webhook de pago fallido desde Openpay  
**Actores:** Openpay, Sistema  
**Prioridad:** Alta  
**Estado:** Activo  

### Descripción
Sistema recibe y procesa webhook de Openpay cuando un pago falla.  

### Precondiciones
- Endpoint de webhooks configurado
- Webhook contiene firma HMAC válida

### Flujo Principal
1. **Openpay procesa un cargo y falla**
2. Openpay envía POST request: 
   ```json
   POST https://app.com/webhooks/openpay
   
   {
     "type": "charge. failed",
     "event_date": "2026-01-15T10:30:00Z",
     "data": {
       "id": "tr4ns4ct10n1d",
       "status": "failed",
       "amount": 499.00,
       "currency": "MXN",
       "order_id": "payment_12345",
       "error_code": "1001",
       "description": "Insufficient funds",
       "3d_secure": {
         "authenticated": false,
         "reason": null
       }
     }
   }
   ```
3. Sistema valida firma HMAC (igual que UC-018 paso 4-5)
4. **Firma válida**
5. Sistema registra webhook en logs
6. Sistema extrae datos: 
   - `type = 'charge.failed'`
   - `transaction_id = 'tr4ns4ct10n1d'`
   - `error_code = '1001'`
   - `error_description = 'Insufficient funds'`
7. Sistema busca pago en BD por `openpay_transaction_id`
8. **Pago encontrado**
9. Sistema verifica estado actual: 
   - SI ya está en `'failed'` → Webhook duplicado, FIN
   - SI está en `'pending'`, `'processing'`, `'requires_3ds'` → CONTINÚA
10. **Sistema actualiza registro en `payments`:**
    ```sql
    UPDATE payments SET
      status = 'failed',
      error_code = '1001',
      error_message = 'Insufficient funds',
      updated_at = NOW()
    WHERE openpay_transaction_id = 'tr4ns4ct10n1d';
    ```
11. Sistema identifica **tipo de fallo:**
    - **Tipo A:** Requiere 3DS (códigos:  3001, 3002) → Ver UC-021
    - **Tipo B:** Fondos insuficientes (código: 1001)
    - **Tipo C:** Tarjeta inválida/expirada (códigos: 1005, 1006, 1010)
    - **Tipo D:** Otros errores técnicos
12. **Para Tipo B/C/D:** Sistema inicia flujo de reintentos
13. Sistema dispara evento Laravel:  `PaymentFailed`
14. **Listeners del evento se ejecutan:**

    **Listener 1: UpdateSubscriptionStatus**
    - Actualiza suscripción: 
      - `status = 'past_due'`

    **Listener 2: CreatePaymentRetry**
    - Crea registro en `payment_retries`:
      - `payment_id` = ID del pago
      - `attempt` = 1
      - `tried_at = NOW()`
      - `result` = error_description

    **Listener 3: ScheduleRetry**
    - Programa job para reintento en 3 días: 
      - `ProcessPaymentRetry:: dispatch($payment)->delay(now()->addDays(3))`

    **Listener 4: SendPaymentFailedEmail**
    - Envía Email #4 (Fallo de pago) al usuario:
      ```
      📧 No pudimos procesar tu pago
      
      Hola [Nombre],
      
      Intentamos procesar tu pago de $499.00 MXN pero no fue exitoso.
      
      Razón:  Fondos insuficientes
      
      Qué puedes hacer: 
      • Asegúrate de tener fondos suficientes
      • Actualiza tu tarjeta de pago
      • Contacta a tu banco
      
      Reintentaremos el cobro en 3 días (18 de enero).
      
      Si necesitas ayuda, contacta a soporte. 
      ```

15. Sistema responde a Openpay con HTTP 200 OK
16. **Openpay recibe respuesta y no reintenta webhook**

### Flujos Alternativos

**11a. Fallo tipo A:  Requiere 3DS (banco rechazó MIT)**
- 11a.1. Sistema detecta códigos 3001 o 3002
- 11a.2. Sistema actualiza `payments`:
  - `status = 'requires_3ds'`
  - `three_ds_status = 'pending'`
  - `requires_3ds = true`
- 11a.3. Sistema envía Email #20 (Autenticación requerida) - Ver UC-021
- 11a.4. FIN (espera acción del usuario)

**13a. Después de 3 fallos:  Período de gracia**
- 13a. 1. Sistema verifica `payment_retries` COUNT = 3
- 13a. 2. Sistema dispara evento `EnterGracePeriod`
- 13a.3. Listener ejecuta UC-004 (crear grace period)

**3a. Firma HMAC inválida**
- Similar a UC-018 flujo alternativo 4a

**7a. Pago no encontrado**
- Similar a UC-018 flujo alternativo 8a

### Postcondiciones

**Éxito:**
- Pago marcado como `failed`
- Suscripción marcada como `past_due`
- Reintento programado
- Usuario notificado
- Webhook registrado en logs

**Fallo:**
- Webhook rechazado (firma inválida)
- O en cola para reintento (error 500)

### Reglas de Negocio
- RN-103:  Distinguir tipo de fallo para aplicar lógica correcta
- RN-104: Fallo por 3DS requerido tiene manejo especial (no es reintento automático)
- RN-105: Máximo 3 reintentos automáticos antes de gracia
- RN-106: Usuario debe ser notificado inmediatamente de fallos

### Excepciones
- EX-030: Si fallo es por error técnico de Openpay → Reintentar inmediatamente

### Notas Adicionales
- Código de error de Openpay indica la razón específica del fallo
- Sistema debe ser inteligente al comunicar razón al usuario (lenguaje claro)
- Monitorear tasa de fallos por tipo para identificar patrones

---

## 📊 Resumen de Casos de Uso

### Por Prioridad

**Críticos (5):**
- UC-001: Registro con trial
- UC-002: Renovación automática exitosa
- UC-018: Webhook pago exitoso
- UC-020: Autenticación 3DS primer pago 🆕

**Altos (8):**
- UC-003: Reintentos
- UC-004: Período de gracia
- UC-006: Upgrade de plan
- UC-010: Consumo de tokens
- UC-011: Solicitar factura
- UC-013: Reactivación
- UC-014: Admin - Gestionar plan
- UC-017: Admin - Subir factura
- UC-019: Webhook pago fallido
- UC-021: Renovación con fallo 3DS 🆕
- UC-022: Usuario autentica pago 🆕

**Medios (6):**
- UC-005: Pago manual transferencia
- UC-007: Downgrade
- UC-008: Aplicar cupón
- UC-009: Referir amigo
- UC-012: Cancelación
- UC-015: Admin - Crear cupón
- UC-016: Admin - Reembolso

### Casos de Uso por Actor

**Usuario:**
- UC-001, UC-006, UC-007, UC-008, UC-009, UC-010, UC-011, UC-012, UC-020, UC-022

**Sistema (Automatizado):**
- UC-002, UC-003, UC-004, UC-018, UC-019, UC-021

**Admin:**
- UC-014, UC-015, UC-016, UC-017

**Openpay (Externo):**
- UC-018, UC-019, UC-020, UC-021, UC-022

### Nuevos con 3D Secure

**🆕 UC-020:** Autenticación 3DS en primer pago  
**🆕 UC-021:** Renovación automática con fallo por 3DS  
**🆕 UC-022:** Usuario autentica pago pendiente  

Estos 3 casos de uso son NUEVOS y críticos para el correcto funcionamiento del sistema con 3D Secure obligatorio.

---

## 📚 Referencias

- [PRD - Requerimientos del Producto](./PRD. md)
- [User Flows - Diagramas de Flujo](./USER_FLOWS.md)
- [Database Schema](./DATABASE_SCHEMA.md)
- [3DS Integration](./3DS_INTEGRATION.md)
- [API Webhooks](./API_WEBHOOKS.md)

---

## 📝 Notas de Implementación

### Orden Recomendado de Desarrollo

**Fase 1: Core MVP (Mes 1)**
1. UC-001: Registro con trial (incluye UC-020 para 3DS)
2. UC-018: Webhook pago exitoso
3. UC-019: Webhook pago fallido
4. UC-002: Renovación automática
5. UC-010: Consumo de tokens

**Fase 2: Gestión de Fallos (Mes 2)**
6. UC-003: Reintentos
7. UC-021: Renovación con fallo 3DS 🆕
8. UC-022: Usuario autentica pago 🆕
9. UC-004: Período de gracia
10. UC-013: Reactivación

**Fase 3: Flexibilidad Usuario (Mes 2-3)**
11. UC-006: Upgrade
12. UC-007: Downgrade
13. UC-012: Cancelación
14. UC-008: Cupones
15. UC-009: Referidos

**Fase 4: Facturación (Mes 3)**
16. UC-011: Solicitar factura
17. UC-017: Admin subir factura
18. UC-005: Pago manual

**Fase 5: Admin Tools (Mes 3-4)**
19. UC-014: Admin gestionar plan
20. UC-015: Admin crear cupón
21. UC-016: Admin reembolso

### Testing Crítico

Cada caso de uso debe tener:
- ✅ Tests unitarios de lógica de negocio
- ✅ Tests de integración con Openpay (sandbox)
- ✅ Tests de webhooks (mock y real)
- ✅ Tests específicos de flujos 3DS (UC-020, UC-021, UC-022)
- ✅ Tests de edge cases y flujos alternativos
- ✅ Tests de performance (especialmente webhooks)

### Monitoreo Requerido

- 📊 Dashboard de métricas de pagos (tasas éxito/fallo)
- 📊 Dashboard de métricas 3DS (autenticación, abandono)
- 🔔 Alertas de webhooks fallidos
- 🔔 Alertas de caída de tasa de aprobación
- 📝 Logs estructurados de todos los eventos de pago

---

**Versión:** 1.2  
**Total casos de uso:** 24 (19 originales + 3 de 3DS + 2 de períodos personalizables)  
**Última actualización:** Enero 2026  

**Cambios en v1.2:**
- ✅ Agregado UC-023: Aplicar trial personalizado (Admin)
- ✅ Agregado UC-024: Ajustar grace period personalizado (Admin)

**Cambios en v1.1:**
- ✅ Agregado UC-020: Autenticación 3DS primer pago
- ✅ Agregado UC-021: Renovación con fallo por 3DS
- ✅ Agregado UC-022: Usuario autentica pago pendiente
- ✅ Actualizado UC-001: Incluye flujo 3DS completo
- ✅ Actualizado UC-002: Incluye MIT para renovaciones
- ✅ Actualizado UC-006: Incluye posible 3DS en upgrade
- ✅ Actualizado UC-018: Procesa webhooks 3DS
- ✅ Actualizado UC-019: Distingue fallos por 3DS

---

**Fin del Documento**