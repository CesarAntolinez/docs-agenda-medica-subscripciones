# 📋 Product Requirements Document (PRD)
## Sistema de Planes y Suscripciones - Plataforma SaaS de Gestión Médica

---

## 📑 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Contexto y Objetivos](#contexto-y-objetivos)
3. [Stakeholders](#stakeholders)
4. [Requerimientos Funcionales](#requerimientos-funcionales)
5. [Requerimientos No Funcionales](#requerimientos-no-funcionales)
6. [User Stories](#user-stories)
7. [Criterios de Aceptación](#criterios-de-aceptación)
8. [Métricas de Éxito](#métricas-de-éxito)
9. [Glosario](#glosario)

---

## Resumen Ejecutivo

El Sistema de Planes y Suscripciones es un módulo crítico para la plataforma SaaS de gestión médica que opera en México y Colombia. Este sistema permitirá la gestión completa del ciclo de vida de suscripciones recurrentes basadas en consumo de tokens para funcionalidades de inteligencia artificial.

**Objetivo Principal:** Implementar un sistema robusto de suscripciones que soporte pagos recurrentes, consumo de tokens, facturación electrónica cumpliendo con regulaciones locales, y gestión completa del ciclo de vida del cliente.

**Alcance:** MVP funcional en 3-4 meses con capacidad para escalar a 10,000+ usuarios en 6 meses.

**Impacto Esperado:** Monetización efectiva de la plataforma con ingresos recurrentes predecibles, alta retención de usuarios y experiencia de pago fluida.

---

## Contexto y Objetivos

### Contexto del Proyecto

**Plataforma Actual:**
- SaaS para profesionales de salud y consultorios médicos
- Funcionalidades: Gestión de citas, calendarios, pagos, administración
- Operación en dos mercados: México y Colombia
- Base de usuarios estimada: 10,000+ en 6 meses

**Arquitectura Técnica:**
- **Backend:** Laravel 8 (migración planificada a Laravel 10)
- **Frontend:** Bootstrap 4.6
- **Base de Datos:** MySQL (instancias separadas por país)
- **Pasarela de Pagos:** Openpay con cuentas separadas MXN/COP
- **Hosting:** Latinoamericana Hosting (compartido, migración a VPS recomendada)
- **Panel Admin:** Laravel 10 (proyecto separado)
- **Jobs:** CronJobs
- **Emails:** SMTP propio
- **Storage:** FTP en el mismo servidor

**Roles de Usuario:**
- **Profesional:** Médico individual que gestiona su consultorio
- **Consultorio:** Entidad que agrupa múltiples profesionales
- **Asistente:** Usuario con permisos customizables y limitados
- **Paciente:** Usuario final que agenda citas

### Objetivos del Proyecto

1. **Monetización Efectiva**
   - Implementar modelo de suscripción recurrente
   - Generar ingresos predecibles y escalables
   - Maximizar valor de vida del cliente (LTV)

2. **Experiencia de Usuario Superior**
   - Proceso de registro y pago fluido
   - Transparencia en consumo de tokens
   - Notificaciones oportunas y relevantes

3. **Cumplimiento Normativo**
   - Facturación electrónica CFDI (México) y DIAN (Colombia)
   - Protección de datos personales según leyes locales
   - Transparencia en cobros y términos

4. **Flexibilidad y Escalabilidad**
   - Soporte para múltiples planes y periodicidades
   - Sistema de descuentos y referidos
   - Arquitectura preparada para 10,000+ usuarios

5. **Gestión Administrativa Eficiente**
   - Panel admin completo con métricas clave
   - Automatización de procesos críticos
   - Visibilidad total del negocio

---

## Stakeholders

| Rol | Responsabilidad | Interés |
|-----|----------------|---------|
| **Product Owner** | Definición de características y priorización | Maximizar valor del producto |
| **Equipo de Desarrollo** | Implementación técnica del sistema | Claridad en requerimientos, arquitectura escalable |
| **Equipo de Finanzas** | Gestión de ingresos y facturación | Reportes precisos, cumplimiento fiscal |
| **Soporte al Cliente** | Atención a usuarios finales | Sistema intuitivo, documentación clara |
| **Usuarios Finales** | Profesionales médicos y consultorios | Proceso simple, transparencia, valor por dinero |
| **Equipo Legal** | Cumplimiento normativo | Adherencia a regulaciones MX/CO |
| **Management** | Visión estratégica del negocio | ROI, métricas de crecimiento, escalabilidad |

---

## Requerimientos Funcionales

### RF-001: Gestión de Planes de Suscripción

**Descripción:** El sistema debe permitir la creación y gestión de planes de suscripción con diferentes características y precios.

**Detalles:**
- **Planes Disponibles:**
  - "Google Tech + IA 50"
  - "Google Tech + IA 100"
  - "Google Tech + IA 200"
  
- **Periodicidades:**
  - Mensual
  - Anual
  - Anual con cobros mensuales (contrato de 12 meses)

- **Características por Plan:**
  - Tokens mensuales asignados (cantidad a definir por negocio)
  - Período de prueba (trial) personalizable por plan
  - Precio fijo por país (MXN para México, COP para Colombia)
  - No hay conversión automática de moneda

- **Atributos Configurables:**
  - Nombre del plan
  - Descripción
  - Tokens mensuales incluidos
  - Duración del trial (en días)
  - Precio en MXN
  - Precio en COP
  - Estado activo/inactivo

**Prioridad:** ALTA

---

### RF-002: Sistema de Tokens Mensual

**Descripción:** Implementar un sistema de tokens para controlar el consumo de funcionalidades de IA.

**Detalles:**
- **Asignación:** Tokens asignados mensualmente según el plan contratado
- **No Acumulables:** Tokens no utilizados se pierden al final del período
- **Renovación Automática:** Se resetean al inicio de cada período de facturación
- **Consumo:** Cada uso de funcionalidad IA consume tokens del pool mensual
- **Alertas de Consumo:**
  - 50% consumido
  - 75% consumido
  - 90% consumido
  - 100% consumido (sin tokens disponibles)

- **Visualización:**
  - Dashboard con indicador visual de tokens restantes
  - Historial de consumo mensual
  - Proyección de consumo

**Prioridad:** ALTA

---

### RF-003: Período de Prueba (Trial)

**Descripción:** Ofrecer período de prueba gratuito para nuevos usuarios.

**Detalles:**
- **Duración:** Configurable por plan (ejemplo: 7, 14, 30 días)
- **Requisito Obligatorio:** Usuario debe agregar método de pago (tarjeta) para activar trial
- **Funcionalidad Completa:** Acceso a todas las características del plan durante el trial
- **Tokens Incluidos:** Pool completo de tokens del plan durante trial
- **Conversión Automática:** Al finalizar trial, se cobra automáticamente si el usuario no cancela
- **Notificaciones:**
  - 3 días antes de vencer el trial
  - El día que vence el trial
  - Confirmación al convertirse en suscripción de pago

**Prioridad:** ALTA

---

### RF-004: Pagos Recurrentes con Tarjeta

**Descripción:** Procesar pagos automáticos recurrentes mediante tarjeta de crédito/débito.

**Detalles:**
- **Pasarela:** Openpay (cuentas separadas MX/CO)
- **Tokenización:** Almacenar token de tarjeta, NO datos completos
- **Cobro Automático:** En la fecha de renovación según periodicidad
- **Métodos Aceptados:**
  - Tarjetas de crédito
  - Tarjetas de débito

- **Proceso de Renovación:**
  1. Sistema intenta cobro en fecha programada
  2. Si exitoso: Renueva suscripción, resetea tokens, envía confirmación
  3. Si falla: Inicia proceso de reintentos (ver RF-005)

- **Actualización de Tarjeta:** Usuario puede cambiar tarjeta en cualquier momento

**Prioridad:** ALTA

---

### RF-005: Gestión de Fallos de Pago y Reintentos

**Descripción:** Manejar fallos de pago con reintentos automáticos y período de gracia.

**Detalles:**
- **Reintentos Automáticos:**
  - Intento 1: Inmediato al fallo
  - Intento 2: 3 días después del primer fallo
  - Intento 3: 7 días después del segundo fallo

- **Período de Gracia:**
  - **Duración:** 2 meses desde el último intento fallido
  - **Acceso:** Usuario mantiene acceso COMPLETO a la plataforma
  - **Deuda:** Se acumula el monto de suscripciones no pagadas
  - **Notificaciones:** Recordatorios cada 15 días (configurable)

- **Fin del Período de Gracia:**
  - **Si paga:** Reactivación inmediata, continúa suscripción normal
  - **Si NO paga:** Bloqueo de cuenta con deuda acumulada

- **Bloqueo:**
  - Acceso limitado a funcionalidades (solo consulta)
  - Mensaje visible de deuda pendiente
  - Opción de pago para reactivación

**Prioridad:** ALTA

---

### RF-006: Pagos Manuales (Transferencia Bancaria)

**Descripción:** Permitir pago manual mediante transferencia bancaria como alternativa a tarjeta.

**Detalles:**
- **Aplicabilidad:** Opcional, disponible para todos los planes
- **Proceso:**
  1. Usuario sin tarjeta genera orden de pago
  2. Sistema envía email con instrucciones y datos bancarios
  3. Usuario realiza transferencia
  4. Admin confirma pago manualmente o vía webhook bancario
  5. Sistema activa/renueva suscripción

- **Conversión a Tarjeta:** Usuario con pago manual puede agregar tarjeta posteriormente para automatizar renovaciones

- **Limitaciones:**
  - NO disponible para período de trial
  - Requiere confirmación manual (más lento)
  - Sin renovación automática hasta agregar tarjeta

**Prioridad:** MEDIA

---

### RF-007: Cambio de Plan (Upgrade)

**Descripción:** Permitir a usuarios mejorar su plan de suscripción actual.

**Detalles:**
- **Aplicación:** Inmediata
- **Cálculo de Prorrata:**
  - Se calcula el monto no utilizado del plan actual
  - Se aplica como crédito al nuevo plan
  - Se cobra la diferencia inmediatamente

- **Ejemplo:**
  ```
  Plan Actual: $50/mes, quedan 15 días
  Plan Nuevo: $100/mes
  Crédito por días restantes: $25
  Cargo inmediato: $75 (diferencia prorrateada)
  Próximo cobro completo: $100 en 15 días
  ```

- **Tokens:**
  - Se resetean INMEDIATAMENTE al pool del nuevo plan
  - Tokens no utilizados del plan anterior se pierden

- **Próxima Renovación:**
  - Nueva fecha de facturación desde el día del upgrade
  - Monto completo del nuevo plan

**Prioridad:** ALTA

---

### RF-008: Cambio de Plan (Downgrade)

**Descripción:** Permitir a usuarios reducir su plan de suscripción actual.

**Detalles:**
- **Aplicación:** Al finalizar el período actual de facturación
- **Proceso:**
  1. Usuario solicita downgrade
  2. Sistema programa el cambio para la próxima renovación
  3. Usuario continúa con plan actual hasta fin de período
  4. En la renovación, se activa el nuevo plan y se cobra el monto menor

- **Tokens:**
  - Durante período actual: Mantiene tokens del plan actual
  - En renovación: Se asignan tokens del nuevo plan (menor cantidad)

- **Confirmación:**
  - Email confirmando el cambio programado
  - Email al ejecutarse el cambio en la renovación

- **Reversión:** Usuario puede cancelar el downgrade programado antes de que se ejecute

**Prioridad:** ALTA

---

### RF-009: Sistema de Cupones de Descuento

**Descripción:** Implementar sistema de cupones para descuentos en suscripciones.

**Detalles:**
- **Tipos de Descuento:**
  - **Porcentaje:** ej. 20% de descuento
  - **Precio Fijo:** ej. $10 de descuento

- **Duración:**
  - **Permanente:** Aplica indefinidamente mientras el cupón esté activo
  - **Temporal:** Duración en meses (ej. 3 meses, 6 meses)

- **Aplicabilidad:**
  - Todos los planes
  - Planes específicos seleccionables

- **Restricciones:**
  - NO acumulables (solo un cupón activo por usuario)
  - Límite de usos totales (opcional)
  - Fecha de expiración (opcional)
  - Un usuario solo puede usar un cupón una vez (no puede reusar)

- **Códigos:**
  - Códigos únicos alfanuméricos
  - Case-insensitive
  - Validación en tiempo real

- **Gestión Admin:**
  - Crear/editar/desactivar cupones
  - Ver estadísticas de uso
  - Exportar lista de usuarios que usaron cupón

**Prioridad:** MEDIA

---

### RF-010: Sistema de Referidos

**Descripción:** Programa de referidos para incentivar crecimiento orgánico.

**Detalles:**
- **Beneficios del Referidor (configurable):**
  - Descuento en próxima renovación
  - Tokens extra (adicionales al pool mensual)
  - Crédito en la plataforma

- **Beneficios del Referido:**
  - Solo descuento en primer pago

- **Mecánica:**
  1. Usuario obtiene código único y link de referido
  2. Comparte con amigos/colegas
  3. Nuevo usuario se registra usando el código/link
  4. Nuevo usuario completa trial y realiza primer pago
  5. Sistema otorga beneficios a ambas partes

- **Reglas:**
  - Beneficio se otorga al PRIMER PAGO del referido (no en trial)
  - Referidor puede referir a múltiples usuarios
  - Límite configurable de beneficios por referidor (ej. máximo 10 referidos/mes)
  - Referido solo puede ser referido una vez (no puede usar múltiples códigos)

- **Tracking:**
  - Dashboard con estadísticas de referidos
  - Estado de cada referido (registrado, en trial, convertido)
  - Beneficios ganados

**Prioridad:** MEDIA

---

### RF-011: Facturación Electrónica

**Descripción:** Generar y entregar facturas electrónicas cumpliendo normativas locales.

**Detalles:**

#### México (CFDI):
- **Datos Requeridos:**
  - RFC (Registro Federal de Contribuyentes)
  - Razón Social
  - Régimen Fiscal
  - Código Postal
  - Uso de CFDI

- **Límite de Solicitud:** Mismo mes del pago
- **Generación:** Externa mediante PAC (Proveedor Autorizado de Certificación)

#### Colombia (Factura Electrónica DIAN):
- **Datos Requeridos:**
  - NIT (Número de Identificación Tributaria)
  - Razón Social
  - Tipo de Persona (Natural/Jurídica)
  - Dirección
  - Ciudad
  - Departamento

- **Límite de Solicitud:** 5 días después del pago
- **Generación:** Externa cumpliendo normativa DIAN

#### Proceso:
1. Usuario solicita factura desde la plataforma
2. Sistema valida datos fiscales completos
3. Sistema valida límite de tiempo según país
4. Genera solicitud visible para Admin
5. Admin genera factura en sistema externo (PAC/DIAN)
6. Admin sube PDF de factura a la plataforma
7. Sistema envía email al usuario con factura adjunta
8. Factura queda disponible en historial del usuario

**Prioridad:** ALTA

---

### RF-012: Sistema de Notificaciones

**Descripción:** Enviar notificaciones por email en eventos clave del ciclo de vida.

**17 Emails Mínimos para MVP:**

1. **Bienvenida:** Al completar registro
2. **Confirmación de Pago:** Cuando un pago es exitoso
3. **Recordatorio de Cobro:** X días antes de la renovación (configurable)
4. **Fallo de Pago:** Cuando un intento de cobro falla
5. **Orden de Pago Manual:** Instrucciones para transferencia bancaria
6. **Entrada a Período de Gracia:** Al entrar en período de gracia
7-N. **Recordatorios de Gracia:** Cada 15 días durante período de gracia (configurable)
8. **Cancelación de Suscripción:** Cuando usuario cancela
9. **Cambio de Plan:** Confirmación de upgrade o downgrade
10. **Referido Exitoso:** Al referidor cuando un referido convierte
11. **Código de Descuento:** Al referido con su código de descuento
12. **Factura Disponible:** Cuando la factura está lista para descarga
13. **Tokens 50%:** Alerta al consumir 50% de tokens
14. **Tokens 75%:** Alerta al consumir 75% de tokens
15. **Tokens 90%:** Alerta al consumir 90% de tokens
16. **Tokens 100%:** Alerta al agotar tokens
17. **Trial Próximo a Vencer:** 3 días antes de que termine el trial
18. **Trial Vencido:** El día que termina el trial
19. **Reactivación:** Al reactivar cuenta después de bloqueo

**Características:**
- Templates responsive con branding
- Personalización con datos del usuario
- Links a acciones relevantes
- Footer con información legal y unsubscribe

**Prioridad:** ALTA

---

### RF-013: Panel de Administración

**Descripción:** Dashboard completo para gestión del sistema de suscripciones.

**Módulos Principales:**

#### Dashboard Principal:
- **Métricas Clave:**
  - MRR (Monthly Recurring Revenue)
  - ARR (Annual Recurring Revenue)
  - Usuarios activos vs inactivos
  - Suscripciones por plan
  - Tasa de conversión trial → pago
  - Churn rate (tasa de cancelación)
  - Ingresos del mes/año
  - Cupones activos y su uso
  - Referidos exitosos

- **Gráficos:**
  - Evolución de ingresos (línea temporal)
  - Distribución por planes (pie chart)
  - Nuevos usuarios vs cancelaciones
  - Conversión de trials

#### Gestión de Usuarios:
- Listar todos los usuarios con filtros
- Ver detalle de suscripción de cada usuario
- Cancelar/reactivar suscripción manualmente
- Cambiar plan de usuario
- Agregar/quitar tokens manualmente
- Ver historial de pagos
- Aplicar descuento manual
- Ver datos fiscales

#### Gestión de Planes:
- CRUD completo de planes
- Activar/desactivar planes
- Modificar precios (afecta solo nuevas suscripciones)
- Configurar duración de trial por plan

#### Gestión de Cupones:
- CRUD completo de cupones
- Ver estadísticas de uso por cupón
- Exportar usuarios que usaron cupón
- Desactivar cupones

#### Gestión de Pagos:
- Listar todos los pagos con filtros
- Ver detalle de cada transacción
- Procesar reembolsos
- Confirmar pagos manuales (transferencias)
- Ver logs de webhooks de Openpay

#### Gestión de Período de Gracia:
- Listar usuarios en período de gracia
- Ver deuda acumulada
- Extender/reducir período de gracia
- Forzar pago o bloqueo manual

#### Gestión de Referidos:
- Ver todos los referidos y su estado
- Estadísticas por referidor
- Configurar beneficios de programa de referidos
- Exportar datos

#### Gestión de Facturas:
- Listar solicitudes de facturas
- Subir PDF de factura
- Enviar factura por email
- Ver historial de facturas

#### Reportes:
- Exportar reportes de ingresos
- Exportar reportes de usuarios
- Exportar reportes de facturación
- Análisis de churn
- Proyecciones de ingresos

#### Configuración Global:
- Configurar días de recordatorio de cobro
- Configurar frecuencia de recordatorios en período de gracia
- Configurar beneficios de programa de referidos
- Configurar alertas de tokens
- Configurar emails transaccionales

**Prioridad:** ALTA (Dashboard básico), MEDIA (Features avanzados)

---

### RF-014: Cancelación de Suscripción

**Descripción:** Permitir a usuarios cancelar su suscripción.

**Detalles:**
- **Proceso:**
  1. Usuario solicita cancelación
  2. Sistema muestra confirmación con información:
     - Fecha efectiva de cancelación (fin de período actual)
     - Acceso restante
     - Datos que se mantendrán
  3. Usuario confirma
  4. Sistema programa cancelación al finalizar período pagado

- **Efecto:**
  - Acceso completo hasta fin de período pagado
  - No se cobra en próxima renovación
  - Cuenta se marca como "cancelada"
  - Email de confirmación de cancelación

- **Reactivación:**
  - Usuario puede reactivar antes de que se efectúe la cancelación
  - Opción de reactivar después con nuevo período de trial

- **Retención de Datos:**
  - Datos del usuario se mantienen por período legal
  - Opción de exportar datos antes de cancelar

**Prioridad:** ALTA

---

### RF-015: Auditoría y Logs

**Descripción:** Registrar todas las acciones críticas del sistema para auditoría.

**Eventos a Loguear:**
- Cambios en suscripciones
- Todos los intentos de pago (exitosos y fallidos)
- Cambios de plan
- Aplicación de cupones y descuentos
- Otorgamiento de beneficios de referidos
- Cambios en datos fiscales
- Solicitudes y entregas de facturas
- Acciones de admin sobre usuarios
- Cambios en configuración del sistema
- Webhooks recibidos de Openpay

**Datos a Registrar:**
- Usuario afectado
- Acción realizada
- Entidad y ID
- Estado anterior (JSON)
- Estado nuevo (JSON)
- IP de origen
- Timestamp
- Usuario admin (si aplica)

**Retención:** Mínimo 1 año, 5 años recomendado para cumplimiento fiscal

**Prioridad:** ALTA

---

## Requerimientos No Funcionales

### RNF-001: Rendimiento

**Descripción:** El sistema debe operar con tiempos de respuesta adecuados.

**Criterios:**
- Tiempo de carga de páginas: < 2 segundos
- Procesamiento de pago: < 5 segundos
- APIs: < 500ms para el 95% de las peticiones
- Webhook processing: < 1 segundo

**Prioridad:** ALTA

---

### RNF-002: Escalabilidad

**Descripción:** El sistema debe escalar para soportar 10,000+ usuarios activos.

**Criterios:**
- Arquitectura preparada para escalado horizontal
- Base de datos optimizada con índices adecuados
- Uso de caché para queries frecuentes (Redis recomendado)
- Jobs asíncronos para operaciones pesadas
- CDN para assets estáticos

**Prioridad:** ALTA

---

### RNF-003: Disponibilidad

**Descripción:** El sistema debe estar disponible para procesar pagos y accesos.

**Criterios:**
- Uptime objetivo: 99.5% (downtime máximo ~3.6 horas/mes)
- Monitoreo 24/7 de servicios críticos
- Alertas automáticas en caso de fallo
- Backups diarios de base de datos
- Plan de recuperación ante desastres

**Prioridad:** ALTA

---

### RNF-004: Seguridad

**Descripción:** Proteger datos sensibles y transacciones.

**Criterios:**
- **Cumplimiento Normativo:**
  - Ley Federal de Protección de Datos Personales en Posesión de Particulares (México)
  - Ley 1581 de 2012 - Ley de Habeas Data (Colombia)

- **Seguridad de Datos:**
  - HTTPS obligatorio en todas las comunicaciones
  - Tokenización de tarjetas (NO almacenar datos completos)
  - Encriptación de datos sensibles en BD
  - CSRF protection
  - Input sanitization y validación
  - Rate limiting en APIs

- **Seguridad de Webhooks:**
  - Validación de IP origen
  - Verificación de firma HMAC
  - Logs de todos los webhooks

- **Autenticación:**
  - Contraseñas hasheadas (bcrypt)
  - 2FA en roadmap futuro
  - Sesiones seguras
  - Rate limiting en login

- **Auditoría:**
  - Logs de todas las transacciones
  - Logs de acciones de admin
  - Retención de logs según normativa

**Prioridad:** ALTA

---

### RNF-005: Usabilidad

**Descripción:** La interfaz debe ser intuitiva y accesible.

**Criterios:**
- Diseño responsive (mobile, tablet, desktop)
- Formularios con validación en tiempo real
- Mensajes de error claros y accionables
- Proceso de pago en máximo 3 pasos
- Accesibilidad WCAG 2.1 nivel AA (objetivo)
- Soporte para navegadores modernos (últimas 2 versiones)

**Prioridad:** MEDIA

---

### RNF-006: Mantenibilidad

**Descripción:** El código debe ser mantenible y extensible.

**Criterios:**
- Código siguiendo estándares PSR (PHP)
- Arquitectura en capas (Service Layer, Repository Pattern)
- Documentación técnica completa
- Tests unitarios y de integración
- Code reviews obligatorios
- Versionamiento semántico

**Prioridad:** MEDIA

---

### RNF-007: Compatibilidad

**Descripción:** El sistema debe funcionar en ambos países con sus especificidades.

**Criterios:**
- Soporte para 2 monedas (MXN, COP)
- Soporte para 2 sistemas de facturación (CFDI, DIAN)
- Instancias separadas por país
- Sin conversión automática de moneda
- Configuración específica por país

**Prioridad:** ALTA

---

### RNF-008: Observabilidad

**Descripción:** Capacidad de monitorear y diagnosticar el sistema.

**Criterios:**
- Logging estructurado
- Métricas de negocio en dashboard
- Alertas configurables
- Laravel Telescope para desarrollo
- Laravel Horizon para queues en producción (recomendado)
- Integración con Sentry para errores (recomendado)

**Prioridad:** MEDIA

---

## User Stories

### Epic 1: Onboarding y Trial

#### US-001: Registro de Usuario
**Como** nuevo usuario  
**Quiero** registrarme en la plataforma seleccionando un plan  
**Para** comenzar a usar el servicio

**Criterios de Aceptación:**
- Puedo ver los 3 planes disponibles con sus características
- Puedo seleccionar periodicidad (mensual/anual)
- Puedo ingresar mis datos de registro
- Puedo ingresar mis datos fiscales
- El sistema valida todos los campos
- Recibo email de bienvenida

---

#### US-002: Activación de Trial
**Como** usuario recién registrado  
**Quiero** agregar mi tarjeta para activar el período de prueba  
**Para** probar el servicio sin cargo inmediato

**Criterios de Aceptación:**
- Puedo ingresar datos de mi tarjeta de forma segura
- El sistema tokeniza mi tarjeta (no almacena datos completos)
- Mi trial se activa inmediatamente
- Recibo los tokens completos del plan
- Recibo confirmación de activación de trial
- Sé exactamente cuándo se cobrará mi tarjeta

---

#### US-003: Notificación de Vencimiento de Trial
**Como** usuario en período de trial  
**Quiero** recibir notificación antes de que venza mi trial  
**Para** decidir si continuar o cancelar

**Criterios de Aceptación:**
- Recibo email 3 días antes de que venza el trial
- El email indica la fecha exacta de cobro
- El email indica el monto que se cobrará
- Puedo cancelar desde el link del email
- Puedo actualizar mi tarjeta si es necesario

---

### Epic 2: Pagos y Facturación

#### US-004: Renovación Automática
**Como** usuario con suscripción activa  
**Quiero** que mi suscripción se renueve automáticamente  
**Para** no interrumpir mi servicio

**Criterios de Aceptación:**
- Mi tarjeta se cobra automáticamente en la fecha de renovación
- Mis tokens se resetean al pool completo del plan
- Recibo confirmación de pago exitoso
- Puedo descargar mi recibo de pago
- Mi próxima fecha de renovación se actualiza

---

#### US-005: Pago Manual con Transferencia
**Como** usuario sin tarjeta  
**Quiero** pagar mediante transferencia bancaria  
**Para** acceder al servicio sin usar tarjeta

**Criterios de Aceptación:**
- Puedo generar una orden de pago
- Recibo email con instrucciones y datos bancarios
- Puedo enviar comprobante de pago
- Mi suscripción se activa al confirmar el pago
- Puedo agregar tarjeta después para automatizar

---

#### US-006: Solicitud de Factura
**Como** usuario que realizó un pago  
**Quiero** solicitar mi factura electrónica  
**Para** cumplir con mis obligaciones fiscales

**Criterios de Aceptación:**
- Puedo ingresar/actualizar mis datos fiscales
- El sistema valida que esté dentro del límite de tiempo
- Puedo solicitar factura desde mi historial de pagos
- Recibo email cuando la factura está disponible
- Puedo descargar la factura en PDF
- La factura cumple con normativa local (CFDI/DIAN)

---

### Epic 3: Gestión de Suscripción

#### US-007: Upgrade de Plan
**Como** usuario con plan básico  
**Quiero** mejorar a un plan superior  
**Para** obtener más tokens y funcionalidades

**Criterios de Aceptación:**
- Puedo ver los planes superiores disponibles
- Veo el cálculo de prorrata claramente
- Veo el cargo que se aplicará de inmediato
- Mi upgrade se aplica inmediatamente al confirmar
- Mis tokens se resetean al nuevo plan
- Recibo confirmación del cambio

---

#### US-008: Downgrade de Plan
**Como** usuario con plan premium  
**Quiero** reducir a un plan menor  
**Para** ajustar mis costos

**Criterios de Aceptación:**
- Puedo seleccionar un plan inferior
- Entiendo que el cambio se aplicará al finalizar mi período actual
- Mantengo mi plan actual hasta la próxima renovación
- Recibo confirmación del cambio programado
- Puedo cancelar el downgrade antes de que se ejecute

---

#### US-009: Cancelación de Suscripción
**Como** usuario suscrito  
**Quiero** cancelar mi suscripción  
**Para** dejar de recibir cobros

**Criterios de Aceptación:**
- Puedo solicitar cancelación fácilmente
- Veo claramente hasta cuándo tendré acceso
- Mantengo acceso hasta fin del período pagado
- No se me cobra en la próxima renovación
- Recibo confirmación de cancelación
- Puedo exportar mis datos antes de cancelar

---

### Epic 4: Tokens y Consumo

#### US-010: Visualización de Tokens
**Como** usuario activo  
**Quiero** ver mis tokens disponibles  
**Para** planificar mi uso de funcionalidades IA

**Criterios de Aceptación:**
- Veo un indicador visual de tokens restantes
- Veo el total de tokens de mi plan
- Veo mi historial de consumo del mes
- Veo cuándo se resetearán mis tokens
- El indicador se actualiza en tiempo real

---

#### US-011: Alertas de Consumo de Tokens
**Como** usuario consumiendo tokens  
**Quiero** recibir alertas cuando me estoy quedando sin tokens  
**Para** planificar upgrade o reducir uso

**Criterios de Aceptación:**
- Recibo alerta al consumir 50% de tokens
- Recibo alerta al consumir 75% de tokens
- Recibo alerta al consumir 90% de tokens
- Recibo alerta al agotar 100% de tokens
- Cada alerta incluye opción de upgrade
- Las alertas se envían por email y se muestran en plataforma

---

### Epic 5: Descuentos y Referidos

#### US-012: Aplicar Cupón de Descuento
**Como** nuevo usuario o usuario renovando  
**Quiero** aplicar un cupón de descuento  
**Para** obtener un precio reducido

**Criterios de Aceptación:**
- Puedo ingresar un código de cupón
- El sistema valida el cupón en tiempo real
- Veo el descuento aplicado claramente
- Veo el precio final a pagar
- El cupón se aplica automáticamente en cobros recurrentes según su duración
- Recibo confirmación del cupón aplicado

---

#### US-013: Referir a un Amigo
**Como** usuario satisfecho  
**Quiero** referir amigos a la plataforma  
**Para** obtener beneficios

**Criterios de Aceptación:**
- Obtengo un código y link único de referido
- Puedo compartir fácilmente por email/redes sociales
- Veo cuántos amigos he referido
- Veo el estado de cada referido (registrado, trial, convertido)
- Recibo notificación cuando un referido convierte
- Recibo mis beneficios al primer pago del referido

---

### Epic 6: Gestión de Fallos

#### US-014: Notificación de Fallo de Pago
**Como** usuario con fallo en renovación  
**Quiero** ser notificado del fallo  
**Para** actualizar mi método de pago

**Criterios de Aceptación:**
- Recibo email inmediato al fallar el pago
- El email explica claramente qué pasó
- Puedo actualizar mi tarjeta desde el link del email
- Veo cuándo será el próximo reintento
- Mantengo acceso completo durante los reintentos

---

#### US-015: Período de Gracia
**Como** usuario que no pudo pagar después de reintentos  
**Quiero** tener un período para regularizar  
**Para** no perder acceso inmediatamente

**Criterios de Aceptación:**
- Mantengo acceso completo durante 2 meses de gracia
- Recibo recordatorios cada 15 días
- Veo claramente mi deuda acumulada
- Puedo pagar en cualquier momento para regularizar
- Si pago, mi suscripción continúa normalmente

---

### Epic 7: Administración

#### US-016: Dashboard de Admin
**Como** administrador  
**Quiero** ver métricas clave del negocio  
**Para** tomar decisiones informadas

**Criterios de Aceptación:**
- Veo MRR y ARR actualizados
- Veo distribución de usuarios por plan
- Veo tasa de conversión de trial
- Veo churn rate del mes
- Veo gráficos de evolución temporal
- Puedo exportar reportes

---

#### US-017: Gestión de Usuario por Admin
**Como** administrador  
**Quiero** gestionar suscripciones de usuarios  
**Para** resolver problemas y casos especiales

**Criterios de Aceptación:**
- Puedo buscar cualquier usuario
- Puedo ver detalle completo de su suscripción
- Puedo cancelar/reactivar suscripción
- Puedo cambiar plan manualmente
- Puedo agregar/quitar tokens
- Puedo aplicar descuento manual
- Todas las acciones quedan en audit log

---

## Criterios de Aceptación

### Generales

1. **Funcionalidad Completa:**
   - Todos los requerimientos funcionales implementados según especificación
   - Flujos principales funcionando end-to-end
   - Casos edge cubiertos

2. **Calidad de Código:**
   - Tests unitarios con cobertura mínima 70%
   - Tests de integración para flujos críticos
   - Code reviews aprobados
   - Sin vulnerabilidades críticas

3. **Experiencia de Usuario:**
   - Interfaz intuitiva sin necesidad de documentación
   - Mensajes de error claros y accionables
   - Tiempos de respuesta < 2 segundos
   - Funciona en mobile, tablet y desktop

4. **Seguridad:**
   - Datos sensibles encriptados
   - Webhooks validados
   - HTTPS en todos los endpoints
   - Sin almacenamiento de datos de tarjeta

5. **Cumplimiento:**
   - Facturación conforme a normativas MX/CO
   - Política de privacidad implementada
   - Términos y condiciones claros
   - Retención de datos según ley

6. **Documentación:**
   - Documentación técnica completa
   - Documentación de APIs
   - Guías de usuario
   - Runbooks para operaciones

---

## Métricas de Éxito

### Métricas de Negocio

| Métrica | Objetivo | Timeframe |
|---------|----------|-----------|
| **MRR (Monthly Recurring Revenue)** | Crecimiento 20% mensual | Primeros 6 meses |
| **Tasa de Conversión Trial → Pago** | > 40% | Después del primer mes |
| **Churn Rate** | < 5% mensual | Estabilizado a los 3 meses |
| **LTV (Lifetime Value)** | > $500 USD por usuario | A los 6 meses |
| **Tasa de Éxito de Pagos** | > 95% | Desde el lanzamiento |
| **Uso de Cupones** | > 20% de nuevos usuarios | Primeros 3 meses |
| **Tasa de Referidos Convertidos** | > 30% | Primeros 6 meses |

### Métricas Técnicas

| Métrica | Objetivo | Timeframe |
|---------|----------|-----------|
| **Uptime** | > 99.5% | Continuo |
| **Tiempo de Respuesta API** | < 500ms (p95) | Continuo |
| **Tiempo de Carga Páginas** | < 2 segundos | Continuo |
| **Procesamiento de Webhooks** | < 1 segundo | Continuo |
| **Tasa de Error en Pagos** | < 1% (errores de sistema, no del usuario) | Continuo |

### Métricas de Satisfacción

| Métrica | Objetivo | Método de Medición |
|---------|----------|-------------------|
| **NPS (Net Promoter Score)** | > 50 | Encuesta trimestral |
| **CSAT (Customer Satisfaction)** | > 4.5/5 | Post-interacción |
| **Tiempo de Respuesta Soporte** | < 24 horas | Tickets de soporte |
| **Tickets de Soporte por Pagos** | < 2% de usuarios | Análisis mensual |

---

## Glosario

| Término | Definición |
|---------|-----------|
| **ARR** | Annual Recurring Revenue - Ingresos recurrentes anuales |
| **CFDI** | Comprobante Fiscal Digital por Internet - Factura electrónica México |
| **Churn** | Tasa de cancelación de suscripciones |
| **DIAN** | Dirección de Impuestos y Aduanas Nacionales - Autoridad fiscal Colombia |
| **Downgrade** | Cambio a un plan de menor costo |
| **LTV** | Lifetime Value - Valor total que un cliente aporta durante su relación con la empresa |
| **MRR** | Monthly Recurring Revenue - Ingresos recurrentes mensuales |
| **NIT** | Número de Identificación Tributaria - Colombia |
| **Openpay** | Pasarela de pagos utilizada en México y Colombia |
| **PAC** | Proveedor Autorizado de Certificación - Emisor de CFDI en México |
| **Período de Gracia** | Tiempo extra otorgado después de fallos de pago antes del bloqueo |
| **Prorrata** | Cálculo proporcional del costo por período parcial |
| **RFC** | Registro Federal de Contribuyentes - Identificador fiscal México |
| **SaaS** | Software as a Service - Software como servicio |
| **Token** | Unidad de consumo para funcionalidades de IA |
| **Trial** | Período de prueba gratuito |
| **Upgrade** | Cambio a un plan de mayor costo |
| **Webhook** | Notificación HTTP automática de eventos |

---

**Documento:** PRD v1.0  
**Fecha:** Enero 2026  
**Próxima Revisión:** Mensual durante desarrollo

