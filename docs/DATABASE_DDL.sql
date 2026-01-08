-- ============================================================================
-- DATABASE DDL - Sistema de Planes y Suscripciones
-- Plataforma SaaS de Gestión Médica (México y Colombia)
-- ============================================================================
-- Versión: 1.0
-- Fecha: Enero 2026
-- Motor: MySQL 8.0+
-- Charset: utf8mb4
-- Collation: utf8mb4_unicode_ci
-- ============================================================================

-- Configuración inicial
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- 1. TABLA: users
-- Descripción: Almacena todos los usuarios del sistema
-- ============================================================================

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL COMMENT 'Nombre completo del usuario',
    email VARCHAR(255) NOT NULL UNIQUE COMMENT 'Email único del usuario',
    email_verified_at TIMESTAMP NULL COMMENT 'Fecha de verificación de email',
    password VARCHAR(255) NOT NULL COMMENT 'Contraseña hasheada',
    role ENUM('profesional', 'consultorio', 'asistente', 'paciente') NOT NULL COMMENT 'Rol del usuario',
    country ENUM('MX', 'CO') NOT NULL COMMENT 'País del usuario',
    remember_token VARCHAR(100) NULL COMMENT 'Token para "recordarme"',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft delete',
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_country (country),
    INDEX idx_deleted_at (deleted_at),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Usuarios del sistema con autenticación y roles';

-- ============================================================================
-- 2. TABLA: plans
-- Descripción: Define los planes de suscripción disponibles
-- ============================================================================

