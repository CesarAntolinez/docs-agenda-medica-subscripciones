# Gestor de Suscripciones Laravel

Paquete completo de gestión de suscripciones para Laravel con soporte multi-pasarela, 3D Secure, relaciones polimórficas y más.

[![PHP Version](https://img.shields.io/badge/PHP-8.1%2B-blue)](https://www.php.net/)
[![Laravel Version](https://img.shields.io/badge/Laravel-10.x%20%7C%2011.x-red)](https://laravel.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-success)](https://github.com/CesarAntolinez/laravel-subscription-manager)

---

## 🚀 Características

- ✅ **Relaciones Polimórficas** - Suscribir Usuarios, Empresas, Equipos, cualquier modelo
- ✅ **Soporte Multi-Pasarela** - Openpay, Stripe, Mercadopago (interfaz abstraída)
- ✅ **3D Secure 2.0** - Implementación completa de cumplimiento PSD2
- ✅ **Cupones de Descuento** - Porcentaje, monto fijo, basado en duración (característica CORE)
- ✅ **Períodos de Prueba** - Días de prueba configurables por plan
- ✅ **Períodos de Gracia** - Manejar pagos fallidos con gracia (2 meses por defecto)
- ✅ **Reintentos de Pago** - Mecanismo automático de reintento con intentos configurables
- ✅ **Webhooks** - Procesar eventos de pago de forma asíncrona
- ⚙️ **Tokens Opcionales** - Módulo de facturación basado en consumo
- ⚙️ **Referidos Opcionales** - Sistema completo de referidos
- ⚙️ **Facturación Opcional** - Facturación electrónica (PAC/DIAN)
- 🔒 **Registro de Auditoría** - Rastro de auditoría completo para cumplimiento
- 📧 **20+ Notificaciones** - Emails transaccionales para todos los eventos

---

## 📖 Documentación

### Planificación
- **[Documento de Requerimientos Funcionales (PRD)](./docs/PRD.md)** - Requerimientos completos del producto
- **[Roadmap de Desarrollo](./docs/ROADMAP.md)** - Plan de desarrollo con asignación de equipo

### Primeros Pasos
- **[Guía de Instalación](./docs/INSTALLATION.md)** - Instalación paso a paso
- **[Configuración](./docs/CONFIGURATION.md)** - Opciones de configuración
- **[Relaciones Polimórficas](./docs/POLYMORPHIC_RELATIONSHIPS.md)** - Guía de uso

### Referencia
- **[Características del Paquete](./docs/PACKAGE_FEATURES.md)** - Lista completa de características
- **[Esquema de Base de Datos](./docs/DATABASE_SCHEMA.md)** - Estructura de base de datos
- **[API y Webhooks](./docs/API_WEBHOOKS.md)** - Endpoints de API
- **[Integración 3D Secure](./docs/3DS_INTEGRATION.md)** - Implementación 3DS
- **[Arquitectura](./docs/ARCHITECTURE.md)** - Arquitectura del sistema
- **[Casos de Uso](./docs/USE_CASES.md)** - Casos de uso detallados
- **[Flujos de Usuario](./docs/USER_FLOWS.md)** - Diagramas de flujo

### Avanzado
- **[Extender el Paquete](./docs/EXTENDING.md)** - Guía de personalización
- **[Recomendaciones](./docs/RECOMMENDATIONS.md)** - Mejores prácticas

---

## 🎯 Inicio Rápido

### 1. Instalar vía Composer

```bash
composer require cesarantolinez/laravel-subscription-manager
```

### 2. Publicar Configuración y Migraciones

```bash
php artisan vendor:publish --tag=subscription-config
php artisan vendor:publish --tag=subscription-migrations
php artisan migrate
```

### 3. Configurar Entorno

```env
# .env
SUBSCRIPTION_SUBSCRIBER_MODEL=App\\Models\\User
PAYMENT_GATEWAY=openpay
OPENPAY_MERCHANT_ID=your_merchant_id
OPENPAY_PRIVATE_KEY=sk_your_private_key
OPENPAY_PUBLIC_KEY=pk_your_public_key
```

### 4. Agregar Trait a tu Modelo

```php
use CesarAntolinez\LaravelSubscriptionManager\Traits\HasSubscription;

class User extends Authenticatable
{
    use HasSubscription;
}
```

### 5. Suscribirse a un Plan

```php
$user = User::find(1);
$plan = Plan::where('name', 'Professional Plan')->first();

$subscription = $user->subscribeToPlan($plan);

// Verificar estado
if ($user->hasActiveSubscription()) {
    echo "¡Suscripción activa!";
}
```

---

## 💡 Conceptos Fundamentales

### Relaciones Polimórficas

A diferencia de los paquetes de suscripción tradicionales, este utiliza **relaciones polimórficas** para trabajar con cualquier modelo:

```php
// Suscripciones de usuarios
class User extends Authenticatable {
    use HasSubscription;
}

// Suscripciones de empresas
class Company extends Model {
    use HasSubscription;
}

// Suscripciones de equipos
class Team extends Model {
    use HasSubscription;
}
```

Todos funcionan sin problemas:
```php
$user->subscribeToPlan($plan);
$company->subscribeToPlan($plan);
$team->subscribeToPlan($plan);
```

### Abstracción de Pasarela de Pagos

Fácil de cambiar entre pasarelas o agregar personalizadas:

```php
// config/subscription.php
'payment_gateway' => env('PAYMENT_GATEWAY', 'openpay'),

'gateways' => [
    'openpay' => OpenpayGateway::class,
    'stripe' => StripeGateway::class,
    'custom' => MyCustomGateway::class,
],
```

### Características Modulares

Habilita solo lo que necesitas:

```php
// config/subscription.php
'features' => [
    'tokens' => true,      // Seguimiento de consumo
    'referrals' => true,   // Sistema de referidos
    'invoicing' => false,  // Facturación electrónica
],
```

---

## 📊 Esquema de Base de Datos

### Tablas Principales (Siempre Incluidas)
- `plans` - Planes de suscripción
- `subscriptions` - Suscripciones de suscriptores (polimórfico)
- `payments` - Registros de pagos con 3DS
- `payment_retries` - Seguimiento de reintentos
- `grace_periods` - Gestión de períodos de gracia
- `billing_data` - Información fiscal/facturación (polimórfico)
- `coupons` - Cupones de descuento **[CORE]**
- `subscriber_coupons` - Cupones aplicados (polimórfico) **[CORE]**
- `notifications` - Registro de notificaciones (polimórfico)
- `audit_logs` - Rastro de auditoría (polimórfico)

### Tablas Opcionales (Migraciones Separadas)
- `tokens_usage` - Consumo de tokens (polimórfico) **[OPCIONAL]**
- `referrals` - Sistema de referidos (polimórfico) **[OPCIONAL]**
- `invoices` - Facturación electrónica (polimórfico) **[OPCIONAL]**

### Sin Tabla de Usuarios
El paquete **NO** incluye una tabla de usuarios. Utiliza relaciones polimórficas para trabajar con tus modelos existentes.

---

## 🔐 Características de Seguridad

### Implementación 3D Secure 2.0

- Cumplimiento de Autenticación Fuerte de Cliente (SCA)
- Cumplimiento de regulación PSD2
- Transacciones Iniciadas por el Comerciante (MIT) después del primer pago
- Fraude y contracargos reducidos

### Cumplimiento PCI

- Tokenización de tarjetas (sin almacenamiento de tarjetas)
- La pasarela de pagos maneja datos sensibles
- Verificación segura de webhooks
- Datos de facturación encriptados

---

## 🌍 Pasarelas de Pago Soportadas

| Pasarela | Estado | Soporte 3DS | Países |
|---------|--------|-------------|-----------|
| **Openpay** | ✅ Completo | ✅ Sí | MX, CO |
| **Stripe** | 🔄 Próximamente | ✅ Sí | Global |
| **Mercadopago** | 🔄 Próximamente | ✅ Sí | LATAM |

---

## 📧 Tipos de Notificaciones

20+ emails transaccionales:
- Bienvenida, pago exitoso/fallido, recordatorios
- Prueba por expirar/expirada
- Inicio de período de gracia/recordatorios
- Suscripción cancelada/reactivada
- Plan cambiado (upgrade/downgrade)
- Referido exitoso
- Factura disponible
- Alertas de uso de tokens (50%, 75%, 90%, 100%)
- **Autenticación de pago requerida (3DS)**

---

## 🧪 Pruebas

```bash
# Ejecutar pruebas del paquete
composer test

# Ejecutar con cobertura
composer test:coverage
```

---

## 📦 Requisitos

- **PHP:** 8.1+
- **Laravel:** 10.x o 11.x
- **Base de Datos:** MySQL 8.0+ / PostgreSQL 13+ / MariaDB 10.5+
- **Opcional:** Redis (recomendado para colas y caché)

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor consulta [CONTRIBUTING.md](CONTRIBUTING.md) para más detalles.

---

## 📄 Licencia

Este paquete es software de código abierto licenciado bajo la [licencia MIT](LICENSE).

---

## 📞 Soporte

- **Documentación:** [Documentación Completa](./docs/)
- **Problemas:** [GitHub Issues](https://github.com/CesarAntolinez/laravel-subscription-manager/issues)
- **Discusiones:** [GitHub Discussions](https://github.com/CesarAntolinez/laravel-subscription-manager/discussions)

---

## 🙏 Créditos

Creado y mantenido por [Cesar Antolinez](https://github.com/CesarAntolinez)

---

## 📝 Registro de Cambios

Ver [CHANGELOG.md](CHANGELOG.md) para cambios recientes.

---

**Version:** 2.0  
**Last Updated:** January 2026
