-- ============================================================================
-- DATABASE DDL - Sistema de Suscripciones
-- Plataforma SaaS de Gestión Médica
-- ============================================================================
-- Versión: 1.1
-- Fecha:  Enero 2026
-- Actualización: Campos 3D Secure (3DS)
-- ============================================================================

-- Configuración de base de datos
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- Tabla: users
-- Descripción: Usuarios del sistema con 4 roles
-- ============================================================================
CREATE TABLE `users` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL COMMENT 'Nombre completo del usuario',
    `email` VARCHAR(255) NOT NULL UNIQUE COMMENT 'Email único (login)',
    `email_verified_at` TIMESTAMP NULL COMMENT 'Fecha de verificación de email',
    `password` VARCHAR(255) NOT NULL COMMENT 'Hash de contraseña (bcrypt)',
    `role` ENUM('profesional', 'consultorio', 'asistente', 'paciente') NOT NULL COMMENT 'Rol del usuario',
    `country` ENUM('MX', 'CO') NOT NULL COMMENT 'País del usuario',
    `remember_token` VARCHAR(100) NULL COMMENT 'Token de "recordarme"',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL COMMENT 'Soft delete',
    
    INDEX `idx_email` (`email`),
    INDEX `idx_role` (`role`),
    INDEX `idx_country` (`country`),
    INDEX `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Usuarios del sistema';

-- ============================================================================
-- Tabla: plans
-- Descripción: Catálogo de planes de suscripción
-- ============================================================================
CREATE TABLE `plans` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL COMMENT 'Nombre del plan',
    `description` TEXT NULL COMMENT 'Descripción detallada del plan',
    `tokens_monthly` INT NOT NULL COMMENT 'Cantidad de tokens mensuales',
    `periodicity` ENUM('monthly', 'annual', 'annual_monthly_billing') NOT NULL COMMENT 'Periodicidad del plan',
    `price_mxn` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Precio en pesos mexicanos',
    `price_cop` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Precio en pesos colombianos',
    `trial_days` INT NOT NULL DEFAULT 0 COMMENT 'Días de trial',
    `active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Plan disponible para nuevas suscripciones',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_active` (`active`),
    INDEX `idx_periodicity` (`periodicity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planes de suscripción';

-- ============================================================================
-- Tabla: subscriptions [ACTUALIZADO - 3DS]
-- Descripción:  Suscripciones de usuarios a planes
-- ============================================================================
CREATE TABLE `subscriptions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario que tiene la suscripción',
    `plan_id` BIGINT UNSIGNED NOT NULL COMMENT 'Plan actual de la suscripción',
    `status` ENUM('trial', 'active', 'past_due', 'grace_period', 'cancelled', 'blocked') NOT NULL DEFAULT 'trial' COMMENT 'Estado de la suscripción',
    `periodicity` ENUM('monthly', 'annual', 'annual_monthly_billing') NOT NULL COMMENT 'Periodicidad de cobro',
    `starts_at` DATE NOT NULL COMMENT 'Fecha de inicio',
    `ends_at` DATE NULL COMMENT 'Fecha de fin (NULL si activa)',
    `next_billing_date` DATE NOT NULL COMMENT 'Próxima fecha de cobro',
    `card_token` VARCHAR(255) NULL COMMENT 'Token de tarjeta en Openpay',
    `manual_payment_reference` VARCHAR(255) NULL COMMENT 'Referencia de pago manual',
    `mit_enabled` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'MIT habilitado para pagos recurrentes',
    `first_payment_3ds_completed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Primer pago con 3DS exitoso',
    `pending_plan_id` BIGINT UNSIGNED NULL COMMENT 'Plan programado (downgrade)',
    `pending_plan_change_date` DATE NULL COMMENT 'Fecha de cambio programado',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL COMMENT 'Soft delete',
    
    FOREIGN KEY `fk_subscriptions_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY `fk_subscriptions_plan` (`plan_id`) REFERENCES `plans`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY `fk_subscriptions_pending_plan` (`pending_plan_id`) REFERENCES `plans`(`id`) ON DELETE SET NULL,
    
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_plan_id` (`plan_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_next_billing_date` (`next_billing_date`),
    INDEX `idx_deleted_at` (`deleted_at`),
    INDEX `idx_mit_enabled` (`mit_enabled`),
    INDEX `idx_first_payment_3ds` (`first_payment_3ds_completed`),
    INDEX `idx_renewal` (`next_billing_date`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Suscripciones de usuarios';

-- ============================================================================
-- Tabla: tokens_usage
-- Descripción: Tracking de consumo de tokens por período
-- ============================================================================
CREATE TABLE `tokens_usage` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario',
    `subscription_id` BIGINT UNSIGNED NOT NULL COMMENT 'Suscripción',
    `period_start` DATE NOT NULL COMMENT 'Inicio del período',
    `period_end` DATE NOT NULL COMMENT 'Fin del período',
    `used` INT NOT NULL DEFAULT 0 COMMENT 'Tokens usados',
    `total` INT NOT NULL COMMENT 'Tokens totales del período',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_tokens_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY `fk_tokens_subscription` (`subscription_id`) REFERENCES `subscriptions`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_subscription_id` (`subscription_id`),
    INDEX `idx_period_start` (`period_start`),
    INDEX `idx_user_period` (`user_id`, `period_start` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Consumo de tokens';

-- ============================================================================
-- Tabla: payments [ACTUALIZADO - 3DS]
-- Descripción: Registro de todos los pagos y sus estados 3DS
-- ============================================================================
CREATE TABLE `payments` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `subscription_id` BIGINT UNSIGNED NOT NULL COMMENT 'Suscripción asociada',
    `amount` DECIMAL(10,2) NOT NULL COMMENT 'Monto del pago',
    `currency` VARCHAR(3) NOT NULL COMMENT 'Moneda (MXN, COP)',
    `method` ENUM('card', 'bank_transfer') NOT NULL COMMENT 'Método de pago',
    `status` ENUM('pending', 'processing', 'requires_3ds', 'authenticating', 'authenticated', 'completed', 'failed', 'refunded', 'cancelled') NOT NULL DEFAULT 'pending' COMMENT 'Estado del pago',
    `openpay_transaction_id` VARCHAR(255) NULL COMMENT 'ID de transacción en Openpay',
    `attempt` INT NOT NULL DEFAULT 1 COMMENT 'Número de intento (1, 2, 3)',
    `paid_at` TIMESTAMP NULL COMMENT 'Fecha de pago completado',
    `error_code` VARCHAR(50) NULL COMMENT 'Código de error',
    `error_message` TEXT NULL COMMENT 'Mensaje de error',
    `requires_3ds` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Pago requiere 3DS',
    `three_ds_status` ENUM('not_required', 'pending', 'authenticated', 'failed', 'timeout') NOT NULL DEFAULT 'not_required' COMMENT 'Estado de 3DS',
    `three_ds_redirect_url` VARCHAR(500) NULL COMMENT 'URL del banco para autenticación',
    `three_ds_version` VARCHAR(10) NULL COMMENT 'Versión de 3DS (1.0, 2.0)',
    `authentication_required_notified_at` TIMESTAMP NULL COMMENT 'Cuándo se notificó al usuario',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_payments_subscription` (`subscription_id`) REFERENCES `subscriptions`(`id`) ON DELETE RESTRICT,
    
    INDEX `idx_subscription_id` (`subscription_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_openpay_transaction_id` (`openpay_transaction_id`),
    INDEX `idx_requires_3ds` (`requires_3ds`),
    INDEX `idx_three_ds_status` (`three_ds_status`),
    INDEX `idx_auth_notified` (`authentication_required_notified_at`),
    INDEX `idx_3ds_pending` (`requires_3ds`, `three_ds_status`, `authentication_required_notified_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pagos y estados 3DS';

-- ============================================================================
-- Tabla: coupons
-- Descripción:  Catálogo de cupones de descuento
-- ============================================================================
CREATE TABLE `coupons` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código único del cupón',
    `type` ENUM('percentage', 'fixed') NOT NULL COMMENT 'Tipo de descuento',
    `value` DECIMAL(10,2) NOT NULL COMMENT 'Valor del descuento',
    `duration_months` INT NULL COMMENT 'Duración en meses (NULL=permanente)',
    `applicable_plans` JSON NULL COMMENT 'IDs de planes (NULL=todos)',
    `usage_limit` INT NULL COMMENT 'Límite de usos (NULL=ilimitado)',
    `current_usage` INT NOT NULL DEFAULT 0 COMMENT 'Usos actuales',
    `expires_at` DATE NULL COMMENT 'Fecha de expiración',
    `active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Cupón activo',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_code` (`code`),
    INDEX `idx_active` (`active`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cupones de descuento';

-- ============================================================================
-- Tabla: user_coupons
-- Descripción: Relación de cupones aplicados por usuarios
-- ============================================================================
CREATE TABLE `user_coupons` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario',
    `coupon_id` BIGINT UNSIGNED NOT NULL COMMENT 'Cupón',
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de aplicación',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_user_coupons_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY `fk_user_coupons_coupon` (`coupon_id`) REFERENCES `coupons`(`id`) ON DELETE CASCADE,
    
    UNIQUE KEY `uk_user_coupon` (`user_id`, `coupon_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_coupon_id` (`coupon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cupones aplicados por usuarios';

-- ============================================================================
-- Tabla: referrals
-- Descripción: Sistema de referidos
-- ============================================================================
CREATE TABLE `referrals` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `referrer_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario que refiere',
    `referred_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario referido',
    `code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código único de referido',
    `referrer_benefit` JSON NOT NULL COMMENT 'Beneficios del referidor',
    `referred_benefit` JSON NOT NULL COMMENT 'Beneficios del referido',
    `status` ENUM('pending', 'completed', 'expired') NOT NULL DEFAULT 'pending' COMMENT 'Estado del referido',
    `completed_at` TIMESTAMP NULL COMMENT 'Fecha de completado',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_referrals_referrer` (`referrer_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY `fk_referrals_referred` (`referred_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_referrer_id` (`referrer_id`),
    INDEX `idx_referred_id` (`referred_id`),
    INDEX `idx_code` (`code`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sistema de referidos';

-- ============================================================================
-- Tabla: billing_data
-- Descripción: Datos fiscales de usuarios para facturación
-- ============================================================================
CREATE TABLE `billing_data` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL UNIQUE COMMENT 'Usuario (relación 1:1)',
    `country` ENUM('MX', 'CO') NOT NULL COMMENT 'País',
    `tax_id` VARCHAR(50) NOT NULL COMMENT 'RFC o NIT',
    `legal_name` VARCHAR(255) NOT NULL COMMENT 'Razón social',
    `tax_regime` VARCHAR(100) NULL COMMENT 'Régimen fiscal (solo MX)',
    `postal_code` VARCHAR(10) NULL COMMENT 'Código postal (solo MX)',
    `cfdi_use` VARCHAR(10) NULL COMMENT 'Uso de CFDI (solo MX)',
    `person_type` ENUM('natural', 'legal') NULL COMMENT 'Tipo de persona (solo CO)',
    `address` TEXT NULL COMMENT 'Dirección (solo CO)',
    `city` VARCHAR(100) NULL COMMENT 'Ciudad (solo CO)',
    `state` VARCHAR(100) NULL COMMENT 'Departamento (solo CO)',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_billing_data_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Datos fiscales de usuarios';

-- ============================================================================
-- Tabla:  invoices
-- Descripción:  Solicitudes y registro de facturas electrónicas
-- ============================================================================
CREATE TABLE `invoices` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario',
    `payment_id` BIGINT UNSIGNED NOT NULL COMMENT 'Pago asociado',
    `file_url` VARCHAR(500) NULL COMMENT 'Ruta del PDF',
    `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de solicitud',
    `sent_at` TIMESTAMP NULL COMMENT 'Fecha de envío',
    `status` ENUM('requested', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'requested' COMMENT 'Estado de la factura',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_invoices_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY `fk_invoices_payment` (`payment_id`) REFERENCES `payments`(`id`) ON DELETE RESTRICT,
    
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_payment_id` (`payment_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Facturas electrónicas';

-- ============================================================================
-- Tabla:  payment_retries
-- Descripción: Registro de reintentos de pagos fallidos
-- ============================================================================
CREATE TABLE `payment_retries` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `payment_id` BIGINT UNSIGNED NOT NULL COMMENT 'Pago asociado',
    `attempt` INT NOT NULL COMMENT 'Número de reintento',
    `tried_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha del reintento',
    `result` TEXT NULL COMMENT 'Resultado del reintento',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_payment_retries_payment` (`payment_id`) REFERENCES `payments`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_payment_id` (`payment_id`),
    INDEX `idx_tried_at` (`tried_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reintentos de pagos';

-- ============================================================================
-- Tabla: grace_periods
-- Descripción:  Períodos de gracia por fallos de pago
-- ============================================================================
CREATE TABLE `grace_periods` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `subscription_id` BIGINT UNSIGNED NOT NULL COMMENT 'Suscripción',
    `started_at` DATE NOT NULL COMMENT 'Fecha de inicio',
    `ends_at` DATE NOT NULL COMMENT 'Fecha de fin (2 meses)',
    `months_owed` INT NOT NULL DEFAULT 0 COMMENT 'Meses adeudados',
    `amount_owed` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Monto adeudado',
    `notifications_sent` INT NOT NULL DEFAULT 0 COMMENT 'Notificaciones enviadas',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_grace_periods_subscription` (`subscription_id`) REFERENCES `subscriptions`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_subscription_id` (`subscription_id`),
    INDEX `idx_ends_at` (`ends_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Períodos de gracia';

-- ============================================================================
-- Tabla:  notifications [ACTUALIZADO - 3DS]
-- Descripción: Log de notificaciones enviadas (20 tipos)
-- ============================================================================
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Usuario destinatario',
    `type` VARCHAR(100) NOT NULL COMMENT 'Tipo de notificación (20 tipos)',
    `sent_at` TIMESTAMP NULL COMMENT 'Fecha de envío',
    `status` ENUM('pending', 'sent', 'failed', 'bounced') NOT NULL DEFAULT 'pending' COMMENT 'Estado del envío',
    `metadata` JSON NULL COMMENT 'Datos adicionales',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_notifications_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_sent_at` (`sent_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones enviadas';

-- ============================================================================
-- Tabla: audit_logs
-- Descripción:  Registro de auditoría de acciones críticas
-- ============================================================================
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NULL COMMENT 'Usuario (NULL si es sistema)',
    `action` VARCHAR(100) NOT NULL COMMENT 'Acción realizada',
    `entity` VARCHAR(100) NOT NULL COMMENT 'Entidad afectada',
    `entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del registro',
    `before` JSON NULL COMMENT 'Estado antes',
    `after` JSON NULL COMMENT 'Estado después',
    `ip` VARCHAR(45) NULL COMMENT 'IP de origen',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_audit_logs_user` (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_entity` (`entity`, `entity_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Logs de auditoría';

-- ============================================================================
-- Índices compuestos adicionales para optimización
-- ============================================================================

-- Consulta de renovaciones diarias
CREATE INDEX idx_subscriptions_renewal_query 
ON subscriptions(next_billing_date, status, mit_enabled);

-- Consulta de pagos 3DS pendientes
CREATE INDEX idx_payments_3ds_pending_query 
ON payments(requires_3ds, three_ds_status, authentication_required_notified_at) 
WHERE requires_3ds = TRUE AND three_ds_status = 'pending';

-- Consulta de tokens de usuario actual
CREATE INDEX idx_tokens_current_period 
ON tokens_usage(user_id, period_end DESC);

-- Consulta de períodos de gracia activos
CREATE INDEX idx_grace_periods_active 
ON grace_periods(ends_at, subscription_id) 
WHERE ends_at >= CURDATE();

-- ============================================================================
-- Datos de ejemplo (OPCIONAL - solo para desarrollo)
-- ============================================================================

-- Plan de ejemplo
INSERT INTO `plans` (`name`, `description`, `tokens_monthly`, `periodicity`, `price_mxn`, `price_cop`, `trial_days`, `active`) VALUES
('Google Tech + IA 50', 'Plan básico con 50 tokens mensuales', 5000, 'monthly', 299.00, 50000.00, 14, TRUE),
('Google Tech + IA 100', 'Plan profesional con 100 tokens mensuales', 10000, 'monthly', 499.00, 80000.00, 14, TRUE),
('Google Tech + IA 200', 'Plan empresarial con 200 tokens mensuales', 20000, 'monthly', 899.00, 150000.00, 14, TRUE);

-- ============================================================================
-- Triggers para auditoría (OPCIONAL)
-- ============================================================================

DELIMITER $$

-- Trigger para auditar cambios en subscriptions
CREATE TRIGGER trg_subscriptions_audit_update
AFTER UPDATE ON subscriptions
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status OR OLD.plan_id != NEW.plan_id THEN
        INSERT INTO audit_logs (user_id, action, entity, entity_id, `before`, `after`, ip)
        VALUES (
            NEW.user_id,
            'update',
            'subscription',
            NEW.id,
            JSON_OBJECT('status', OLD.status, 'plan_id', OLD.plan_id),
            JSON_OBJECT('status', NEW.status, 'plan_id', NEW.plan_id),
            NULL
        );
    END IF;
END$$

-- Trigger para auditar cambios en payments
CREATE TRIGGER trg_payments_audit_update
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    IF OLD. status != NEW.status OR OLD. three_ds_status != NEW.three_ds_status THEN
        INSERT INTO audit_logs (user_id, action, entity, entity_id, `before`, `after`, ip)
        SELECT 
            s.user_id,
            'update',
            'payment',
            NEW.id,
            JSON_OBJECT('status', OLD. status, 'three_ds_status', OLD.three_ds_status),
            JSON_OBJECT('status', NEW.status, 'three_ds_status', NEW.three_ds_status),
            NULL
        FROM subscriptions s
        WHERE s.id = NEW.subscription_id;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- Restaurar configuración
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================

-- NOTAS:
-- 1. Ejecutar este script en base de datos limpia
-- 2. Para producción, ajustar datos de ejemplo según necesidades
-- 3. Triggers de auditoría son opcionales pero recomendados
-- 4. Índices compuestos mejoran performance de queries frecuentes
-- 5. Campos 3DS (requires_3ds, three_ds_*, mit_enabled) son críticos para flujo de pagos
-- 6. Soft delete habilitado solo en users y subscriptions
-- 7. Foreign keys configurados con ON DELETE apropiado para cada caso

-- VERSIÓN:  1.1
-- CAMBIOS: 
-- - Agregados campos 3DS en tabla payments
-- - Agregados campos MIT en tabla subscriptions
-- - Agregados índices para queries de 3DS
-- - Agregados triggers de auditoría
-- - Optimizados índices compuestos