CREATE TABLE plans (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL COMMENT 'Nombre del plan',
    description TEXT NULL COMMENT 'Descripción detallada',
    tokens_monthly INT UNSIGNED NOT NULL COMMENT 'Tokens mensuales incluidos',
    periodicity ENUM('monthly', 'annual', 'annual_monthly_billing') NOT NULL COMMENT 'Periodicidad del plan',
    price_mxn DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Precio en pesos mexicanos',
    price_cop DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Precio en pesos colombianos',
    trial_days INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Días de trial (0 = sin trial)',
    active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Si el plan está activo',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_active (active),
    INDEX idx_periodicity (periodicity),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Planes de suscripción con características y precios';

-- ============================================================================
-- 3. TABLA: subscriptions
-- Descripción: Gestiona las suscripciones activas de los usuarios
-- ============================================================================

CREATE TABLE subscriptions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    plan_id BIGINT UNSIGNED NOT NULL,
    status ENUM('trialing', 'active', 'past_due', 'cancelled', 'blocked') NOT NULL DEFAULT 'trialing' COMMENT 'Estado de la suscripción',
    periodicity ENUM('monthly', 'annual', 'annual_monthly_billing') NOT NULL COMMENT 'Periodicidad contratada',
    starts_at DATETIME NOT NULL COMMENT 'Fecha de inicio',
    ends_at DATETIME NULL COMMENT 'Fecha de finalización (si cancelada)',
    next_billing_date DATETIME NOT NULL COMMENT 'Próxima fecha de cobro',
    card_token VARCHAR(255) NULL COMMENT 'Token de tarjeta en Openpay (encriptado)',
    manual_payment_reference VARCHAR(255) NULL COMMENT 'Referencia de pago manual',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft delete',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE RESTRICT,
    
    INDEX idx_user_status (user_id, status),
    INDEX idx_next_billing (next_billing_date, status),
    INDEX idx_status (status),
    INDEX idx_deleted_at (deleted_at),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Suscripciones de usuarios con estado y fechas de facturación';

-- ============================================================================
-- 4. TABLA: tokens_usage
-- Descripción: Registra el consumo mensual de tokens por usuario
-- ============================================================================

CREATE TABLE tokens_usage (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    subscription_id BIGINT UNSIGNED NOT NULL,
    period_start DATE NOT NULL COMMENT 'Inicio del período',
    period_end DATE NOT NULL COMMENT 'Fin del período',
    used INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Tokens consumidos',
    total INT UNSIGNED NOT NULL COMMENT 'Total de tokens del período',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
    
    INDEX idx_user_period (user_id, period_start, period_end),
    INDEX idx_subscription_period (subscription_id, period_start),
    UNIQUE KEY idx_user_period_unique (user_id, period_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracking de consumo de tokens por período';

-- ============================================================================
-- 5. TABLA: payments
-- Descripción: Registra todas las transacciones de pago
-- ============================================================================

CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subscription_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL COMMENT 'Monto del pago',
    currency ENUM('MXN', 'COP') NOT NULL COMMENT 'Moneda',
    method ENUM('card', 'transfer') NOT NULL COMMENT 'Método de pago',
    status ENUM('pending', 'successful', 'failed', 'refunded') NOT NULL DEFAULT 'pending' COMMENT 'Estado del pago',
    openpay_transaction_id VARCHAR(255) NULL COMMENT 'ID de transacción en Openpay',
    attempt INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Número de intento',
    paid_at DATETIME NULL COMMENT 'Fecha de pago exitoso',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
    
    INDEX idx_subscription_status (subscription_id, status),
    INDEX idx_openpay_transaction (openpay_transaction_id),
    INDEX idx_status_created (status, created_at),
    INDEX idx_paid_at (paid_at),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de transacciones de pago';

-- ============================================================================
-- 6. TABLA: coupons
-- Descripción: Define cupones de descuento disponibles
-- ============================================================================

CREATE TABLE coupons (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código del cupón (único, case-insensitive)',
    type ENUM('percentage', 'fixed_amount') NOT NULL COMMENT 'Tipo de descuento',
    value DECIMAL(10,2) NOT NULL COMMENT 'Valor del descuento',
    duration_months INT UNSIGNED NULL COMMENT 'Duración en meses (NULL = permanente)',
    applicable_plans JSON NULL COMMENT 'IDs de planes aplicables (NULL = todos)',
    usage_limit INT UNSIGNED NULL COMMENT 'Límite total de usos (NULL = ilimitado)',
    current_usage INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Usos actuales',
    expires_at DATETIME NULL COMMENT 'Fecha de expiración',
    active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Si el cupón está activo',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_code_active (code, active),
    INDEX idx_active_expires (active, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Cupones de descuento con configuración y límites';

-- ============================================================================
-- 7. TABLA: user_coupons
-- Descripción: Registra qué usuarios han aplicado qué cupones
-- ============================================================================

CREATE TABLE user_coupons (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    coupon_id BIGINT UNSIGNED NOT NULL,
    applied_at DATETIME NOT NULL COMMENT 'Fecha de aplicación',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE,
    
    UNIQUE KEY idx_user_coupon_unique (user_id, coupon_id),
    INDEX idx_coupon_applied (coupon_id, applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Asociación de cupones aplicados por usuario';

-- ============================================================================
-- 8. TABLA: referrals
-- Descripción: Gestiona el sistema de referidos
-- ============================================================================

CREATE TABLE referrals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    referrer_id BIGINT UNSIGNED NOT NULL COMMENT 'Usuario que refiere',
    referred_id BIGINT UNSIGNED NOT NULL COMMENT 'Usuario referido',
    code VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código único de referido',
    referrer_benefit JSON NOT NULL COMMENT 'Beneficios del referidor',
    referred_benefit JSON NOT NULL COMMENT 'Beneficios del referido',
    status ENUM('pending', 'completed', 'expired') NOT NULL DEFAULT 'pending' COMMENT 'Estado del referido',
    completed_at DATETIME NULL COMMENT 'Fecha de conversión',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (referrer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (referred_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_referrer_status (referrer_id, status),
    INDEX idx_referred (referred_id),
    INDEX idx_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sistema de referidos con tracking y beneficios';

-- ============================================================================
-- 9. TABLA: billing_data
-- Descripción: Almacena datos fiscales de los usuarios
-- ============================================================================

CREATE TABLE billing_data (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    country ENUM('MX', 'CO') NOT NULL COMMENT 'País',
    tax_id VARCHAR(50) NOT NULL COMMENT 'RFC (MX) o NIT (CO) - encriptado',
    legal_name VARCHAR(255) NOT NULL COMMENT 'Razón social - encriptado',
    tax_regime VARCHAR(100) NULL COMMENT 'Régimen fiscal (solo MX)',
    postal_code VARCHAR(10) NULL COMMENT 'Código postal (solo MX)',
    cfdi_use VARCHAR(100) NULL COMMENT 'Uso de CFDI (solo MX)',
    person_type ENUM('natural', 'juridica') NULL COMMENT 'Tipo de persona (solo CO)',
    address VARCHAR(255) NULL COMMENT 'Dirección (solo CO)',
    city VARCHAR(100) NULL COMMENT 'Ciudad (solo CO)',
    state VARCHAR(100) NULL COMMENT 'Departamento (solo CO)',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    UNIQUE KEY idx_user (user_id),
    INDEX idx_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Datos fiscales de usuarios para facturación';

-- ============================================================================
-- 10. TABLA: invoices
-- Descripción: Registra solicitudes y facturas generadas
-- ============================================================================

CREATE TABLE invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    payment_id BIGINT UNSIGNED NOT NULL,
    file_url VARCHAR(500) NULL COMMENT 'URL del PDF de factura',
    requested_at DATETIME NOT NULL COMMENT 'Fecha de solicitud',
    sent_at DATETIME NULL COMMENT 'Fecha de envío',
    status ENUM('pending', 'generated', 'sent') NOT NULL DEFAULT 'pending' COMMENT 'Estado',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
    
    INDEX idx_user_status (user_id, status),
    INDEX idx_payment (payment_id),
    INDEX idx_status_requested (status, requested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Solicitudes y facturas electrónicas';

-- ============================================================================
-- 11. TABLA: payment_retries
-- Descripción: Registra reintentos de pagos fallidos
-- ============================================================================

CREATE TABLE payment_retries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT UNSIGNED NOT NULL,
    attempt INT UNSIGNED NOT NULL COMMENT 'Número de reintento (1-3)',
    tried_at DATETIME NOT NULL COMMENT 'Fecha del reintento',
    result TEXT NOT NULL COMMENT 'Resultado/mensaje del reintento',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
    
    INDEX idx_payment_attempt (payment_id, attempt),
    INDEX idx_tried_at (tried_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de reintentos de pagos fallidos';

-- ============================================================================
-- 12. TABLA: grace_periods
-- Descripción: Gestiona períodos de gracia por fallos de pago
-- ============================================================================

CREATE TABLE grace_periods (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subscription_id BIGINT UNSIGNED NOT NULL,
    started_at DATETIME NOT NULL COMMENT 'Inicio del período de gracia',
    ends_at DATETIME NOT NULL COMMENT 'Fin (2 meses después)',
    months_owed INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Meses adeudados',
    amount_owed DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Monto total de deuda',
    notifications_sent INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Recordatorios enviados',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
    
    UNIQUE KEY idx_subscription (subscription_id),
    INDEX idx_ends_at (ends_at),
    INDEX idx_started_at (started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Períodos de gracia por fallo de pago';

-- ============================================================================
-- 13. TABLA: notifications
-- Descripción: Registra todas las notificaciones enviadas a usuarios
-- ============================================================================

CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    type VARCHAR(100) NOT NULL COMMENT 'Tipo de notificación',
    sent_at DATETIME NULL COMMENT 'Fecha de envío',
    status ENUM('pending', 'sent', 'failed') NOT NULL DEFAULT 'pending' COMMENT 'Estado',
    metadata JSON NULL COMMENT 'Datos adicionales',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_type (user_id, type),
    INDEX idx_status_sent (status, sent_at),
    INDEX idx_type (type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de notificaciones por email';

-- ============================================================================
-- 14. TABLA: audit_logs
-- Descripción: Registro de auditoría de todas las acciones críticas
-- ============================================================================

CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL COMMENT 'Usuario que ejecuta (NULL = sistema)',
    action VARCHAR(100) NOT NULL COMMENT 'Acción realizada',
    entity VARCHAR(100) NOT NULL COMMENT 'Entidad afectada',
    entity_id BIGINT UNSIGNED NOT NULL COMMENT 'ID de la entidad',
    before JSON NULL COMMENT 'Estado anterior',
    after JSON NULL COMMENT 'Estado nuevo',
    ip VARCHAR(45) NULL COMMENT 'IP de origen',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_entity (entity, entity_id),
    INDEX idx_user_action (user_id, action),
    INDEX idx_created_at (created_at),
    INDEX idx_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit log de acciones críticas del sistema';

-- ============================================================================
-- Restaurar configuración
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
