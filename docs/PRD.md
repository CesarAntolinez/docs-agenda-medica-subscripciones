# Documento de Requerimientos Funcionales (PRD)
## Gestor de Suscripciones Laravel - Agenda Médica

**Versión:** 2.0  
**Fecha:** Enero 2026  
**Autor:** Cesar Antolinez  
**Estado:** Aprobado

---

## 📑 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Visión del Producto](#visión-del-producto)
3. [Objetivos del Producto](#objetivos-del-producto)
4. [Alcance del Producto](#alcance-del-producto)
5. [Requerimientos Funcionales](#requerimientos-funcionales)
6. [Historias de Usuario](#historias-de-usuario)
7. [Criterios de Aceptación](#criterios-de-aceptación)
8. [Casos de Uso](#casos-de-uso)
9. [Requisitos No Funcionales](#requisitos-no-funcionales)
10. [Dependencias y Restricciones](#dependencias-y-restricciones)
11. [Métricas de Éxito](#métricas-de-éxito)

---

## Resumen Ejecutivo

El **Gestor de Suscripciones Laravel - Agenda Médica** es un paquete completo diseñado para gestionar suscripciones de servicios médicos de forma flexible, segura y escalable. El sistema permite que médicos, clínicas y organizaciones de salud gestionen planes de suscripción con múltiples pasarelas de pago, cumplimiento de normativas de seguridad (3D Secure, PSD2), y características avanzadas como cupones, períodos de prueba, y facturación electrónica.

**Propuesta de Valor:**
- Solución lista para producción que reduce el tiempo de desarrollo de 6 meses a 2 semanas
- Cumplimiento automático con regulaciones de pago (PSD2, 3D Secure 2.0)
- Arquitectura polimórfica que se adapta a cualquier modelo de negocio médico
- Soporte multi-pasarela para expansión internacional (México, Colombia, y más)

---

## Visión del Producto

Crear el paquete de gestión de suscripciones más flexible y completo del ecosistema Laravel, específicamente diseñado para el sector salud, que permita a desarrolladores implementar sistemas de suscripción robustos en días en lugar de meses.

**Diferenciadores Clave:**
1. **Polimorfismo Total** - Funciona con Usuarios, Empresas, Equipos médicos, Clínicas, sin modificaciones
2. **Seguridad First** - 3D Secure 2.0 y cumplimiento PCI integrados desde el día uno
3. **Multi-Pasarela** - Abstracción completa para cambiar proveedores sin tocar código de negocio
4. **Modularidad** - Activa solo las características que necesitas (tokens, referidos, facturación)

---

## Objetivos del Producto

### Objetivos de Negocio
1. **Reducir Tiempo de Implementación:** De 6 meses a 2 semanas para un sistema completo de suscripciones
2. **Aumentar Conversión:** Soporte 3DS reduce fraude en 70% y aumenta aprobación de pagos
3. **Escalabilidad:** Soportar desde 100 hasta 100,000+ suscriptores sin cambios arquitectónicos
4. **Cumplimiento Regulatorio:** 100% compatible con PSD2, PCI-DSS, y normativas locales

### Objetivos Técnicos
1. **Cobertura de Pruebas:** ≥85% de cobertura de código
2. **Performance:** Procesar pagos en <3 segundos (p95)
3. **Disponibilidad:** 99.9% uptime para operaciones críticas
4. **Extensibilidad:** API clara para agregar nuevas pasarelas en <1 día

---

## Alcance del Producto

### En Alcance (Versión 2.0)

#### Módulo Core - Gestión de Suscripciones
- ✅ Creación y gestión de planes de suscripción
- ✅ Suscripción de entidades polimórficas (Users, Companies, Teams)
- ✅ Tres modalidades de facturación (mensual, anual, anual con pago mensual)
- ✅ Períodos de prueba configurables por plan
- ✅ Períodos de gracia para pagos fallidos
- ✅ Cambio de planes (upgrade/downgrade) con prorrateo
- ✅ Cancelación y reactivación de suscripciones

#### Módulo Core - Gestión de Pagos
- ✅ Integración 3D Secure 2.0 completa
- ✅ Soporte Openpay (México, Colombia)
- ✅ Procesamiento de pagos únicos y recurrentes
- ✅ Reintentos automáticos configurables
- ✅ Webhooks para eventos de pago
- ✅ Registro completo de transacciones

#### Módulo Core - Cupones y Descuentos
- ✅ Cupones de porcentaje
- ✅ Cupones de monto fijo
- ✅ Cupones con duración limitada
- ✅ Validación de cupones y límites de uso
- ✅ Histórico de cupones aplicados

#### Módulo Core - Notificaciones
- ✅ 20+ emails transaccionales
- ✅ Notificaciones de pago exitoso/fallido
- ✅ Alertas de vencimiento de prueba
- ✅ Recordatorios de período de gracia
- ✅ Confirmaciones de cambio de plan

#### Módulo Core - Auditoría y Seguridad
- ✅ Registro de auditoría completo
- ✅ Tokenización de tarjetas (sin almacenamiento)
- ✅ Encriptación de datos sensibles
- ✅ Verificación de webhooks

#### Módulos Opcionales
- ⚙️ Sistema de Tokens (consumo basado en uso)
- ⚙️ Sistema de Referidos
- ⚙️ Facturación Electrónica (PAC México / DIAN Colombia)

### Fuera de Alcance (Versión 2.0)
- ❌ Pasarela Stripe (planificado v2.1)
- ❌ Pasarela Mercadopago (planificado v2.1)
- ❌ Panel de administración UI (decisión del desarrollador)
- ❌ Integración directa con CRM
- ❌ Reportes y analytics avanzados

---

## Requerimientos Funcionales

### RF-001: Gestión de Planes de Suscripción

**Prioridad:** Alta  
**Módulo:** Core

**Descripción:**  
El sistema debe permitir crear, editar, activar, desactivar y eliminar (soft delete) planes de suscripción.

**Detalles:**
- Cada plan debe tener:
  - Nombre único
  - Descripción
  - Precio (soporta múltiples monedas: MXN, COP)
  - Periodicidad (mensual, anual, anual con pago mensual)
  - Días de prueba (0-365)
  - Cantidad de tokens (si módulo habilitado)
  - Estado (activo/inactivo)
- Los planes pueden ser activados/desactivados sin eliminar datos históricos
- Soporta versionado de planes para preservar histórico

**Criterios de Aceptación:**
- [ ] Crear plan con todos los campos requeridos
- [ ] Actualizar plan existente
- [ ] Activar/desactivar plan
- [ ] Listar planes activos e inactivos
- [ ] Preservar suscripciones existentes al desactivar plan

---

### RF-002: Suscripción a Planes

**Prioridad:** Alta  
**Módulo:** Core

**Descripción:**  
Cualquier modelo que use el trait `HasSubscription` debe poder suscribirse a un plan.

**Detalles:**
- Soporte para modelos polimórficos (User, Company, Team, etc.)
- Aplicación de períodos de prueba
- Aplicación de cupones de descuento
- Validación de datos de facturación
- Generación de primer pago (si no hay prueba)

**Criterios de Aceptación:**
- [ ] Usuario puede suscribirse a plan activo
- [ ] Empresa puede suscribirse a plan activo
- [ ] Equipo puede suscribirse a plan activo
- [ ] Período de prueba se aplica correctamente
- [ ] Cupón se valida y aplica correctamente
- [ ] Datos de facturación se guardan encriptados

---

### RF-003: Procesamiento de Pagos 3D Secure

**Prioridad:** Crítica  
**Módulo:** Core - Pagos

**Descripción:**  
El sistema debe procesar pagos utilizando 3D Secure 2.0 para cumplir con PSD2.

**Detalles:**
- Primer pago requiere autenticación 3DS (SCA)
- Pagos subsecuentes usan MIT (Merchant Initiated Transaction)
- Redirección a página de autenticación bancaria
- Callback para confirmar pago
- Registro completo del flujo 3DS

**Criterios de Aceptación:**
- [ ] Primer pago solicita autenticación 3DS
- [ ] Redirección a banco funciona correctamente
- [ ] Callback procesa respuesta correctamente
- [ ] Pagos MIT funcionan sin autenticación
- [ ] Fallos 3DS se registran correctamente

---

### RF-004: Reintentos de Pago

**Prioridad:** Alta  
**Módulo:** Core - Pagos

**Descripción:**  
Cuando un pago falla, el sistema debe reintentarlo automáticamente según configuración.

**Detalles:**
- Configuración de número de reintentos (1-5)
- Configuración de días entre reintentos
- Notificaciones en cada reintento
- Inicio de período de gracia tras agotar reintentos

**Criterios de Aceptación:**
- [ ] Reintentos se ejecutan según configuración
- [ ] Notificaciones se envían en cada reintento
- [ ] Período de gracia inicia correctamente
- [ ] Log completo de reintentos

---

### RF-005: Períodos de Gracia

**Prioridad:** Alta  
**Módulo:** Core - Pagos

**Descripción:**  
Tras agotar reintentos, el sistema debe otorgar un período de gracia configurable.

**Detalles:**
- Duración configurable (default: 2 meses)
- Funcionalidad limitada durante gracia
- Notificaciones de recordatorio
- Cancelación automática al terminar gracia

**Criterios de Aceptación:**
- [ ] Período de gracia inicia tras último reintento fallido
- [ ] Suscripción permanece activa durante gracia
- [ ] Notificaciones se envían periódicamente
- [ ] Suscripción se cancela al terminar gracia si no hay pago

---

### RF-006: Cupones de Descuento

**Prioridad:** Alta  
**Módulo:** Core - Cupones

**Descripción:**  
El sistema debe permitir crear y aplicar cupones de descuento.

**Detalles:**
- Tipos: porcentaje, monto fijo
- Duración: única, por tiempo definido (ej. 3 meses)
- Límites de uso total y por usuario
- Validación de vigencia y disponibilidad

**Criterios de Aceptación:**
- [ ] Crear cupón de porcentaje
- [ ] Crear cupón de monto fijo
- [ ] Validar cupón antes de aplicar
- [ ] Aplicar descuento correctamente
- [ ] Respetar límites de uso
- [ ] Registrar histórico de uso

---

### RF-007: Cambio de Plan

**Prioridad:** Media  
**Módulo:** Core - Suscripciones

**Descripción:**  
Los suscriptores deben poder cambiar de plan (upgrade/downgrade).

**Detalles:**
- Cálculo de prorrateo para upgrades
- Aplicación de crédito para downgrades
- Actualización inmediata de características
- Ajuste de próximo cobro

**Criterios de Aceptación:**
- [ ] Upgrade aplica cargo prorrateado inmediato
- [ ] Downgrade genera crédito para siguiente pago
- [ ] Características del nuevo plan se aplican inmediatamente
- [ ] Fecha de próximo cobro se ajusta correctamente

---

### RF-008: Cancelación de Suscripción

**Prioridad:** Alta  
**Módulo:** Core - Suscripciones

**Descripción:**  
Los suscriptores deben poder cancelar su suscripción.

**Detalles:**
- Cancelación inmediata o al fin del período
- Preservación de datos históricos
- Notificación de cancelación
- Posibilidad de reactivar

**Criterios de Aceptación:**
- [ ] Cancelación inmediata funciona correctamente
- [ ] Cancelación al fin de período funciona correctamente
- [ ] Datos históricos se preservan
- [ ] Notificación se envía
- [ ] Reactivación es posible

---

### RF-009: Webhooks de Pasarela

**Prioridad:** Crítica  
**Módulo:** Core - Pagos

**Descripción:**  
El sistema debe procesar webhooks de las pasarelas de pago de forma segura.

**Detalles:**
- Verificación de firma del webhook
- Procesamiento asíncrono (queue)
- Manejo de eventos: pago exitoso, pago fallido, reembolso, chargeback
- Idempotencia (evitar duplicados)

**Criterios de Aceptación:**
- [ ] Webhooks se verifican correctamente
- [ ] Eventos se procesan en cola
- [ ] Pago exitoso actualiza suscripción
- [ ] Pago fallido inicia reintentos
- [ ] Duplicados se detectan y descartan

---

### RF-010: Sistema de Notificaciones

**Prioridad:** Alta  
**Módulo:** Core - Notificaciones

**Descripción:**  
El sistema debe enviar notificaciones por email para todos los eventos relevantes.

**Detalles:**
- 20+ tipos de notificaciones
- Plantillas personalizables
- Envío asíncrono (queue)
- Registro de envíos

**Tipos de Notificaciones:**
1. Bienvenida tras suscripción
2. Pago exitoso
3. Pago fallido
4. Reintento de pago
5. Prueba por expirar (7, 3, 1 días)
6. Prueba expirada
7. Período de gracia iniciado
8. Recordatorios de gracia (semanal)
9. Suscripción cancelada
10. Suscripción reactivada
11. Plan cambiado (upgrade)
12. Plan cambiado (downgrade)
13. Cupón aplicado
14. Autenticación 3DS requerida
15. Factura disponible
16. Referido exitoso
17. Tokens por agotarse (50%, 75%, 90%)
18. Tokens agotados
19. Actualización de datos de pago
20. Recordatorio de renovación (3 días antes)

**Criterios de Aceptación:**
- [ ] Todas las notificaciones se envían correctamente
- [ ] Plantillas son personalizables
- [ ] Envíos se registran en base de datos
- [ ] Queue procesa notificaciones asíncronamente

---

### RF-011: Registro de Auditoría

**Prioridad:** Alta  
**Módulo:** Core - Seguridad

**Descripción:**  
El sistema debe registrar todas las acciones relevantes para auditoría.

**Detalles:**
- Registro de acciones: crear, actualizar, eliminar, pagar, cancelar
- Información del usuario que realizó la acción
- Timestamp preciso
- Datos antes/después del cambio (opcional)

**Criterios de Aceptación:**
- [ ] Todas las acciones críticas se registran
- [ ] Logs incluyen usuario, timestamp y acción
- [ ] Logs son inmutables
- [ ] Consulta de logs es eficiente

---

### RF-012: Módulo de Tokens (Opcional)

**Prioridad:** Media  
**Módulo:** Opcional - Tokens

**Descripción:**  
Sistema de consumo basado en tokens para funcionalidades de pago por uso.

**Detalles:**
- Asignación de tokens por plan
- Consumo de tokens por acción
- Recarga manual de tokens
- Alertas de consumo (50%, 75%, 90%, 100%)

**Criterios de Aceptación:**
- [ ] Tokens se asignan según plan
- [ ] Consumo se registra correctamente
- [ ] Alertas se envían en umbrales correctos
- [ ] Recarga manual funciona

---

### RF-013: Módulo de Referidos (Opcional)

**Prioridad:** Baja  
**Módulo:** Opcional - Referidos

**Descripción:**  
Sistema de referidos con recompensas para ambas partes.

**Detalles:**
- Código único de referido por usuario
- Registro de referidos exitosos
- Aplicación de recompensas (descuentos, créditos)

**Criterios de Aceptación:**
- [ ] Código de referido se genera automáticamente
- [ ] Referido se registra al usarse código
- [ ] Recompensas se aplican correctamente
- [ ] Histórico de referidos está disponible

---

### RF-014: Módulo de Facturación (Opcional)

**Prioridad:** Media  
**Módulo:** Opcional - Facturación

**Descripción:**  
Generación de facturas electrónicas según normativa local.

**Detalles:**
- Integración con PAC (México) y DIAN (Colombia)
- Generación automática tras pago exitoso
- Almacenamiento de XML/PDF
- Envío por email

**Criterios de Aceptación:**
- [ ] Factura se genera tras pago
- [ ] XML/PDF se almacenan correctamente
- [ ] Email con factura se envía
- [ ] Consulta de facturas funciona

---

## Historias de Usuario

### HU-001: Suscripción a Plan Mensual
**Como** médico independiente  
**Quiero** suscribirme a un plan mensual de agenda médica  
**Para** gestionar mis citas sin compromiso a largo plazo

**Criterios de Aceptación:**
- Puedo ver todos los planes disponibles
- Puedo seleccionar plan mensual
- Puedo aplicar un cupón de descuento
- Puedo ingresar datos de tarjeta de forma segura
- Recibo confirmación por email
- Mi período de prueba de 14 días se activa correctamente

---

### HU-002: Cambio de Plan (Upgrade)
**Como** clínica pequeña  
**Quiero** cambiar mi plan a uno superior  
**Para** obtener más funcionalidades según crece mi negocio

**Criterios de Aceptación:**
- Puedo ver todos los planes disponibles
- Veo el costo prorrateado del cambio
- El cargo se procesa inmediatamente
- Las nuevas funcionalidades están disponibles de inmediato
- Recibo confirmación del cambio por email

---

### HU-003: Recuperación de Pago Fallido
**Como** administrador del sistema  
**Quiero** que los pagos fallidos se reintenten automáticamente  
**Para** evitar cancelaciones por problemas temporales de pago

**Criterios de Aceptación:**
- El sistema reintenta según configuración (ej. 3 veces)
- Recibo notificación de cada intento
- Si todos fallan, entro en período de gracia
- Puedo actualizar método de pago durante gracia
- Recibo recordatorios durante período de gracia

---

### HU-004: Aplicación de Cupón
**Como** nuevo usuario  
**Quiero** aplicar un cupón de descuento  
**Para** obtener un mejor precio en mi primer mes

**Criterios de Aceptación:**
- Puedo ingresar código de cupón al suscribirme
- El sistema valida el cupón antes de aplicarlo
- Veo el descuento reflejado en el total
- El descuento se aplica en la facturación
- Recibo confirmación del cupón aplicado

---

### HU-005: Pago con 3D Secure
**Como** usuario en Europa  
**Quiero** que mis pagos cumplan con PSD2  
**Para** tener seguridad en mis transacciones

**Criterios de Aceptación:**
- El primer pago me redirige a autenticación bancaria
- Puedo completar la autenticación 3DS
- El pago se confirma tras autenticación exitosa
- Recargos subsecuentes no requieren autenticación
- Recibo notificación de pago exitoso

---

### HU-006: Cancelación de Suscripción
**Como** usuario  
**Quiero** cancelar mi suscripción cuando ya no la necesite  
**Para** dejar de recibir cargos

**Criterios de Aceptación:**
- Puedo cancelar desde mi panel de usuario
- Puedo elegir cancelar inmediatamente o al fin del período
- Recibo confirmación de cancelación
- Mantengo acceso hasta el fin del período pagado
- Puedo reactivar si cambio de opinión

---

### HU-007: Monitoreo de Tokens
**Como** clínica con plan de tokens  
**Quiero** ver mi consumo de tokens en tiempo real  
**Para** saber cuándo necesito recargar

**Criterios de Aceptación:**
- Veo balance de tokens disponibles
- Veo histórico de consumo
- Recibo alertas al llegar a 75% y 90% de uso
- Puedo comprar tokens adicionales
- Los tokens se refrescan cada mes según mi plan

---

### HU-008: Sistema de Referidos
**Como** usuario satisfecho  
**Quiero** referir amigos y obtener beneficios  
**Para** compartir el servicio y obtener descuentos

**Criterios de Aceptación:**
- Tengo un código único de referido
- Puedo compartir mi código fácilmente
- Recibo notificación cuando alguien usa mi código
- Obtengo descuento o crédito por cada referido exitoso
- Veo listado de mis referidos

---

## Casos de Uso

### CU-001: Flujo Completo de Suscripción
1. Usuario visita página de planes
2. Usuario selecciona plan deseado
3. Usuario aplica cupón (opcional)
4. Usuario ingresa datos de facturación
5. Usuario ingresa datos de tarjeta
6. Sistema valida datos
7. Sistema redirige a 3DS (si aplica)
8. Usuario completa autenticación bancaria
9. Sistema procesa pago
10. Sistema crea suscripción
11. Sistema envía email de bienvenida
12. Usuario accede a funcionalidades

---

### CU-002: Flujo de Pago Recurrente
1. Sistema detecta próxima fecha de cobro
2. Sistema crea intento de pago
3. Sistema procesa pago con pasarela (MIT)
4. **Escenario Éxito:**
   - Pago aprobado
   - Suscripción renovada
   - Email de confirmación enviado
5. **Escenario Fallo:**
   - Pago rechazado
   - Email de notificación enviado
   - Reintento programado
   - Si todos los reintentos fallan → período de gracia

---

### CU-003: Flujo de Cambio de Plan
1. Usuario solicita cambio de plan
2. Sistema calcula diferencia de precio
3. Sistema calcula prorrateo
4. Usuario confirma cambio
5. **Upgrade:**
   - Sistema procesa cargo inmediato
   - Actualiza plan
   - Actualiza próxima fecha de cobro
6. **Downgrade:**
   - Sistema genera crédito
   - Actualiza plan
   - Aplica crédito en próximo cobro

---

### CU-004: Flujo de Webhook
1. Pasarela envía webhook
2. Sistema verifica firma
3. Sistema valida que no sea duplicado
4. Sistema procesa evento en cola
5. **Pago Exitoso:**
   - Actualiza estado de pago
   - Renueva suscripción
   - Envía notificación
6. **Pago Fallido:**
   - Actualiza estado de pago
   - Inicia proceso de reintento
   - Envía notificación

---

## Requisitos No Funcionales

### RNF-001: Performance
- **Tiempo de respuesta API:** <200ms (p95)
- **Procesamiento de pago:** <3s (p95)
- **Procesamiento de webhook:** <1s (p95)
- **Carga de listado:** <500ms para 1000 registros

### RNF-002: Escalabilidad
- **Suscriptores concurrentes:** Hasta 100,000
- **Pagos concurrentes:** Hasta 1,000/min
- **Webhooks concurrentes:** Hasta 5,000/min

### RNF-003: Disponibilidad
- **Uptime objetivo:** 99.9% (8.76 horas de downtime/año)
- **RPO (Recovery Point Objective):** 1 hora
- **RTO (Recovery Time Objective):** 4 horas

### RNF-004: Seguridad
- **Encriptación:** AES-256 para datos sensibles
- **HTTPS:** Obligatorio para todas las comunicaciones
- **PCI Compliance:** Nivel SAQ-A (tokenización completa)
- **Autenticación:** 3D Secure 2.0 para primer pago

### RNF-005: Compatibilidad
- **PHP:** 8.1+
- **Laravel:** 10.x, 11.x
- **MySQL:** 8.0+
- **PostgreSQL:** 13+ (opcional)
- **Redis:** 6.0+ (recomendado)

### RNF-006: Usabilidad
- **Documentación:** Completa y en español
- **Ejemplos:** Al menos 10 casos de uso documentados
- **Testing:** Cobertura ≥85%
- **API:** RESTful, predecible, versionada

### RNF-007: Mantenibilidad
- **Código:** PSR-12 compliant
- **Testing:** PHPUnit ≥9.0
- **CI/CD:** Tests automáticos en cada commit
- **Logs:** Compatibles con Laravel Log

---

## Dependencias y Restricciones

### Dependencias Técnicas
1. **Laravel Framework:** 10.x o 11.x
2. **PHP:** 8.1 o superior
3. **Base de Datos:** MySQL 8.0+ o PostgreSQL 13+
4. **Pasarela de Pago:** Openpay (inicialmente)
5. **Queue System:** Redis recomendado
6. **Email Provider:** Cualquier compatible con Laravel Mail

### Dependencias de Negocio
1. **Cuenta de Pasarela:** Requiere cuenta activa en Openpay
2. **Certificados SSL:** Obligatorio para cumplir PCI
3. **Servidor:** Linux recomendado, PHP configurado apropiadamente

### Restricciones
1. **No incluye UI:** El paquete es backend only
2. **No incluye tabla users:** Usa modelos existentes del proyecto
3. **No procesa tarjetas:** Usa tokenización de pasarela
4. **Límite de pasarelas:** Solo Openpay en v2.0

---

## Métricas de Éxito

### Métricas Técnicas
1. **Cobertura de Tests:** ≥85%
2. **Tiempo de Setup:** ≤30 minutos para instalación básica
3. **Performance:** API responde en <200ms (p95)
4. **Bugs Críticos:** 0 en producción durante 30 días

### Métricas de Negocio
1. **Tasa de Conversión:** ≥60% de usuarios completan suscripción
2. **Reducción de Fraude:** ≥70% con 3D Secure
3. **Recuperación de Pagos:** ≥40% de pagos fallidos recuperados
4. **Retención:** ≥80% de suscriptores tras primer mes

### Métricas de Adopción
1. **Instalaciones:** 100+ en primer trimestre
2. **Stars en GitHub:** 50+ en 6 meses
3. **Contribuidores:** 5+ externos en primer año
4. **Documentación:** 90% de usuarios encuentran respuestas sin soporte

---

## Apéndice

### Glosario

- **3DS/3D Secure:** Protocolo de autenticación para pagos con tarjeta
- **MIT:** Merchant Initiated Transaction (sin autenticación del usuario)
- **PSD2:** Payment Services Directive 2 (regulación europea)
- **SCA:** Strong Customer Authentication
- **Polimórfico:** Relaciones de base de datos que funcionan con múltiples modelos
- **Prorrateo:** Cálculo proporcional de pago al cambiar plan
- **Webhook:** Notificación HTTP que envía la pasarela
- **PAC:** Proveedor Autorizado de Certificación (México)
- **DIAN:** Dirección de Impuestos (Colombia)

### Referencias
1. [PSD2 Compliance Guide](https://www.europeanpaymentscouncil.eu/what-we-do/psd2)
2. [3D Secure 2.0 Specification](https://www.emvco.com/emv-technologies/3d-secure/)
3. [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
4. [Laravel Documentation](https://laravel.com/docs)
5. [Openpay API Reference](https://www.openpay.mx/docs/api/)

---

**Documento aprobado por:** Cesar Antolinez  
**Fecha de aprobación:** Enero 2026  
**Próxima revisión:** Julio 2026
