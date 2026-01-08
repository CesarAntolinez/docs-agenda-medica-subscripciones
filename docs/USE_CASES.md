# 📊 Casos de Uso Detallados
## Sistema de Planes y Suscripciones

---

## 📑 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Casos de Uso - Usuario](#casos-de-uso---usuario)
3. [Casos de Uso - Sistema](#casos-de-uso---sistema)
4. [Casos de Uso - Administrador](#casos-de-uso---administrador)
5. [Casos de Uso - Integraciones](#casos-de-uso---integraciones)

---

## Introducción

Este documento detalla los casos de uso del sistema de suscripciones siguiendo un formato estándar que incluye: actores, precondiciones, flujo principal, flujos alternativos, postcondiciones y reglas de negocio.

**Formato de Identificación:** UC-XXX donde XXX es el número secuencial del caso de uso.

---

## Casos de Uso - Usuario

### UC-001: Registro de Nuevo Usuario con Trial

**Actores:** Usuario nuevo, Sistema, Openpay

**Precondiciones:**
- Usuario no tiene cuenta en el sistema
- Plan seleccionado tiene trial configurado
- Usuario tiene tarjeta de crédito/débito válida

**Flujo Principal:**
1. Usuario accede a la página de planes
2. Usuario selecciona plan deseado
3. Sistema muestra formulario de registro
4. Usuario ingresa datos personales (nombre, email, contraseña)
5. Usuario ingresa datos fiscales según su país
6. Sistema valida datos ingresados
7. Sistema solicita información de tarjeta
8. Usuario ingresa datos de tarjeta
9. Sistema tokeniza tarjeta en Openpay
10. Sistema crea usuario en base de datos
11. Sistema crea suscripción con status "trialing"
12. Sistema asigna tokens completos del plan
13. Sistema envía email de bienvenida
14. Sistema muestra dashboard con información del trial

**Flujos Alternativos:**

**6a. Datos de registro inválidos:**
- 6a.1. Sistema muestra errores de validación
- 6a.2. Usuario corrige datos
- 6a.3. Continúa en paso 6

**6b. Email ya registrado:**
- 6b.1. Sistema muestra mensaje "Email ya en uso"
- 6b.2. Usuario puede intentar login o usar otro email
- 6b.3. Si elige otro email, continúa en paso 4

**6c. Datos fiscales incompletos o inválidos:**
- 6c.1. Sistema muestra errores específicos por campo
- 6c.2. Usuario completa/corrige datos fiscales
- 6c.3. Continúa en paso 6

**9a. Tarjeta rechazada por Openpay:**
- 9a.1. Sistema muestra mensaje de error específico
- 9a.2. Usuario puede intentar con otra tarjeta
- 9a.3. Continúa en paso 8

**9b. Error de comunicación con Openpay:**
- 9b.1. Sistema muestra mensaje de error temporal
- 9b.2. Sistema registra error en logs
- 9b.3. Usuario puede reintentar después de 5 minutos
- 9b.4. Continúa en paso 8

**Postcondiciones:**
- Usuario creado en sistema con rol asignado
- Suscripción activa en período de trial
- Tokens asignados según plan
- Token de tarjeta almacenado
- Email de bienvenida enviado
- Audit log registrado

**Reglas de Negocio:**
- RN-001: Trial solo disponible para nuevos usuarios
- RN-002: Tarjeta es obligatoria para activar trial
- RN-003: Datos fiscales obligatorios desde el registro
- RN-004: Un email solo puede tener una cuenta activa
- RN-005: Tokens de trial no expiran hasta fin del período

---

### UC-002: Renovación Automática Exitosa

**Actores:** Sistema, Openpay

**Precondiciones:**
- Suscripción activa con tarjeta registrada
- Fecha actual = next_billing_date
- Tarjeta válida y con fondos suficientes

**Flujo Principal:**
1. Sistema ejecuta job de renovaciones diarias (2 AM)
2. Sistema identifica suscripciones para renovar hoy
3. Para cada suscripción:
   - Sistema obtiene datos de suscripción y plan
   - Sistema calcula monto a cobrar según plan y país
   - Sistema aplica descuentos activos si existen
   - Sistema crea registro de pago con status "pending"
   - Sistema intenta cargo en Openpay con token de tarjeta
4. Openpay procesa cargo exitosamente
5. Sistema recibe confirmación de Openpay
6. Sistema actualiza pago con status "successful"
7. Sistema actualiza suscripción:
   - Mantiene/actualiza status a "active"
   - Actualiza next_billing_date según periodicidad
8. Sistema resetea tokens mensuales:
   - Crea nuevo registro en tokens_usage
   - Asigna total según plan
   - Establece used = 0
9. Sistema envía email de confirmación de pago
10. Sistema crea solicitud de factura automática
11. Sistema registra en audit log

**Flujos Alternativos:**

**4a. Descuento temporal vencido:**
- 4a.1. Sistema verifica duración del descuento
- 4a.2. Si venció, sistema remueve descuento
- 4a.3. Sistema cobra precio completo
- 4a.4. Sistema notifica al usuario del cambio
- 4a.5. Continúa en paso 5

**4b. Cargo rechazado por Openpay:**
- Ver UC-003: Renovación automática fallida

**Postcondiciones:**
- Pago registrado como exitoso
- Suscripción renovada para próximo período
- Tokens reseteados a total del plan
- Email de confirmación enviado
- Solicitud de factura creada
- Próxima fecha de cobro calculada
- Audit log actualizado

**Reglas de Negocio:**
- RN-006: Renovación se intenta exactamente en next_billing_date
- RN-007: Tokens se resetean SOLO después de pago exitoso
- RN-008: Descuentos temporales se evalúan en cada renovación
- RN-009: Factura se solicita automáticamente post-pago
- RN-010: next_billing_date se calcula según periodicidad del plan

---

### UC-003: Renovación Automática Fallida - Reintentos

**Actores:** Sistema, Openpay, Usuario

**Precondiciones:**
- Intento de renovación automática falló
- Suscripción tiene tarjeta registrada
- No se han agotado los 3 reintentos

**Flujo Principal:**
1. Sistema recibe respuesta de fallo de Openpay
2. Sistema actualiza pago con status "failed"
3. Sistema crea registro en payment_retries (attempt 1)
4. Sistema actualiza suscripción a status "past_due"
5. Sistema envía email notificando fallo de pago
6. Sistema programa reintento #1 para 3 días después
7. **Después de 3 días:**
8. Sistema ejecuta reintento #1
9. Sistema intenta cargo nuevamente en Openpay

**[Si Reintento #1 Exitoso]**
10. Ver UC-002 (flujo de renovación exitosa)

**[Si Reintento #1 Fallido]**
11. Sistema registra fallo de reintento #1
12. Sistema envía email de fallo de reintento #1
13. Sistema programa reintento #2 para 7 días después
14. **Después de 7 días adicionales:**
15. Sistema ejecuta reintento #2
16. Sistema intenta cargo nuevamente en Openpay

**[Si Reintento #2 Exitoso]**
17. Ver UC-002 (flujo de renovación exitosa)

**[Si Reintento #2 Fallido]**
18. Sistema registra fallo de reintento #2
19. Sistema envía email de fallo de reintento #2
20. Sistema programa reintento #3 para 10 días después
21. **Después de 10 días adicionales:**
22. Sistema ejecuta reintento #3 (último intento)
23. Sistema intenta cargo nuevamente en Openpay

**[Si Reintento #3 Exitoso]**
24. Ver UC-002 (flujo de renovación exitosa)

**[Si Reintento #3 Fallido - Todos los reintentos agotados]**
25. Ver UC-004 (inicio de período de gracia)

**Flujos Alternativos:**

**5a. Usuario actualiza tarjeta durante reintentos:**
- 5a.1. Usuario accede a configuración de pago
- 5a.2. Usuario ingresa nueva tarjeta
- 5a.3. Sistema tokeniza nueva tarjeta
- 5a.4. Sistema actualiza subscription.card_token
- 5a.5. Sistema puede intentar cargo inmediato (opcional)
- 5a.6. Si cargo exitoso, ver UC-002
- 5a.7. Si no, continúa con programación de reintentos

**9a. Error de comunicación con Openpay:**
- 9a.1. Sistema registra error técnico
- 9a.2. Sistema reintenta después de 1 hora (mismo día)
- 9a.3. Si persiste, continúa con programación normal

**Postcondiciones:**
- Si exitoso: Ver UC-002
- Si todos fallan: Ver UC-004
- Todos los intentos registrados en payment_retries
- Usuario notificado en cada intento
- Audit log completo de intentos

**Reglas de Negocio:**
- RN-011: Máximo 3 reintentos automáticos
- RN-012: Intervalos: 3 días, 7 días, 10 días después del intento anterior
- RN-013: Usuario mantiene acceso durante reintentos
- RN-014: Suscripción status "past_due" durante reintentos
- RN-015: Usuario recibe notificación en cada intento fallido

---

### UC-004: Período de Gracia por Fallo de Pago

**Actores:** Sistema, Usuario

**Precondiciones:**
- 3 reintentos de pago han fallado
- Suscripción en status "past_due"
- No existe período de gracia activo para esta suscripción

**Flujo Principal:**
1. Sistema detecta que 3 reintentos han fallado
2. Sistema crea registro en grace_periods:
   - started_at = fecha actual
   - ends_at = fecha actual + 2 meses
   - months_owed = 1
   - amount_owed = precio del plan
   - notifications_sent = 0
3. Sistema actualiza suscripción a status "active" (mantiene acceso)
4. Sistema envía email de entrada a período de gracia
5. Sistema programa recordatorios cada 15 días
6. **Cada 15 días durante el período de gracia:**
7. Sistema envía email recordatorio de pago pendiente
8. Sistema incrementa grace_periods.notifications_sent
9. Sistema muestra deuda acumulada en dashboard del usuario
10. **Si pasa mes adicional sin pago:**
11. Sistema incrementa months_owed
12. Sistema incrementa amount_owed (suma precio plan adicional)
13. **Al cumplirse 2 meses desde inicio:**
14. Ver UC-013 (bloqueo por falta de pago)

**Flujos Alternativos:**

**7a. Usuario realiza pago durante período de gracia:**
- 7a.1. Usuario accede a pagar deuda acumulada
- 7a.2. Sistema calcula monto total adeudado
- 7a.3. Usuario confirma pago
- 7a.4. Sistema procesa pago en Openpay
- 7a.5. Si exitoso:
  - Sistema marca grace_period como completado
  - Sistema limpia deuda (months_owed = 0, amount_owed = 0)
  - Sistema actualiza/mantiene status "active"
  - Sistema establece nuevo next_billing_date
  - Sistema envía email de reactivación exitosa
  - Sistema registra en audit log
- 7a.6. Si falla:
  - Sistema muestra error
  - Usuario puede reintentar
  - Continúa en período de gracia

**7b. Usuario actualiza tarjeta y solicita reintento:**
- 7b.1. Usuario ingresa nueva tarjeta
- 7b.2. Sistema tokeniza tarjeta
- 7b.3. Usuario solicita cobro inmediato de deuda
- 7b.4. Continúa en flujo 7a desde paso 7a.4

**9a. Usuario cancela suscripción durante gracia:**
- 9a.1. Usuario solicita cancelación
- 9a.2. Sistema muestra deuda pendiente
- 9a.3. Sistema requiere pago de deuda para cancelación limpia
- 9a.4. Si usuario paga: cancelación limpia
- 9a.5. Si no paga: cancelación con deuda registrada

**Postcondiciones:**
- Período de gracia activo
- Usuario mantiene acceso completo a plataforma
- Deuda acumulada visible
- Recordatorios programados
- Si paga: suscripción reactivada normalmente
- Si no paga en 2 meses: bloqueo de cuenta

**Reglas de Negocio:**
- RN-016: Duración fija de 2 meses de gracia
- RN-017: Acceso completo durante período de gracia
- RN-018: Recordatorios cada 15 días (configurable)
- RN-019: Deuda se acumula mensualmente
- RN-020: Solo un período de gracia activo por suscripción

---

### UC-005: Pago Manual con Transferencia

**Actores:** Usuario, Sistema, Admin

**Precondiciones:**
- Usuario seleccionó pago manual (sin tarjeta)
- Usuario NO puede estar en trial (trial requiere tarjeta)

**Flujo Principal:**
1. Usuario selecciona plan
2. Usuario elige método "Transferencia Bancaria"
3. Sistema genera orden de pago única
4. Sistema crea subscription con status "pending"
5. Sistema crea payment con status "pending" y method "transfer"
6. Sistema obtiene datos bancarios según país
7. Sistema envía email con:
   - Datos bancarios para transferencia
   - Monto exacto a pagar
   - Referencia única de pago
   - Instrucciones detalladas
8. Sistema muestra página de confirmación con misma información
9. Usuario realiza transferencia en su banco
10. Usuario sube comprobante en plataforma
11. Sistema notifica a Admin de comprobante recibido
12. Admin accede a panel de pagos manuales pendientes
13. Admin revisa comprobante
14. Admin verifica transferencia en cuenta bancaria
15. Admin confirma pago en sistema
16. Sistema actualiza payment a status "successful"
17. Sistema actualiza subscription a status "active"
18. Sistema asigna tokens del plan
19. Sistema envía email de confirmación de activación
20. Sistema registra en audit log

**Flujos Alternativos:**

**10a. Usuario no sube comprobante:**
- 10a.1. Después de 72 horas sin comprobante
- 10a.2. Sistema envía recordatorio
- 10a.3. Después de 7 días sin comprobante
- 10a.4. Sistema marca orden como expirada
- 10a.5. Usuario debe generar nueva orden

**14a. Admin rechaza comprobante:**
- 14a.1. Admin marca pago como "rechazado"
- 14a.2. Admin ingresa razón del rechazo
- 14a.3. Sistema envía email a usuario explicando rechazo
- 14a.4. Usuario puede subir nuevo comprobante
- 14a.5. Continúa en paso 11

**14b. Monto transferido incorrecto:**
- 14b.1. Admin detecta monto diferente
- 14b.2. Si menor: Admin contacta usuario para diferencia
- 14b.3. Si mayor: Admin contacta para reembolso o crédito
- 14b.4. Usuario corrige situación
- 14b.5. Continúa en paso 15

**Postcondiciones:**
- Si aprobado: Suscripción activa, tokens asignados
- Si rechazado: Orden sigue pendiente hasta corrección
- Pago registrado en historial
- Admin puede ofrecer opción de agregar tarjeta para futuras renovaciones
- Audit log completo

**Reglas de Negocio:**
- RN-021: Pago manual NO disponible para trial
- RN-022: Orden expira en 7 días sin confirmación
- RN-023: Referencia de pago debe ser única por orden
- RN-024: Usuario puede agregar tarjeta después para auto-renovación
- RN-025: Próxima renovación también será manual si no agrega tarjeta

---

### UC-006: Upgrade Inmediato de Plan

**Actores:** Usuario, Sistema, Openpay

**Precondiciones:**
- Usuario tiene suscripción activa
- Plan destino es superior al actual (más caro o más tokens)
- Usuario tiene método de pago válido (tarjeta)

**Flujo Principal:**
1. Usuario accede a gestión de suscripción
2. Usuario selecciona "Cambiar Plan"
3. Sistema muestra planes disponibles superiores
4. Usuario selecciona nuevo plan
5. Sistema calcula prorrata:
   - Días restantes en período actual
   - Crédito por días no usados = (días_restantes / días_totales) × precio_plan_actual
   - Cargo inmediato = precio_plan_nuevo - crédito
6. Sistema muestra resumen detallado:
   - Plan actual y precio
   - Plan nuevo y precio
   - Días restantes en período actual
   - Crédito aplicado
   - Cargo inmediato
   - Nuevo monto de próxima renovación
   - Tokens que se asignarán inmediatamente
7. Usuario revisa y confirma upgrade
8. Sistema procesa cargo inmediato en Openpay
9. Openpay confirma transacción exitosa
10. Sistema actualiza suscripción:
    - plan_id = nuevo plan
    - Recalcula next_billing_date desde hoy según periodicidad
11. Sistema resetea tokens INMEDIATAMENTE:
    - Tokens anteriores se pierden
    - Asigna tokens completos del nuevo plan
12. Sistema crea registro de pago
13. Sistema envía email de confirmación de upgrade
14. Sistema registra cambio en audit log con before/after
15. Sistema muestra mensaje de éxito con nuevos tokens disponibles

**Flujos Alternativos:**

**8a. Cargo rechazado:**
- 8a.1. Sistema muestra error de Openpay
- 8a.2. Sistema no aplica cambio de plan
- 8a.3. Usuario mantiene plan actual
- 8a.4. Usuario puede reintentar o actualizar tarjeta
- 8a.5. Fin del caso de uso

**9a. Error de comunicación:**
- 9a.1. Sistema registra error
- 9a.2. Sistema no aplica cambio
- 9a.3. Sistema muestra mensaje de error temporal
- 9a.4. Usuario puede reintentar después de 5 minutos
- 9a.5. Fin del caso de uso

**Postcondiciones:**
- Suscripción actualizada a nuevo plan
- Cargo prorrateado procesado
- Tokens reseteados a nuevo plan inmediatamente
- Próxima renovación en nueva fecha (desde hoy)
- Email de confirmación enviado
- Audit log con detalle del cambio

**Reglas de Negocio:**
- RN-026: Upgrade es inmediato, no programado
- RN-027: Se cobra prorrata en el momento
- RN-028: Tokens se resetean INMEDIATAMENTE al nuevo plan
- RN-029: Tokens del plan anterior se pierden (no se suman)
- RN-030: Próximo cobro completo es según nueva periodicidad desde hoy

---

### UC-007: Downgrade Programado de Plan

**Actores:** Usuario, Sistema

**Precondiciones:**
- Usuario tiene suscripción activa
- Plan destino es inferior al actual (más barato o menos tokens)

**Flujo Principal:**
1. Usuario accede a gestión de suscripción
2. Usuario selecciona "Cambiar Plan"
3. Sistema muestra planes disponibles inferiores
4. Usuario selecciona plan inferior
5. Sistema muestra impacto del cambio:
   - Plan actual y características
   - Plan nuevo y características
   - Reducción de tokens mensuales
   - Nuevo precio (menor)
   - Fecha efectiva: próxima renovación
   - Fecha de próxima renovación actual
6. Usuario confirma downgrade programado
7. Sistema guarda cambio pendiente:
   - Marca suscripción con "pending_downgrade"
   - Guarda plan_id destino
   - Fecha efectiva = next_billing_date
8. Sistema envía email confirmando downgrade programado
9. Sistema muestra mensaje: "Cambio programado para [fecha]"
10. Usuario continúa usando plan actual hasta renovación
11. **En fecha de renovación (next_billing_date):**
12. Sistema ejecuta job de renovaciones
13. Sistema detecta downgrade programado
14. Sistema procesa pago con precio del NUEVO plan
15. Si pago exitoso:
    - Actualiza plan_id al nuevo plan
    - Resetea tokens al total del nuevo plan (menor)
    - Actualiza next_billing_date según periodicidad
    - Remueve marca "pending_downgrade"
    - Envía email confirmando cambio aplicado
16. Sistema registra cambio en audit log

**Flujos Alternativos:**

**7a. Usuario cancela downgrade programado antes de ejecución:**
- 7a.1. Usuario accede a suscripción
- 7a.2. Sistema muestra "Downgrade programado para [fecha]"
- 7a.3. Usuario selecciona "Cancelar cambio programado"
- 7a.4. Sistema remueve pending_downgrade
- 7a.5. Sistema envía email confirmando cancelación
- 7a.6. Usuario continúa con plan actual normalmente
- 7a.7. Fin del caso de uso

**14a. Pago de renovación falla:**
- 14a.1. Sistema mantiene downgrade programado
- 14a.2. Sistema inicia proceso de reintentos (UC-003)
- 14a.3. Cuando pago sea exitoso, aplica downgrade
- 14a.4. Si entra en gracia, downgrade se aplica al regularizar pago

**Postcondiciones:**
- Cambio programado guardado
- Usuario notificado de cambio futuro
- Usuario mantiene plan actual hasta renovación
- En renovación: plan cambia, tokens reducen, precio reduce
- Audit log completo

**Reglas de Negocio:**
- RN-031: Downgrade NO es inmediato, se aplica en renovación
- RN-032: Usuario mantiene plan actual hasta renovación
- RN-033: Puede cancelar downgrade antes de que se ejecute
- RN-034: En renovación, cobra precio del nuevo plan (menor)
- RN-035: Tokens resetean al total del nuevo plan en renovación

---

### UC-008: Aplicar Cupón de Descuento

**Actores:** Usuario, Sistema

**Precondiciones:**
- Usuario está en proceso de checkout o renovación
- Usuario tiene código de cupón válido
- Usuario NO tiene otro cupón activo (no acumulables)

**Flujo Principal:**
1. Usuario ingresa código de cupón en campo
2. Usuario hace clic en "Aplicar"
3. Sistema normaliza código (uppercase, trim)
4. Sistema busca cupón por código
5. Sistema valida cupón:
   - Existe en base de datos
   - Campo active = true
   - No está expirado (expires_at > now o NULL)
   - No alcanzó límite de usos (current_usage < usage_limit o NULL)
   - Aplica al plan seleccionado (applicable_plans incluye plan_id o es NULL)
   - Usuario no lo ha usado antes (no existe en user_coupons)
6. Sistema calcula descuento:
   - Si type = "percentage": descuento = precio × (value / 100)
   - Si type = "fixed_amount": descuento = value
7. Sistema calcula precio final = precio - descuento
8. Sistema muestra resumen:
   - Precio original
   - Descuento aplicado
   - Precio final
   - Duración del descuento (duration_months o "permanente")
9. Usuario procede con pago
10. Sistema procesa pago con precio con descuento
11. Si pago exitoso:
    - Sistema crea registro en user_coupons
    - Sistema incrementa coupon.current_usage
    - Sistema asocia cupón a suscripción
    - Sistema programa aplicación según duración
12. Sistema envía confirmación con descuento aplicado

**Flujos Alternativos:**

**5a. Cupón no existe:**
- 5a.1. Sistema muestra "Cupón no encontrado"
- 5a.2. Fin del caso de uso

**5b. Cupón inactivo:**
- 5b.1. Sistema muestra "Cupón no válido"
- 5b.2. Fin del caso de uso

**5c. Cupón expirado:**
- 5c.1. Sistema muestra "Cupón expirado el [fecha]"
- 5c.2. Fin del caso de uso

**5d. Límite de usos alcanzado:**
- 5d.1. Sistema muestra "Cupón ya no disponible"
- 5d.2. Fin del caso de uso

**5e. No aplica al plan seleccionado:**
- 5e.1. Sistema muestra "Cupón no válido para este plan"
- 5e.2. Fin del caso de uso

**5f. Usuario ya usó este cupón:**
- 5f.1. Sistema muestra "Ya has usado este cupón"
- 5f.2. Fin del caso de uso

**5g. Usuario tiene otro cupón activo:**
- 5g.1. Sistema muestra "Ya tienes un cupón activo"
- 5g.2. Sistema muestra cupón actual
- 5g.3. Sistema pregunta si desea reemplazar
- 5g.4. Si usuario acepta:
  - Sistema remueve cupón anterior
  - Continúa en paso 6
- 5g.5. Si rechaza: Fin del caso de uso

**10a. Pago falla:**
- 10a.1. Sistema NO crea registro en user_coupons
- 10a.2. Sistema NO incrementa current_usage
- 10a.3. Cupón queda disponible para reintentar
- 10a.4. Usuario puede corregir pago y reintentar

**Postcondiciones:**
- Si exitoso: Descuento aplicado a suscripción
- user_coupons registrado
- Cupón usage incrementado
- Descuento se aplica según duración configurada
- Audit log registrado

**Reglas de Negocio:**
- RN-036: Cupones NO son acumulables (solo uno activo)
- RN-037: Usuario puede usar cada cupón solo una vez
- RN-038: Descuento permanente (duration_months NULL) aplica siempre
- RN-039: Descuento temporal aplica por N meses, luego revierte
- RN-040: Al vencer descuento, próxima renovación es precio completo

---

### UC-009: Referir a un Amigo

**Actores:** Usuario (Referidor), Usuario Nuevo (Referido), Sistema

**Precondiciones:**
- Referidor tiene suscripción activa
- Referido es un usuario nuevo (no existe en sistema)

**Flujo Principal:**
1. Referidor accede a sección "Referir amigos"
2. Sistema genera o muestra código único existente
3. Sistema genera link único: `https://app.com/register?ref=CODIGO`
4. Sistema muestra opciones para compartir:
   - Copiar link
   - Compartir por email
   - Compartir por WhatsApp
   - Compartir por redes sociales
5. Referidor comparte link con amigo
6. Referido hace clic en link
7. Sistema captura código de referido en sesión
8. Sistema muestra página de registro con mensaje "Invitado por [Nombre]"
9. Referido completa registro
10. Sistema crea usuario referido
11. Sistema crea registro en referrals:
    - referrer_id = referidor
    - referred_id = referido
    - code = código usado
    - status = "pending"
    - referrer_benefit = configuración actual
    - referred_benefit = configuración actual
12. Sistema envía email a referidor: "Tu amigo [nombre] se registró"
13. Referido inicia trial
14. Sistema muestra dashboard de referido con programa
15. **Al completar trial y realizar primer pago:**
16. Sistema detecta primer pago exitoso de referido
17. Sistema actualiza referral.status = "completed"
18. Sistema actualiza referral.completed_at = now
19. Sistema otorga beneficio a referidor según configuración:
    - Si type = "discount": aplica descuento en próxima renovación
    - Si type = "tokens": agrega tokens extra inmediatamente
    - Si type = "credit": agrega crédito a cuenta
20. Sistema otorga beneficio a referido:
    - Aplica descuento según configuración
21. Sistema envía email a referidor: "¡Tu referido ha convertido! Has ganado [beneficio]"
22. Sistema envía email a referido: "¡Has recibido [beneficio]!"
23. Sistema actualiza dashboard de referidos del referidor

**Flujos Alternativos:**

**9a. Referido ya tiene cuenta:**
- 9a.1. Sistema detecta email existente
- 9a.2. Sistema no asocia referido
- 9a.3. Sistema redirige a login
- 9a.4. Referral no se crea
- 9a.5. Fin del caso de uso

**9b. Link expirado o inválido:**
- 9b.1. Sistema muestra mensaje de error
- 9b.2. Sistema permite registro normal sin referido
- 9b.3. Fin del caso de uso

**15a. Referido cancela trial o no convierte:**
- 15a.1. Después de 60 días sin conversión
- 15a.2. Sistema actualiza referral.status = "expired"
- 15a.3. No se otorgan beneficios
- 15a.4. Fin del caso de uso

**19a. Referidor alcanzó límite de referidos:**
- 19a.1. Sistema verifica límite configurado (ej. 10/mes)
- 19a.2. Si alcanzado, no otorga beneficio adicional
- 19a.3. Sistema notifica a referidor del límite
- 19a.4. Continúa con beneficio a referido

**Postcondiciones:**
- Referral registrado en sistema
- Si convierte: Beneficios otorgados a ambas partes
- Dashboard actualizado
- Emails de notificación enviados
- Audit log completo

**Reglas de Negocio:**
- RN-041: Beneficio solo se otorga al PRIMER PAGO del referido
- RN-042: Referido puede ser referido solo una vez
- RN-043: Referidor puede referir múltiples usuarios
- RN-044: Límite de beneficios por referidor configurable
- RN-045: Código de referido único por usuario
- RN-046: Referido debe ser nuevo usuario (email no registrado)

---

### UC-010: Consumo de Tokens y Alertas

**Actores:** Usuario, Sistema

**Precondiciones:**
- Usuario tiene suscripción activa
- Usuario tiene tokens disponibles en período actual

**Flujo Principal:**
1. Usuario utiliza funcionalidad que consume tokens (ej. IA)
2. Sistema verifica tokens disponibles:
   - Obtiene registro actual de tokens_usage
   - Calcula disponibles = total - used
3. Sistema valida que tenga tokens suficientes
4. Sistema decrementa tokens:
   - Incrementa tokens_usage.used
   - Actualiza tokens_usage.updated_at
5. Sistema calcula porcentaje consumido = (used / total) × 100
6. Sistema verifica umbrales de alerta:
   - Si porcentaje >= 50% y no se ha enviado alerta 50%
   - Si porcentaje >= 75% y no se ha enviado alerta 75%
   - Si porcentaje >= 90% y no se ha enviado alerta 90%
   - Si porcentaje = 100% y no se ha enviado alerta 100%
7. Si alcanza umbral:
   - Sistema envía email de alerta
   - Sistema muestra notificación en dashboard
   - Sistema registra alerta enviada (metadata en notifications)
8. Sistema retorna éxito de operación
9. Usuario ve tokens restantes actualizados en dashboard

**Flujos Alternativos:**

**3a. No hay tokens disponibles:**
- 3a.1. Sistema muestra mensaje "Sin tokens disponibles"
- 3a.2. Sistema muestra opciones:
  - Ver cuándo se resetean tokens (next_billing_date)
  - Upgrade a plan superior
  - Comprar tokens adicionales (si disponible)
- 3a.3. Sistema registra intento fallido por falta de tokens
- 3a.4. Fin del caso de uso

**7a. Alerta 50%:**
- 7a.1. Email: "Has consumido 50% de tus tokens mensuales"
- 7a.2. Incluye: tokens restantes, fecha de reseteo, opción de upgrade
- 7a.3. Notificación en dashboard (color amarillo)

**7b. Alerta 75%:**
- 7b.1. Email: "Has consumido 75% de tus tokens mensuales"
- 7b.2. Incluye: tokens restantes, fecha de reseteo, opción de upgrade
- 7b.3. Notificación en dashboard (color naranja)

**7c. Alerta 90%:**
- 7c.1. Email: "¡Atención! Has consumido 90% de tus tokens"
- 7c.2. Incluye: tokens restantes, fecha de reseteo, recomendación upgrade
- 7c.3. Notificación en dashboard (color naranja intenso)

**7d. Alerta 100%:**
- 7d.1. Email: "Has agotado tus tokens mensuales"
- 7d.2. Incluye: fecha de reseteo, opción de upgrade inmediato
- 7d.3. Notificación prominente en dashboard (color rojo)
- 7d.4. Mensaje en cada intento de uso

**Postcondiciones:**
- Tokens decrementados
- Si alcanza umbral: Alerta enviada
- Dashboard actualizado
- Usuario informado del consumo

**Reglas de Negocio:**
- RN-047: Tokens se consumen en tiempo real
- RN-048: Alertas en 50%, 75%, 90%, 100%
- RN-049: Cada alerta se envía solo una vez por período
- RN-050: Al agotar tokens, funcionalidades IA se bloquean
- RN-051: Tokens se resetean automáticamente en renovación
- RN-052: Tokens NO son acumulables entre períodos

---

### UC-011: Solicitar Factura Electrónica

**Actores:** Usuario, Sistema, Admin, PAC/DIAN

**Precondiciones:**
- Usuario tiene pago exitoso registrado
- Usuario completó datos fiscales
- Solicitud dentro del límite de tiempo según país

**Flujo Principal:**
1. Usuario accede a "Historial de Pagos"
2. Sistema muestra lista de pagos
3. Usuario selecciona pago para facturar
4. Sistema verifica si ya tiene factura
5. Si no tiene factura, muestra botón "Solicitar Factura"
6. Usuario hace clic en "Solicitar Factura"
7. Sistema valida datos fiscales completos
8. Sistema valida límite de tiempo según país:
   - México: mismo mes del pago
   - Colombia: máximo 5 días después del pago
9. Sistema muestra resumen:
   - Datos fiscales actuales
   - Monto del pago
   - Fecha del pago
10. Usuario confirma solicitud
11. Sistema crea registro en invoices:
    - user_id, payment_id
    - requested_at = now
    - status = "pending"
12. Sistema envía notificación a Admin
13. Sistema envía email a usuario confirmando solicitud
14. **Admin procesa solicitud:**
15. Admin accede a panel de facturas pendientes
16. Admin revisa datos fiscales y pago
17. Admin genera factura en sistema externo (PAC/DIAN)
18. Admin obtiene PDF (y XML en México)
19. Admin sube archivo(s) a plataforma
20. Sistema guarda file_url
21. Sistema actualiza invoice.status = "generated"
22. Admin hace clic en "Enviar al usuario"
23. Sistema envía email con factura adjunta (PDF)
24. Sistema actualiza invoice.status = "sent"
25. Sistema actualiza invoice.sent_at = now
26. Usuario recibe email con factura
27. Factura disponible en historial para descarga

**Flujos Alternativos:**

**4a. Pago ya tiene factura:**
- 4a.1. Sistema muestra botón "Descargar Factura"
- 4a.2. Usuario descarga PDF existente
- 4a.3. Fin del caso de uso

**7a. Datos fiscales incompletos:**
- 7a.1. Sistema muestra mensaje "Completa datos fiscales"
- 7a.2. Sistema redirige a formulario de datos fiscales
- 7a.3. Usuario completa datos
- 7a.4. Usuario valida y guarda
- 7a.5. Continúa en paso 7

**8a. Fuera de límite de tiempo - México:**
- 8a.1. Sistema verifica: payment.created_at.month != now.month
- 8a.2. Sistema muestra error: "El límite para facturar es el mismo mes del pago"
- 8a.3. Sistema indica fecha límite que se perdió
- 8a.4. Fin del caso de uso

**8b. Fuera de límite de tiempo - Colombia:**
- 8b.1. Sistema verifica: now > payment.created_at + 5 días
- 8b.2. Sistema muestra error: "El límite para facturar es 5 días después del pago"
- 8b.3. Sistema indica fecha límite que se perdió
- 8b.4. Fin del caso de uso

**17a. Error generando factura externa:**
- 17a.1. Admin contacta soporte técnico
- 17a.2. Admin resuelve problema
- 17a.3. Admin reintenta generación
- 17a.4. Continúa en paso 18

**17b. Datos fiscales inválidos detectados:**
- 17b.1. Admin marca invoice como "requiere corrección"
- 17b.2. Sistema notifica a usuario
- 17b.3. Usuario corrige datos
- 17b.4. Usuario solicita nuevamente
- 17b.5. Continúa en paso 11

**Postcondiciones:**
- Solicitud de factura registrada
- Admin notificado
- Factura generada y almacenada
- Factura enviada a usuario
- Disponible para descarga futura
- Audit log completo

**Reglas de Negocio:**
- RN-053: Un pago puede tener solo una factura
- RN-054: México: solicitud en mismo mes del pago
- RN-055: Colombia: solicitud máximo 5 días post-pago
- RN-056: Datos fiscales deben estar completos
- RN-057: Generación externa vía PAC (MX) o DIAN (CO)
- RN-058: PDF almacenado en servidor, accesible vía URL

---

## Casos de Uso - Administrador

### UC-014: Admin - Gestionar Plan de Usuario

**Actores:** Admin, Sistema

**Precondiciones:**
- Admin autenticado con permisos
- Usuario objetivo existe en sistema

**Flujo Principal:**
1. Admin accede a panel de gestión de usuarios
2. Admin busca usuario por email, nombre o ID
3. Sistema muestra lista de resultados
4. Admin selecciona usuario
5. Sistema muestra detalle completo:
   - Datos personales
   - Suscripción actual (plan, status, fechas)
   - Historial de pagos
   - Tokens actuales
   - Cupones aplicados
   - Facturas
6. Admin selecciona acción:
   - Cancelar suscripción
   - Reactivar suscripción
   - Cambiar plan
   - Agregar/quitar tokens
   - Aplicar descuento manual
   - Ver audit log del usuario

**Flujo: Cancelar Suscripción**
7. Admin hace clic en "Cancelar Suscripción"
8. Sistema solicita confirmación y razón
9. Admin confirma y especifica razón
10. Sistema actualiza subscription.status = "cancelled"
11. Sistema actualiza subscription.ends_at = now
12. Sistema envía email a usuario notificando cancelación
13. Sistema registra en audit log (admin_id, acción, razón)

**Flujo: Reactivar Suscripción**
7. Admin hace clic en "Reactivar Suscripción"
8. Sistema verifica si hay deuda pendiente
9. Si hay deuda, solicita confirmación para condonar o cobrar
10. Admin decide acción sobre deuda
11. Sistema actualiza subscription.status = "active"
12. Sistema establece nuevo next_billing_date
13. Sistema envía email a usuario confirmando reactivación
14. Sistema registra en audit log

**Flujo: Cambiar Plan**
7. Admin hace clic en "Cambiar Plan"
8. Sistema muestra lista de planes disponibles
9. Admin selecciona nuevo plan
10. Sistema pregunta si aplicar:
    - Inmediatamente (sin prorrata, admin override)
    - En próxima renovación
11. Admin selecciona opción
12. Sistema aplica cambio según selección
13. Sistema resetea tokens si es inmediato
14. Sistema notifica a usuario
15. Sistema registra en audit log con detalle

**Flujo: Agregar/Quitar Tokens**
7. Admin hace clic en "Gestionar Tokens"
8. Sistema muestra tokens actuales (used/total)
9. Admin ingresa cantidad a agregar (positivo) o quitar (negativo)
10. Admin ingresa razón del ajuste
11. Sistema actualiza tokens_usage.total
12. Sistema registra ajuste en audit log
13. Sistema puede opcionalmente notificar a usuario

**Postcondiciones:**
- Acción ejecutada según flujo seleccionado
- Usuario notificado
- Audit log completo con admin_id y razón
- Cambios visibles en dashboard del usuario

**Reglas de Negocio:**
- RN-059: Todas las acciones de admin quedan en audit log
- RN-060: Razón obligatoria para cambios críticos
- RN-061: Admin puede override reglas de negocio (prorrata, etc.)
- RN-062: Usuario debe ser notificado de cambios por admin

---

### UC-015: Admin - Crear Cupón de Descuento

**Actores:** Admin, Sistema

**Precondiciones:**
- Admin autenticado con permisos de gestión de cupones

**Flujo Principal:**
1. Admin accede a "Gestión de Cupones"
2. Admin hace clic en "Crear Nuevo Cupón"
3. Sistema muestra formulario:
   - Código del cupón (único)
   - Tipo: Porcentaje o Monto Fijo
   - Valor del descuento
   - Duración (meses o permanente)
   - Planes aplicables (todos o específicos)
   - Límite de usos totales (opcional)
   - Fecha de expiración (opcional)
   - Activo (checkbox)
4. Admin completa formulario
5. Sistema valida datos:
   - Código único (no existe)
   - Valor > 0
   - Si porcentaje, valor <= 100
   - Planes seleccionados existen
6. Admin confirma creación
7. Sistema guarda cupón en base de datos
8. Sistema muestra mensaje de éxito
9. Sistema muestra código para compartir
10. Admin puede copiar código o generar reporte

**Flujos Alternativos:**

**5a. Código ya existe:**
- 5a.1. Sistema muestra error "Código ya en uso"
- 5a.2. Admin ingresa código diferente
- 5a.3. Continúa en paso 5

**5b. Valor inválido:**
- 5b.1. Sistema muestra error específico
- 5b.2. Admin corrige valor
- 5b.3. Continúa en paso 5

**Postcondiciones:**
- Cupón creado y disponible
- Si activo = true, usuarios pueden usarlo
- Admin puede editar o desactivar después
- Audit log registrado

**Reglas de Negocio:**
- RN-063: Código debe ser único en sistema
- RN-064: Porcentaje máximo 100%
- RN-065: Duración NULL = permanente
- RN-066: applicable_plans NULL = todos los planes
- RN-067: usage_limit NULL = ilimitado

---

## Casos de Uso - Integraciones

### UC-018: Webhook de Pago Exitoso desde Openpay

**Actores:** Openpay, Sistema

**Precondiciones:**
- Webhook configurado en Openpay
- Pago procesado en Openpay
- Endpoint de webhook accesible

**Flujo Principal:**
1. Openpay procesa cargo exitoso
2. Openpay envía POST request a `https://app.com/webhooks/openpay`
3. Middleware verifica firma HMAC del webhook
4. Middleware verifica IP origen es de Openpay
5. Sistema recibe payload JSON con evento "charge.succeeded"
6. Sistema extrae datos relevantes:
   - transaction_id
   - amount
   - customer_id
   - status
7. Sistema busca payment por transaction_id o crea nuevo
8. Sistema actualiza payment:
   - status = "successful"
   - paid_at = timestamp del webhook
   - openpay_transaction_id = transaction_id
9. Sistema obtiene subscription asociada
10. Sistema actualiza subscription según contexto:
    - Si era trial: status = "active"
    - Si era renovación: mantiene "active", actualiza next_billing_date
    - Si era reactivación: status = "active"
11. Sistema resetea tokens si corresponde (renovación)
12. Sistema dispara eventos:
    - PaymentSuccessful event
    - SubscriptionRenewed event (si renovación)
13. Listeners procesan eventos:
    - Enviar email confirmación
    - Crear solicitud de factura
    - Actualizar métricas
14. Sistema retorna HTTP 200 OK a Openpay
15. Sistema registra webhook en audit log

**Flujos Alternativos:**

**3a. Firma HMAC inválida:**
- 3a.1. Middleware rechaza request
- 3a.2. Sistema retorna HTTP 401 Unauthorized
- 3a.3. Sistema registra intento de webhook inválido
- 3a.4. Sistema alerta a admin de posible ataque
- 3a.5. Fin del caso de uso

**4a. IP no autorizada:**
- 4a.1. Middleware rechaza request
- 4a.2. Sistema retorna HTTP 403 Forbidden
- 4a.3. Sistema registra intento
- 4a.4. Fin del caso de uso

**7a. Payment no encontrado y no se puede crear:**
- 7a.1. Sistema registra error
- 7a.2. Sistema retorna HTTP 200 (para evitar reintentos de Openpay)
- 7a.3. Sistema alerta a admin para revisión manual
- 7a.4. Fin del caso de uso

**14a. Error procesando webhook:**
- 14a.1. Sistema registra error completo
- 14a.2. Sistema retorna HTTP 500 (Openpay reintentará)
- 14a.3. Sistema alerta a admin
- 14a.4. Fin del caso de uso

**Postcondiciones:**
- Pago marcado como exitoso
- Suscripción actualizada
- Tokens reseteados si corresponde
- Eventos disparados
- Email enviado
- Webhook logged
- Openpay recibe confirmación (200 OK)

**Reglas de Negocio:**
- RN-068: Validar firma HMAC obligatorio
- RN-069: Validar IP origen recomendado
- RN-070: Idempotencia: mismo webhook puede llegar múltiples veces
- RN-071: Retornar 200 para evitar reintentos innecesarios
- RN-072: Procesar asíncronamente (queues) para responder rápido

---

### UC-019: Webhook de Pago Fallido desde Openpay

**Actores:** Openpay, Sistema

**Precondiciones:**
- Webhook configurado en Openpay
- Intento de pago falló en Openpay
- Endpoint de webhook accesible

**Flujo Principal:**
1. Openpay intenta procesar cargo y falla
2. Openpay envía POST request a `https://app.com/webhooks/openpay`
3. Middleware verifica firma HMAC del webhook
4. Middleware verifica IP origen
5. Sistema recibe payload JSON con evento "charge.failed"
6. Sistema extrae datos relevantes:
   - transaction_id
   - error_code
   - error_message
   - customer_id
7. Sistema busca payment asociado
8. Sistema actualiza payment:
   - status = "failed"
   - Incrementa attempt
   - Guarda error_code y error_message
9. Sistema crea registro en payment_retries
10. Sistema verifica número de intentos totales
11. Si intentos < 3:
    - Sistema programa siguiente reintento
    - Sistema envía email notificando fallo
12. Si intentos = 3:
    - Sistema inicia período de gracia (UC-004)
13. Sistema dispara evento PaymentFailed
14. Sistema retorna HTTP 200 OK a Openpay
15. Sistema registra webhook en audit log

**Flujos Alternativos:**

**3a/4a. Validación de webhook falla:**
- Ver UC-018 flujos alternativos 3a y 4a

**7a. Payment no encontrado:**
- 7a.1. Sistema busca por customer_id para identificar usuario
- 7a.2. Sistema crea payment si es necesario
- 7a.3. Continúa en paso 8

**11a. Error crítico de tarjeta (ej. robada, inválida):**
- 11a.1. Sistema detecta error_code crítico
- 11a.2. Sistema NO programa reintentos
- 11a.3. Sistema notifica usuario inmediatamente
- 11a.4. Sistema sugiere actualizar método de pago
- 11a.5. Sistema puede iniciar gracia inmediatamente

**Postcondiciones:**
- Pago marcado como fallido
- Reintento programado o gracia iniciada
- Usuario notificado
- Error logged para análisis
- Webhook confirmado a Openpay

**Reglas de Negocio:**
- RN-073: Máximo 3 reintentos automáticos
- RN-074: Errores críticos no generan reintentos
- RN-075: Usuario notificado en cada fallo
- RN-076: Después de 3 fallos, iniciar período de gracia

---

**Documento:** USE_CASES v1.0  
**Fecha:** Enero 2026  
**Próxima Revisión:** Post MVP

