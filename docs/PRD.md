# Documento de Requerimientos Funcionales (PRD)
## Sistema de Planes y Suscripciones - Agenda Médica SaaS

**Versión:** 1.1  
**Fecha:** Enero 2026  
**Actualización:** Integración 3D Secure (3DS)

---

## 📑 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Contexto y Objetivos](#contexto-y-objetivos)
3. [Stakeholders](#stakeholders)
4. [Requerimientos Funcionales](#requerimientos-funcionales)
5. [Requerimientos No Funcionales](#requerimientos-no-funcionales)
6. [User Stories](#user-stories)
7. [Criterios de Aceptación](#criterios-de-aceptacion)
8. [Métricas de Éxito](#metricas-de-exito)
9. [Glosario](#glosario)

---

## Resumen Ejecutivo

El proyecto consiste en implementar un sistema completo de membresías y suscripciones recurrentes para una plataforma SaaS orientada a profesionales de la salud y consultorios médicos pequeños y medianos. El sistema permitirá gestionar planes de pago mensual, anual y anual con cobros mensuales, utilizando **Openpay con 3D Secure (3DS)** como pasarela de pagos, operando en dos países (México y Colombia) con instancias independientes.

**Objetivo principal:** Monetizar la plataforma mediante suscripciones recurrentes con un modelo de negocio basado en consumo de tokens para funcionalidades de IA. 

**Alcance:** MVP en 3-4 meses con funcionalidades críticas, seguido de 2 fases adicionales. 

**⚠️ Consideración Crítica:** La integración debe implementar **3D Secure 2.0** obligatoriamente según requerimientos de Openpay y normativas bancarias de México y Colombia.

---

## Contexto y Objetivos

### Contexto del Negocio

La plataforma actual es un SaaS de gestión médica que permite a profesionales de la salud y consultorios gestionar:  
- Citas médicas
- Calendarios
- Pagos
- Administración operativa

**Necesidad identificada:** Monetizar servicios avanzados de IA mediante un modelo de suscripción con consumo de tokens.

### Objetivos del Proyecto

**Objetivos de Negocio:**
- Generar ingresos recurrentes predecibles (MRR/ARR)
- Escalar a 10,000+ usuarios en los primeros 6 meses
- Operar en México y Colombia simultáneamente
- Reducir churn mediante período de gracia y beneficios de referidos
- Cumplir con regulaciones fiscales y de seguridad (PSD2, 3DS) de ambos países
- Mantener tasa de aprobación de pagos >85% con 3DS

**Objetivos Técnicos:**
- Integración limpia y desacoplada con sistema existente
- Escalabilidad para 10,000+ usuarios
- Alta disponibilidad (99.9% uptime)
- Seguridad PCI-compliant (delegada a Openpay)
- **Implementación correcta de 3D Secure 2.0**
- Arquitectura multi-país (2 instancias independientes)

**Objetivos de Usuario:**
- Experiencia fluida de registro y pago **incluso con autenticación 3DS**
- Transparencia en consumo de tokens
- Flexibilidad en planes y métodos de pago
- Notificaciones oportunas y claras
- Proceso de autenticación bancaria simple y seguro

---

## Stakeholders

| Rol | Responsabilidad | Interés Principal |
|-----|----------------|-------------------|
| **CEO/Founder** | Decisiones estratégicas | ROI, crecimiento de ingresos, reducción fraude |
| **Product Manager** | Definición de features | Experiencia de usuario, cumplimiento roadmap, conversión |
| **Tech Lead** | Arquitectura y desarrollo | Escalabilidad, mantenibilidad, seguridad 3DS |
| **Backend Developers** | Implementación Laravel | Código limpio, APIs robustas, webhooks 3DS |
| **Frontend Developers** | UI/UX Bootstrap | Interfaces responsivas, flujo 3DS optimizado |
| **DevOps** | Infraestructura y deploy | Disponibilidad, performance, monitoreo pagos |
| **Finanzas** | Facturación y contabilidad | Facturación correcta, reportes financieros, conciliación |
| **Soporte** | Atención a usuarios | Herramientas admin eficientes, ayuda con 3DS |
| **Compliance/Legal** | Regulaciones | Cumplimiento normativas, protección datos, 3DS |
| **Usuarios Finales** | Consumidores del servicio | Valor por su dinero, facilidad de uso, seguridad |

---

## Requerimientos Funcionales

### RF-001: Gestión de Usuarios y Roles

**Descripción:** El sistema debe permitir registro, autenticación y gestión de usuarios con 4 roles diferentes.  

**Roles:**
- **Profesional:** Médico individual con su práctica
- **Consultorio:** Entidad con múltiples profesionales
- **Asistente:** Usuario con permisos limitados y customizables, asociado a Profesional/Consultorio
- **Paciente:** Usuario final que agenda citas

**Funcionalidades:**
- Registro con email y contraseña
- Login/Logout
- Recuperación de contraseña
- Perfil de usuario editable
- Asignación de rol en registro
- Captura de datos fiscales (obligatorio para facturación)

**Datos fiscales a capturar:**

**México:**
- RFC
- Razón social
- Régimen fiscal
- Código postal
- Uso de CFDI

**Colombia:**
- NIT
- Razón social
- Tipo de persona (natural/jurídica)
- Dirección completa
- Ciudad/Municipio
- Departamento

---

### RF-002: Gestión de Planes

**Descripción:** El sistema debe ofrecer 3 planes con diferentes cantidades de tokens mensuales. 

**Planes:**
1. **Google Tech + IA 50** (cantidades por definir)
2. **Google Tech + IA 100** (cantidades por definir)
3. **Google Tech + IA 200** (cantidades por definir)

**Periodicidades:**
- **Mensual:** Cobro cada mes
- **Anual:** Cobro único anual (precio con descuento vs mensual)
- **Anual con cobros mensuales:** Compromiso de 12 meses, cobro mensual (precio mensual reducido vs plan mensual sin compromiso)

**Características de planes:**
- Cantidad de tokens mensuales
- Precio en MXN (México)
- Precio en COP (Colombia)
- Días de trial (personalizable por plan)
- Descripción y features incluidos
- Estado:  activo/inactivo

**Reglas:**
- Precios son fijos por moneda (no conversión automática)
- Usuario detectado automáticamente por país/IP
- Tokens no son acumulables entre períodos
- Trial requiere tarjeta de crédito/débito obligatoriamente
- **Primer pago requiere 3D Secure obligatoriamente**

---

### RF-003: Período de Trial

**Descripción:** Cada plan ofrece un período de prueba gratuito personalizable.

**Funcionalidades:**
- Días de trial configurables por plan
- Tokens durante trial = tokens del plan completo
- **Requiere tarjeta guardada con validación 3DS** (cargo de $0-1 para validar)
- Notificación 3 días antes de vencer
- Al vencer, cobra automáticamente si hay tarjeta válida
- Si cobra exitosamente → suscripción activa
- Si falla cobro → aplica lógica de reintentos

**⚠️ Consideración 3DS:**
Durante el registro, el usuario deberá: 
1. Ingresar datos de tarjeta
2. **Completar autenticación 3DS con su banco** (modal/redirect)
3. Una vez autenticado, la tarjeta queda validada y guardada
4. Trial se activa inmediatamente

---

### RF-004: Gestión de Tokens

**Descripción:** Tokens son la unidad de consumo para funcionalidades de IA.  

**Funcionalidades:**
- Tracking de consumo en tiempo real
- Visualización de tokens usados/restantes en panel usuario
- Renovación automática el primer día del período de facturaci��n
- **No acumulables:** Tokens no usados se pierden al renovar
- Alertas automáticas por email al alcanzar:  
  - 50% consumidos
  - 75% consumidos
  - 90% consumidos
  - 100% consumidos (sin tokens)

**Comportamiento al agotar tokens:**
- Usuario NO puede usar funcionalidades que consumen tokens
- Puede esperar hasta renovación
- Puede hacer upgrade inmediato para obtener más tokens

---

### RF-005: Pagos y Métodos de Pago 🔒 **[ACTUALIZADO - 3DS]**

**Descripción:** Integración con Openpay para procesar pagos recurrentes **con 3D Secure obligatorio**.

**Pasarela de Pagos:**
- **Openpay México:** Cuenta separada para MXN
- **Openpay Colombia:** Cuenta separada para COP
- **3D Secure 2.0:** Implementación obligatoria

**Métodos de pago aceptados:**

**1. Tarjeta de crédito/débito (Recurrente - Requerido para trial y suscripciones automáticas):**
- **Tokenización de tarjeta con 3DS** (guardada en Openpay, no en BD local)
- **Primer pago SIEMPRE requiere autenticación 3DS**
- Cobro automático en fecha de renovación
- 3 reintentos automáticos si falla
- **Soporte 3DS 2.0** (modal/iframe, biometría)

**Flujo 3DS en primer pago:**
1. Usuario ingresa datos de tarjeta
2. Sistema solicita cargo a Openpay con `use_3d_secure=true`
3. Openpay devuelve URL de autenticación del banco
4. Frontend muestra modal/iframe con página del banco
5. Usuario se autentica (SMS, app bancaria, biometría)
6. Banco confirma identidad
7. Openpay procesa pago
8. Webhook confirma éxito
9. Tarjeta queda guardada para pagos futuros

**2. Transferencia bancaria (Manual - Opcional):**
- SPEI (México)
- PSE o transferencia directa (Colombia)
- Sistema genera orden de pago con referencia única
- Email con instrucciones, monto, referencia y fecha límite
- Usuario paga manualmente
- Confirmación vía webhook bancario o validación manual
- **No requiere 3DS** (no es pago con tarjeta)

**No se aceptan:**
- OXXO, efectivo en tiendas

**Conversión:**
- Usuario que paga manualmente puede agregar tarjeta después para automatizar renovaciones futuras

**Estados de pago con 3DS:**
- `pending`: Pago creado
- `processing`: Enviado a Openpay
- `requires_3ds`: Requiere autenticación del usuario
- `authenticating`: Usuario en proceso de autenticación
- `authenticated`: Autenticación exitosa
- `completed`: Pago completado
- `failed`: Pago fallido (fondos, 3DS fallido, etc.)

---

### RF-006: Renovaciones Automáticas 🔒 **[ACTUALIZADO - MIT/3DS]**

**Descripción:** Cobro automático recurrente según periodicidad del plan, **con soporte MIT (Merchant Initiated Transaction)**.

**Flujo:**
1. **Fecha de renovación alcanzada**
2. **Intento de cobro automático con MIT** (sin 3DS, si el banco lo permite)
   - Marcado como `merchant_initiated=true`
   - Marcado como `mit_type=recurring`
3. **Respuesta de Openpay:**
   
   **a) Exitoso (MIT aceptado):**
   - Renovar suscripción
   - Resetear tokens al valor del plan
   - Enviar confirmación por email
   - Marcar para generación de factura
   
   **b) Fallo:  Requiere 3DS:**
   - Banco rechaza MIT y solicita autenticación del usuario
   - Marcar pago como `requires_3ds`
   - **Enviar notificación urgente al usuario:** "Tu pago requiere autenticación"
   - Usuario tiene 24h para ingresar y autenticar
   - Si autentica:  pago se completa
   - Si NO autentica: pasa a lógica de reintentos
   
   **c) Fallo: Otros (fondos insuficientes, tarjeta expirada):**
   - Iniciar proceso de reintentos (RF-007)

**Recordatorios:**
- Email configurable X días antes del cobro (parámetro global)

**⚠️ MIT (Merchant Initiated Transaction):**
- **Exención de 3DS** para pagos recurrentes
- Solo aplica si el primer pago tuvo 3DS exitoso
- El banco **puede** rechazarlo y pedir 3DS de todos modos
- Aumenta tasa de éxito de renovaciones automáticas

---

### RF-007: Manejo de Fallos de Pago 🔒 **[ACTUALIZADO - Distinguir 3DS]**

**Descripción:** Sistema de reintentos y período de gracia para retener usuarios, **distinguiendo fallos por 3DS vs otros tipos**. 

**Flujo de fallos:**

**1. Clasificación del fallo:**

El sistema debe identificar el tipo de fallo: 
- **Fallo tipo A:  Requiere 3DS** (código Openpay:  `3001`, `3002`)
- **Fallo tipo B: Fondos insuficientes** (código:  `1001`)
- **Fallo tipo C: Tarjeta expirada/inválida** (código: `1005`, `1006`)
- **Fallo tipo D: Otros errores técnicos**

**2. Manejo según tipo:**

**Fallo Tipo A (Requiere 3DS):**
```
1. Marcar pago como `requires_3ds`
2. Enviar email #20: "Acción requerida: Autentica tu pago"
3. Usuario tiene 24h para ingresar y autenticar
4. Si autentica → Pago exitoso → Renovación
5. Si NO autentica en 24h → Contar como primer intento fallido → Continuar con Tipo B/C
```

**Fallo Tipo B/C (Fondos, Tarjeta):**
```
Primer fallo: 
- Reintento automático en 3 días
- Email de alerta al usuario

Segundo fallo:
- Segundo reintento en 5 días
- Email urgente con instrucciones

Tercer fallo:
- Tercer reintento en 7 días
- Email muy urgente

Después de 3 fallos:
- Entra en Período de Gracia (2 meses)
- Usuario mantiene acceso completo a tokens durante estos 2 meses
- Notificaciones cada 15 días (configurable) recordando pago pendiente
- Usuario puede: 
  * Actualizar tarjeta y pagar manualmente
  * Hacer pago manual con transferencia
  * Si el fallo fue por 3DS:  Autenticar el pago pendiente

Después de 2 meses sin pago:
- Bloqueo de acceso
- Deuda acumulada registrada
- Usuario puede reactivar pagando lo adeudado
```

**Para Plan Anual con Cobros Mensuales:**
- Mismo flujo de reintentos y gracia
- Deuda se acumula mes a mes
- Compromiso de 12 meses persiste (no se puede cancelar anticipadamente sin penalización)

---

### RF-008: Cambio de Plan (Upgrade)

**Descripción:** Usuario puede subir de plan en cualquier momento. 

**Flujo:**
1. Usuario solicita upgrade
2. Sistema calcula **prorrata:**
   - Días restantes del período actual
   - Diferencia de precio entre planes
   - Cargo = (Precio nuevo plan - Precio plan actual) × (Días restantes / Días totales del período)
3. **Cobra inmediatamente la diferencia prorrateada**
   - **⚠️ Puede requerir 3DS** si el banco lo solicita
   - Usuario debe completar autenticación si es requerida
4. **Resetea tokens** a 0 usados / Tokens del nuevo plan disponibles
5. Actualiza suscripción al nuevo plan
6. Próxima renovación será por el monto completo del nuevo plan

**Ejemplo:**
- Plan actual:  Básico ($100 MXN/mes, 1,000 tokens)
- Día 15 del mes, usó 500 tokens
- Upgrade a Pro ($300 MXN/mes, 5,000 tokens)
- Cargo inmediato: ~$100 MXN (15 días restantes)
- **Si requiere 3DS:** Usuario autentica en modal
- Tokens:  0 usados / 5,000 disponibles
- Próximo cobro (día 15 del mes siguiente): $300 MXN completos

---

### RF-009: Cambio de Plan (Downgrade)

**Descripción:** Usuario puede bajar de plan.  

**Flujo:**
1. Usuario solicita downgrade
2. **No se aplica inmediatamente**
3. Se **programa para fin del período actual**
4. Usuario sigue con plan actual hasta fecha de renovación
5. En renovación: 
   - Cambia al nuevo plan
   - Cobra monto del nuevo plan (menor)
   - Tokens del nuevo plan (menor cantidad)

**Ejemplo:**
- Plan actual: Pro ($300 MXN/mes, 5,000 tokens)
- Día 20, usó 3,000 tokens
- Solicita downgrade a Básico ($100 MXN/mes, 1,000 tokens)
- Sigue con Pro hasta fin de mes (puede usar sus 2,000 tokens restantes)
- Día 1 del siguiente mes: cambia a Básico, cobra $100, tiene 1,000 tokens

---

### RF-010: Cancelación de Suscripción

**Descripción:** Usuario puede cancelar su suscripción.  

**Tipos de cancelación:**

**1. Plan Mensual o Anual (sin compromiso):**
- Usuario solicita cancelación
- **No cancela inmediatamente**
- Acceso se mantiene hasta fin del período pagado
- No se renueva automáticamente
- Email de confirmación y encuesta de salida (opcional)

**2. Plan Anual con Cobros Mensuales (con compromiso de 12 meses):**
- Usuario solicita cancelación
- **Se cancela solo la renovación** (después de 12 meses)
- **Compromiso de 12 meses persiste**
- Debe seguir pagando los meses restantes hasta completar 12
- Si no paga → aplica RF-007 (deuda acumulada)

**Reactivación:**
- Usuario puede reactivar antes de que expire el período
- Si ya expiró → debe crear nueva suscripción (se pierde precio/descuento anterior)

---

### RF-011: Descuentos y Cupones

**Descripción:** Sistema de cupones para aplicar descuentos.

**Tipos de descuento:**
- **Porcentaje:** Ej:  20% off
- **Precio fijo:** Ej: $50 MXN de descuento

**Configuración de cupón:**
- Código único (ej:  PROMO2026)
- Tipo (porcentaje o fijo)
- Valor
- Duración:  
  - Permanente (mientras mantenga suscripción)
  - Temporal (ej: solo primeros 3 meses)
  - Configurable por cupón
- Aplicabilidad:
  - Todos los planes
  - Planes específicos (ej: solo Plan Pro)
- Límite de usos totales (ej: solo 100 personas)
- Fecha de expiración
- Estado: activo/inactivo

**Reglas:**
- **No acumulables:** Solo un cupón activo por usuario
- Un usuario puede usar un cupón **una sola vez** (no puede cancelar y reusar)
- Cupones de un solo uso:  códigos únicos generados para usuarios específicos

**Validación:**
- Cupón existe
- Está activo
- No ha expirado
- Aplica al plan seleccionado
- No ha alcanzado límite de usos
- Usuario no lo ha usado previamente

---

### RF-012: Sistema de Referidos

**Descripción:** Programa de incentivos para que usuarios inviten a otros.

**Mecánica:**
- Cada usuario tiene:  
  - **Código de referido único** (ej: CESAR2026)
  - **Link de referido único** (ej: app.com/register? ref=abc123)
- Usuario comparte código/link con amigos
- Amigo se registra usando el código/link
- **Beneficios se otorgan al primer pago del referido** (después de trial)

**Beneficios del Referidor (quien invita):**
- Descuento (ej: 20% off por 1 mes)
- Tokens extra (ej: 1,000 tokens bonus)
- Crédito en plataforma (ej: $100 MXN para pagar futuras facturas)
- **Configurable** por administrador

**Beneficios del Referido (quien fue invitado):**
- Descuento (ej: 10% off primer mes)

**Reglas:**
- **Beneficio único:** Por cada referido, se otorga una vez
- **Repetible:** Puede referir múltiples amigos, gana por cada uno
- **Límite configurable:** Ej: máximo 10 referidos por usuario (opcional)

**Tracking:**
- Dashboard de referidos para el usuario (cuántos ha referido, beneficios ganados)
- Admin puede ver árbol de referidos

---

### RF-013: Facturación Electrónica

**Descripción:** Generación y envío de facturas electrónicas según normativa de cada país.

**Proceso:**
1. Usuario completa pago
2. **Solicitud de factura:**
   - Usuario puede solicitar factura desde su panel
   - Límite de tiempo: 
     - **México:** Mismo mes del pago
     - **Colombia:** Hasta 5 días después del pago
3. Sistema valida:
   - Datos fiscales completos
   - Dentro del límite de tiempo
4. **Generación externa:**
   - Factura se genera en software externo (PAC para México, sistema DIAN para Colombia)
   - Administrador genera PDF
5. **Carga a plataforma:**
   - Admin sube factura PDF al sistema
   - Asocia con pago correspondiente
6. **Envío:**
   - Sistema envía email a usuario con factura adjunta
   - Factura disponible para descarga en panel usuario

**Datos fiscales validados:**
- México: RFC válido, régimen fiscal, uso de CFDI seleccionado
- Colombia: NIT válido, tipo de persona, dirección completa

**Histórico:**
- Usuario puede ver todas sus facturas en su panel
- Admin puede buscar facturas por usuario, fecha, monto

---

### RF-014: Notificaciones por Email 🔒 **[ACTUALIZADO - +1 email 3DS]**

**Descripción:** Sistema completo de notificaciones transaccionales.

**18 Notificaciones MVP:**

| # | Tipo | Trigger | Configurable | **3DS** |
|---|------|---------|--------------|---------|
| 1 | Bienvenida | Registro completado | No | - |
| 2 | Confirmación de pago | Pago exitoso | No | ✅ |
| 3 | Recordatorio de cobro | X días antes de renovación | Sí (días) | - |
| 4 | Fallo de pago | Intento de cobro fallido | No | - |
| 5 | Orden de pago manual | Transferencia generada | No | - |
| 6 | Entrada en período de gracia | Después de 3 fallos | No | - |
| 7-N | Recordatorios en gracia | Cada 15 días durante gracia | Sí (frecuencia) | - |
| 8 | Cancelación de suscripción | Usuario cancela | No | - |
| 9 | Cambio de plan | Upgrade/Downgrade | No | ✅ |
| 10 | Referido exitoso | Referido hace primer pago | No | - |
| 11 | Código de descuento (referido) | Referido se registra | No | - |
| 12 | Factura disponible | Admin sube factura | No | - |
| 13 | Tokens 50% | Consume 50% de tokens | No | - |
| 14 | Tokens 75% | Consume 75% de tokens | No | - |
| 15 | Tokens 90% | Consume 90% de tokens | No | - |
| 16 | Tokens 100% | Agota tokens | No | - |
| 17 | Trial próximo a vencer | 3 días antes | No | - |
| 18 | Trial vencido | Trial finaliza | No | ✅ |
| 19 | Reactivación | Paga deuda y reactiva | No | - |
| **20** | **🆕 Autenticación de pago requerida** | **Pago requiere 3DS** | **No** | **✅** |

**Email #20:  Autenticación de Pago Requerida (NUEVO)**

```
Asunto: 🔒 Acción requerida: Autentica tu pago de [Plan]

Hola [Nombre],

Tu pago de [Monto] [Moneda] para la renovación de tu plan [Plan] 
requiere autenticación adicional por seguridad de tu banco.

Por favor, haz clic en el botón de abajo para completar la 
autenticación en tu banco (toma menos de 1 minuto):

[Botón:  Autenticar mi pago ahora]

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

**Diseño:**
- Templates responsivos (HTML + texto plano)
- Branding consistente
- CTAs claros
- Unsubscribe donde aplique (marketing, no transaccionales)
- Tracking de envío (logs)

---

### RF-015: Panel de Administración

**Descripción:** Dashboard completo para gestión del sistema (Laravel 10 independiente).

**Módulos principales:**

**1. Dashboard:**
- Métricas en tiempo real:  
  - Usuarios totales, activos, en trial, cancelados
  - Suscripciones activas por plan
  - MRR (Monthly Recurring Revenue)
  - ARR (Annual Recurring Revenue)
  - Churn rate
  - Tasa de conversión trial → pago
  - **🆕 Tasa de aprobación con 3DS**
  - **🆕 Tasa de abandono en autenticación 3DS**
  - **🆕 % de pagos que requirieron 3DS**
- Gráficas de tendencias

**2. Gestión de Usuarios:**
- Listar usuarios con filtros (rol, país, plan, estado)
- Ver detalle de usuario
- Historial completo (pagos, cambios plan, tokens)
- Cancelar/reactivar suscripción manualmente
- Cambiar plan de usuario
- Ajustar tokens manualmente (ej: compensación)
- Ver datos fiscales
- **🆕 Ver historial de autenticaciones 3DS**

**3. Gestión de Planes:**
- CRUD completo de planes
- Activar/desactivar planes
- Configurar precios por país y periodicidad
- Configurar tokens mensuales
- Configurar días de trial

**4. Gestión de Cupones:**
- CRUD completo de cupones
- Ver estadísticas de uso
- Activar/desactivar cupones
- Generar códigos únicos en lote

**5. Gestión de Descuentos Manuales:**
- Aplicar descuento específico a un usuario
- Porcentaje o monto fijo
- Duración específica

**6. Gestión de Pagos:**
- Historial completo de transacciones
- Filtros avanzados
- Procesar reembolsos
- Ver intentos de pago y reintentos
- Gestión de órdenes de pago manual
- **🆕 Ver estado 3DS de cada pago**
- **🆕 Logs de webhooks 3DS**
- **🆕 Filtro por pagos que requirieron 3DS**

**7. Gestión de Período de Gracia:**
- Listar usuarios en gracia
- Ver deuda acumulada
- Ver notificaciones enviadas
- Acciones manuales (perdonar deuda, extender gracia)
- **🆕 Distinguir si gracia fue por fallo 3DS o fondos**

**8. Gestión de Referidos:**
- Ver árbol de referidos
- Estadísticas de programa
- Beneficios otorgados

**9. Gestión de Facturas:**
- Ver solicitudes pendientes
- Subir facturas PDF
- Enviar facturas por email
- Histórico completo

**10. Logs y Eventos:**
- Ver logs de webhooks de Openpay
- **🆕 Logs específicos de eventos 3DS**
- Logs de errores
- Auditoría de acciones de admin

**11. Reportes:**
- MRR por mes
- ARR
- Churn rate
- Conversión trial
- Distribución de planes
- **🆕 Impacto de 3DS en conversión**
- **🆕 Tasa de éxito/fallo por banco emisor**
- Exportación a CSV/Excel

**12. Configuración Global:**
- Parámetros del sistema (días recordatorio, frecuencia gracia, etc.)
- Configuración de emails (SMTP)
- Configuración Openpay (keys sandbox/producción)
- **🆕 Configuración 3DS (timeout, reintentos)**

**Seguridad:**
- Autenticación robusta
- Roles de admin (Superadmin, Admin, Soporte, Finanzas)
- Logs de auditoría de todas las acciones

---

## Requerimientos No Funcionales

### RNF-001: Performance
- Tiempo de respuesta de APIs: < 500ms (p95)
- Tiempo de carga de páginas: < 2 segundos
- Procesamiento de webhooks: < 100ms
- **🆕 Carga de modal 3DS:  < 1 segundo**

### RNF-002: Escalabilidad
- Soportar 10,000+ usuarios concurrentes
- Crecimiento horizontal (instancias separadas por país)
- Queue workers escalables
- **🆕 Manejo de picos de autenticaciones 3DS**

### RNF-003: Disponibilidad
- Uptime: 99.9% (máximo 43 minutos de downtime al mes)
- Backup diario de base de datos
- Recuperación ante desastres:  RTO < 4 horas
- **🆕 Monitoreo de disponibilidad de servicio 3DS de Openpay**

### RNF-004: Seguridad 🔒 **[ACTUALIZADO - 3DS]**
- HTTPS obligatorio
- **No almacenar datos de tarjetas** (delegado a Openpay - PCI compliant)
- **Implementación de 3D Secure 2.0** (autenticación adicional obligatoria)
- Encriptación de datos sensibles en BD
- Protección contra inyección SQL, XSS, CSRF
- Rate limiting en APIs (100 req/min por IP)
- Logs de auditoría completos
- **Validación de firma de webhooks de Openpay**
- Cumplimiento:  
  - Ley Federal de Protección de Datos Personales en Posesión de Particulares (México)
  - Ley Estatutaria 1581 de 2012 - Habeas Data (Colombia)
  - **PSD2 compliance (3DS)**

### RNF-005: Usabilidad
- Interfaz responsive (mobile, tablet, desktop)
- Navegación intuitiva
- Mensajes de error claros
- Confirmaciones de acciones críticas
- **🆕 Flujo 3DS optimizado para UX (modal, no redirect completo)**
- **🆕 Mensajes tranquilizadores durante autenticación bancaria**

### RNF-006: Mantenibilidad
- Código documentado (PHPDoc)
- Arquitectura modular y desacoplada
- Tests automatizados (cobertura >70%)
- Logs estructurados
- **🆕 Tests específicos para flujos 3DS**

### RNF-007: Compatibilidad
- Navegadores:  Chrome, Firefox, Safari, Edge (últimas 2 versiones)
- Dispositivos:  Responsive desde 320px
- Laravel 10+, PHP 8.1+, MySQL 8.0+
- **🆕 Soporte para 3DS 1.0 y 2.0**
- **🆕 Compatible con apps bancarias móviles (deep linking)**

### RNF-008: Observabilidad
- Monitoreo de errores (Sentry o similar)
- Logs centralizados
- Métricas de negocio en tiempo real
- **🆕 Dashboards de métricas 3DS (tasa aprobación, abandono, tiempo)**
- **🆕 Alertas automáticas si tasa de fallo 3DS > 20%**

---

## User Stories

### Epic 1: Onboarding y Trial

**US-001: Como usuario nuevo, quiero registrarme seleccionando un plan para empezar a usar la plataforma** 🔒 **[ACTUALIZADO]**
- **Criterios de aceptación:**
  - Puedo ver los 3 planes con sus características
  - Puedo seleccionar periodicidad (mensual, anual, anual con cobros mensuales)
  - Completo formulario de registro (nombre, email, contraseña, rol)
  - Completo datos fiscales
  - Agrego tarjeta de crédito/débito
  - **🆕 Completo autenticación 3DS con mi banco (modal/iframe)**
  - **🆕 Veo mensajes tranquilizadores durante proceso 3DS**
  - Trial se activa inmediatamente después de autenticación exitosa
  - Recibo email de bienvenida
- **Prioridad:** Alta
- **Estimación:** 13 puntos (era 8, +5 por 3DS)

**US-002: Como usuario en trial, quiero ser notificado antes de que mi trial venza para decidir si continuar**
- **Criterios de aceptación:**
  - Recibo email 3 días antes de vencer
  - Email indica fecha exacta de vencimiento y monto a cobrar
  - Puedo cancelar antes del cobro si no deseo continuar
- **Prioridad:** Alta
- **Estimación:** 3 puntos

---

### Epic 2: Pagos y Suscripciones

**US-003: Como usuario con suscripción activa, quiero que mi renovación sea automática para no interrumpir mi servicio** 🔒 **[ACTUALIZADO]**
- **Criterios de aceptación:**
  - Sistema cobra automáticamente en fecha de renovación
  - **🆕 Si el banco acepta MIT, no requiere 3DS**
  - **🆕 Si el banco requiere 3DS, recibo email para autenticar**
  - Recibo email de confirmación de pago
  - Mis tokens se resetean al valor de mi plan
  - Factura se genera automáticamente
- **Prioridad:** Crítica
- **Estimación:** 21 puntos (era 13, +8 por flujo 3DS MIT)

**US-004: Como usuario sin tarjeta, quiero pagar con transferencia bancaria**
- **Criterios de aceptación:**
  - Puedo seleccionar "transferencia" como método de pago
  - Recibo email con referencia única, monto y fecha límite
  - Al completar transferencia, mi suscripción se activa
  - Recibo confirmación
- **Prioridad:** Media
- **Estimación:** 8 puntos

**US-005: Como usuario cuyo pago falló, quiero tener tiempo para solucionar el problema sin perder acceso**
- **Criterios de aceptación:**
  - Sistema reintenta cobro 3 veces
  - Recibo notificaciones de cada fallo
  - Entro en período de gracia de 2 meses con acceso completo
  - Recibo recordatorios cada 15 días
  - Puedo actualizar tarjeta y pagar manualmente
- **Prioridad:** Alta
- **Estimación:** 13 puntos

**🆕 US-006: Como usuario, cuando mi pago requiere autenticación adicional, quiero un proceso simple para completarlo**
- **Criterios de aceptación:**
  - **Recibo email con link claro:  "Autentica tu pago"**
  - **Hago clic y veo página explicando el proceso**
  - **Completo autenticación en modal/iframe (no salgo del sitio)**
  - **Veo confirmación inmediata al completar**
  - **Si fallo, puedo reintentar fácilmente**
  - **Recibo email de confirmación después de autenticar**
- **Prioridad:** Alta
- **Estimación:** 8 puntos

---

### Epic 3: Gestión de Tokens

**US-007: Como usuario, quiero ver cuántos tokens me quedan en tiempo real**
- **Criterios de aceptación:**
  - Dashboard muestra tokens usados/totales
  - Barra de progreso visual
  - Actualización en tiempo real al consumir
- **Prioridad:** Alta
- **Estimación:** 5 puntos

**US-008: Como usuario, quiero ser alertado cuando esté por agotar mis tokens**
- **Criterios de aceptación:**
  - Recibo email al 50%, 75%, 90% y 100% de consumo
  - Emails sugieren hacer upgrade si necesito más
- **Prioridad:** Alta
- **Estimación:** 5 puntos

---

### Epic 4: Cambios de Plan

**US-009: Como usuario, quiero hacer upgrade inmediato para obtener más tokens ahora** 🔒 **[ACTUALIZADO]**
- **Criterios de aceptación:**
  - Puedo seleccionar nuevo plan desde mi panel
  - Veo cálculo de prorrata antes de confirmar
  - **🆕 Si requiere 3DS, completo autenticación en modal**
  - Al confirmar, se cobra inmediatamente
  - Mis tokens se resetean al nuevo plan
  - Recibo confirmación
- **Prioridad:** Alta
- **Estimación:** 13 puntos (era 8, +5 por 3DS)

**US-010: Como usuario, quiero hacer downgrade para ahorrar en mi próxima renovación**
- **Criterios de aceptación:**
  - Puedo seleccionar plan menor
  - Sistema me informa que aplicará al fin del período actual
  - Puedo seguir usando mi plan actual hasta entonces
  - Recibo confirmación del cambio programado
- **Prioridad:** Media
- **Estimación:** 5 puntos

---

### Epic 5: Descuentos y Referidos

**US-011: Como usuario, quiero aplicar un cupón de descuento para pagar menos**
- **Criterios de aceptación:**
  - Puedo ingresar código de cupón al seleccionar plan
  - Sistema valida y muestra precio con descuento
  - Descuento se aplica según duración configurada
  - Recibo confirmación
- **Prioridad:** Media
- **Estimación:** 8 puntos

**US-012: Como usuario, quiero invitar amigos y recibir beneficios**
- **Criterios de aceptación:**
  - Tengo un código y link único de referido
  - Puedo compartir fácilmente
  - Veo cuántos amigos he referido
  - Cuando amigo paga, recibo mi beneficio (descuento/tokens/crédito)
  - Recibo notificación
- **Prioridad:** Media
- **Estimación:** 13 puntos

---

### Epic 6: Facturación

**US-013: Como usuario, quiero solicitar mi factura electrónica**
- **Criterios de aceptación:**
  - Puedo solicitar factura desde mi panel
  - Sistema valida que esté dentro del plazo
  - Solicitud llega a admin
  - Cuando esté lista, recibo email con PDF
  - Puedo descargar desde mi panel
- **Prioridad:** Alta
- **Estimación:** 8 puntos

---

### Epic 7: Panel Admin

**US-014: Como administrador, quiero ver métricas clave del negocio** 🔒 **[ACTUALIZADO]**
- **Criterios de aceptación:**
  - Dashboard muestra MRR, ARR, usuarios activos, churn
  - **🆕 Veo tasa de aprobación de pagos con 3DS**
  - **🆕 Veo tasa de abandono en autenticación**
  - **🆕 Veo % de pagos que requirieron 3DS**
  - Gráficas de tendencias
  - Actualización en tiempo real
- **Prioridad:** Alta
- **Estimación:** 13 puntos

**US-015: Como administrador, quiero gestionar suscripciones de usuarios manualmente**
- **Criterios de aceptación:**
  - Puedo buscar usuario
  - Puedo cancelar/reactivar suscripción
  - Puedo cambiar plan
  - Puedo ajustar tokens
  - Todas las acciones quedan registradas en logs
- **Prioridad:** Alta
- **Estimación:** 13 puntos

**US-016: Como administrador, quiero crear cupones de descuento para campañas**
- **Criterios de aceptación:**
  - Puedo crear cupón con código único
  - Configuro tipo, valor, duración, límites
  - Puedo ver estadísticas de uso
  - Puedo activar/desactivar
- **Prioridad:** Media
- **Estimación:** 8 puntos

**🆕 US-017: Como administrador, quiero monitorear el rendimiento de 3DS para optimizar conversión**
- **Criterios de aceptación:**
  - **Veo dashboard con métricas 3DS**
  - **Filtro por banco emisor para identificar problemas**
  - **Veo logs de webhooks 3DS**
  - **Recibo alertas si tasa de fallo > umbral**
  - **Puedo exportar reportes**
- **Prioridad:** Media
- **Estimación:** 8 puntos

---

## Criterios de Aceptación Generales

### Funcionales
- Todas las user stories implementadas según especificación
- Flujos completos testeados (end-to-end)
- Notificaciones enviadas correctamente
- Facturación funcional en ambos países
- Integración Openpay operativa con webhooks
- **🆕 3D Secure implementado correctamente (1.0 y 2.0)**
- **🆕 MIT funcionando para pagos recurrentes**
- **🆕 Manejo correcto de todos los estados 3DS**

### Técnicos
- Tests unitarios con >70% cobertura
- Tests de integración para flujos críticos
- **🆕 Tests específicos para todos los escenarios 3DS**
- Performance según RNF (< 500ms p95)
- Sin errores críticos en producción
- Documentación técnica completa
- **🆕 Logs estructurados de eventos 3DS**

### UX
- Interfaz responsive validada en dispositivos
- Navegación intuitiva (test con usuarios)
- Mensajes de error claros y accionables
- Confirmaciones de acciones críticas
- **🆕 Flujo 3DS intuitivo y tranquilizador**
- **🆕 Timeouts manejados elegantemente**
- **🆕 Mensajes de ayuda durante autenticación**

### Seguridad
- Penetration testing básico pasado
- Encriptación HTTPS
- No almacenamiento de datos de tarjetas
- Validaciones de entrada completas
- **🆕 Firma de webhooks validada**
- **🆕 Compliance con normativas 3DS/PSD2**

---

## Métricas de Éxito

### Métricas de Negocio

| Métrica | Objetivo Año 1 | Medición |
|---------|----------------|----------|
| **MRR** | $50,000 USD | Ingresos recurrentes mensuales |
| **ARR** | $600,000 USD | Ingresos recurrentes anuales |
| **Usuarios activos** | 10,000+ | Usuarios con suscripción activa |
| **Tasa de conversión trial** | >30% | % de trials que se convierten a pago |
| **Churn rate** | <5% mensual | % de usuarios que cancelan por mes |
| **LTV / CAC** | >3:1 | Lifetime Value vs Customer Acquisition Cost |
| **Tiempo en período de gracia** | <15 días promedio | Tiempo que tardan en pagar usuarios en gracia |
| **🆕 Tasa de aprobación con 3DS** | **>85%** | **% de pagos 3DS exitosos** |
| **🆕 Tasa de abandono en 3DS** | **<10%** | **% usuarios que abandonan en autenticación** |

### Métricas de Producto

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| **Tiempo de registro** | <4 minutos | Desde landing hasta trial activo (era 3 min, +1 por 3DS) |
| **Uso de referidos** | >20% usuarios | % de usuarios que refieren al menos 1 amigo |
| **Uso de cupones** | >40% nuevos usuarios | % que usan cupón en primer pago |
| **Upgrades** | >15% usuarios | % que hace upgrade después de trial |
| **🆕 Tiempo promedio autenticación 3DS** | **<2 minutos** | **Tiempo desde inicio 3DS hasta completar** |
| **🆕 Tasa de éxito MIT** | **>70%** | **% renovaciones sin requerir 3DS** |

### Métricas Técnicas

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| **Uptime** | 99.9% | Disponibilidad mensual |
| **Latencia API** | <500ms p95 | Tiempo de respuesta percentil 95 |
| **Tasa de éxito pagos** | >85% | % de cobros exitosos (considerando 3DS) |
| **Tiempo resolución webhooks** | <100ms | Procesamiento de eventos Openpay |
| **🆕 Disponibilidad servicio 3DS** | **99%** | **Uptime del servicio 3DS de Openpay** |

---

## Glosario

- **3DS / 3D Secure:** Protocolo de autenticación adicional para pagos con tarjeta
- **MIT (Merchant Initiated Transaction):** Exención de 3DS para pagos recurrentes
- **MRR:** Monthly Recurring Revenue (Ingresos recurrentes mensuales)
- **ARR:** Annual Recurring Revenue (Ingresos recurrentes anuales)
- **Churn:** Tasa de cancelación de usuarios
- **LTV:** Lifetime Value (Valor de tiempo de vida del cliente)
- **CAC:** Customer Acquisition Cost (Costo de adquisición de cliente)
- **Trial:** Período de prueba gratuito
- **Prorrata:** Cálculo proporcional de cobro por días restantes
- **Webhook:** Notificación HTTP de eventos desde servicio externo
- **Token:** Unidad de consumo para funcionalidades de IA
- **PAC:** Proveedor Autorizado de Certificación (facturación México)
- **DIAN:** Dirección de Impuestos y Aduanas Nacionales (Colombia)
- **CFDI:** Comprobante Fiscal Digital por Internet (factura electrónica México)

---

## Referencias

- [Documentación Openpay México](https://www.openpay.mx/docs/)
- [Documentación Openpay Colombia](https://www.openpay.co/docs/)
- **[Documentación 3D Secure Openpay](https://www.openpay.mx/docs/3d-secure. html)**
- [SAT - Facturación Electrónica México](https://www.sat.gob.mx/)
- [DIAN - Facturación Electrónica Colombia](https://www.dian.gov.co/)
- **[Documentación Interna:  3DS Integration](./3DS_INTEGRATION.md)**

---

**Cambios en v1.1:**
- ✅ Agregado RF-005: Integración 3D Secure obligatoria
- ✅ Actualizado RF-006: MIT para renovaciones automáticas
- ✅ Actualizado RF-007: Distinción de fallos por 3DS
- ✅ Actualizado RF-014: Email #20 autenticación requerida
- ✅ Actualizado RNF-004: Seguridad con 3DS 2.0
- ✅ Agregadas user stories US-006, US-017 relacionadas con 3DS
- ✅ Actualizadas estimaciones de user stories afectadas por 3DS
- ✅ Agregadas métricas de éxito específicas de 3DS
- ✅ Actualizado glosario con términos 3DS

---

**Fin del Documento**