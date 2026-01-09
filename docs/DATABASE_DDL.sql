-- ============================================================================
-- DATABASE DDL - Laravel Subscription Manager Package
-- Generic Subscription Management System
-- ============================================================================
-- Versión: 2.0
-- Fecha:  Enero 2026
-- Actualización: Polymorphic Relationships (subscriber_type/subscriber_id)
-- ============================================================================

-- Configuración de base de datos
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- NOTE: User/Subscriber table is NOT included in this package
-- The package uses POLYMORPHIC RELATIONSHIPS to work with any model:
--   - App\Models\User
--   - App\Models\Company
--   - App\Models\Team
--   - App\Models\Organization
-- The host application must provide a "subscribable" model with HasSubscription trait
-- ============================================================================

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
-- Tabla: subscriptions [CORE - Polymorphic Relationship]
-- Descripción: Subscriptions linked to any subscribable model
-- ============================================================================
CREATE TABLE `subscriptions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship (can be User, Company, Team, etc.)
    `subscriber_type` VARCHAR(255) NOT NULL COMMENT 'Polymorphic model class (App\\Models\\User, App\\Models\\Company, etc.)',
    `subscriber_id` BIGINT UNSIGNED NOT NULL COMMENT 'Polymorphic model ID',
    
    `plan_id` BIGINT UNSIGNED NOT NULL COMMENT 'Current plan',
    `status` ENUM('trial', 'active', 'past_due', 'grace_period', 'cancelled', 'blocked') NOT NULL DEFAULT 'trial' COMMENT 'Subscription status',
    `periodicity` ENUM('monthly', 'annual', 'annual_monthly_billing') NOT NULL COMMENT 'Billing periodicity',
    `starts_at` DATE NOT NULL COMMENT 'Start date',
    `ends_at` DATE NULL COMMENT 'End date (NULL if active)',
    `next_billing_date` DATE NOT NULL COMMENT 'Next billing date',
    `card_token` VARCHAR(255) NULL COMMENT 'Tokenized card from payment gateway',
    `manual_payment_reference` VARCHAR(255) NULL COMMENT 'Manual payment reference',
    `mit_enabled` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'MIT enabled for recurring payments',
    `first_payment_3ds_completed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'First payment with 3DS successful',
    `pending_plan_id` BIGINT UNSIGNED NULL COMMENT 'Scheduled plan change (downgrade)',
    `pending_plan_change_date` DATE NULL COMMENT 'Scheduled change date',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL COMMENT 'Soft delete',
    
    FOREIGN KEY `fk_subscriptions_plan` (`plan_id`) REFERENCES `plans`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY `fk_subscriptions_pending_plan` (`pending_plan_id`) REFERENCES `plans`(`id`) ON DELETE SET NULL,
    
    INDEX `idx_subscriber` (`subscriber_type`, `subscriber_id`),
    INDEX `idx_plan_id` (`plan_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_next_billing_date` (`next_billing_date`),
    INDEX `idx_deleted_at` (`deleted_at`),
    INDEX `idx_mit_enabled` (`mit_enabled`),
    INDEX `idx_first_payment_3ds` (`first_payment_3ds_completed`),
    INDEX `idx_renewal` (`next_billing_date`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subscriptions - Polymorphic relation to any subscribable model';

-- ============================================================================
-- Tabla: tokens_usage [OPTIONAL MODULE - Polymorphic Relationship]
-- Descripción: Token consumption tracking per billing period
-- NOTE: Only created if 'tokens' feature is enabled in package config
-- ============================================================================
CREATE TABLE `tokens_usage` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship
    `subscriber_type` VARCHAR(255) NOT NULL COMMENT 'Polymorphic model class',
    `subscriber_id` BIGINT UNSIGNED NOT NULL COMMENT 'Polymorphic model ID',
    
    `subscription_id` BIGINT UNSIGNED NOT NULL COMMENT 'Subscription',
    `period_start` DATE NOT NULL COMMENT 'Period start',
    `period_end` DATE NOT NULL COMMENT 'Period end',
    `used` INT NOT NULL DEFAULT 0 COMMENT 'Tokens used',
    `total` INT NOT NULL COMMENT 'Total tokens for period',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_tokens_subscription` (`subscription_id`) REFERENCES `subscriptions`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_subscriber` (`subscriber_type`, `subscriber_id`),
    INDEX `idx_subscription_id` (`subscription_id`),
    INDEX `idx_period_start` (`period_start`),
    INDEX `idx_subscriber_period` (`subscriber_type`, `subscriber_id`, `period_start` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Token consumption tracking [OPTIONAL]';

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
-- Tabla: subscriber_coupons [CORE - Polymorphic Relationship]
-- Descripción: Coupons applied by subscribers (prevents reuse)
-- ============================================================================
CREATE TABLE `subscriber_coupons` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship
    `subscriber_type` VARCHAR(255) NOT NULL COMMENT 'Polymorphic model class',
    `subscriber_id` BIGINT UNSIGNED NOT NULL COMMENT 'Polymorphic model ID',
    
    `coupon_id` BIGINT UNSIGNED NOT NULL COMMENT 'Coupon',
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Application date',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_subscriber_coupons_coupon` (`coupon_id`) REFERENCES `coupons`(`id`) ON DELETE CASCADE,
    
    UNIQUE KEY `uk_subscriber_coupon` (`subscriber_type`, `subscriber_id`, `coupon_id`),
    INDEX `idx_subscriber` (`subscriber_type`, `subscriber_id`),
    INDEX `idx_coupon_id` (`coupon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Coupons applied by subscribers [CORE]';

-- ============================================================================
-- Tabla: referrals [OPTIONAL MODULE - Polymorphic Relationship]
-- Descripción: Referral system with benefit tracking
-- NOTE: Only created if 'referrals' feature is enabled in package config
-- ============================================================================
CREATE TABLE `referrals` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship for Referrer
    `referrer_type` VARCHAR(255) NOT NULL COMMENT 'Referrer polymorphic model class',
    `referrer_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referrer polymorphic model ID',
    
    -- Polymorphic Relationship for Referred
    `referred_type` VARCHAR(255) NOT NULL COMMENT 'Referred polymorphic model class',
    `referred_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referred polymorphic model ID',
    
    `code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique referral code',
    `referrer_benefit` JSON NOT NULL COMMENT 'Referrer benefits (discount, tokens, credit)',
    `referred_benefit` JSON NOT NULL COMMENT 'Referred benefits (discount)',
    `status` ENUM('pending', 'completed', 'expired') NOT NULL DEFAULT 'pending' COMMENT 'Referral status',
    `completed_at` TIMESTAMP NULL COMMENT 'Completion date',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_referrer` (`referrer_type`, `referrer_id`),
    INDEX `idx_referred` (`referred_type`, `referred_id`),
    INDEX `idx_code` (`code`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Referral system [OPTIONAL]';

-- ============================================================================
-- Tabla: billing_data [CORE - Polymorphic Relationship]
-- Descripción: Billing/tax data for electronic invoicing
-- ============================================================================
CREATE TABLE `billing_data` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship
    `billable_type` VARCHAR(255) NOT NULL COMMENT 'Billable polymorphic model class',
    `billable_id` BIGINT UNSIGNED NOT NULL COMMENT 'Billable polymorphic model ID',
    
    `country` ENUM('MX', 'CO') NOT NULL COMMENT 'Country',
    `tax_id` VARCHAR(50) NOT NULL COMMENT 'RFC (MX) or NIT (CO)',
    `legal_name` VARCHAR(255) NOT NULL COMMENT 'Legal name',
    `tax_regime` VARCHAR(100) NULL COMMENT 'Tax regime (MX only)',
    `postal_code` VARCHAR(10) NULL COMMENT 'Postal code (MX only)',
    `cfdi_use` VARCHAR(10) NULL COMMENT 'CFDI use (MX only)',
    `person_type` ENUM('natural', 'legal') NULL COMMENT 'Person type (CO only)',
    `address` TEXT NULL COMMENT 'Address (CO only)',
    `city` VARCHAR(100) NULL COMMENT 'City (CO only)',
    `state` VARCHAR(100) NULL COMMENT 'State/Department (CO only)',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uk_billable` (`billable_type`, `billable_id`),
    INDEX `idx_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Billing/tax data for subscribers';

-- ============================================================================
-- Tabla:  invoices [OPTIONAL MODULE - Polymorphic Relationship]
-- Descripción: Electronic invoice requests and records
-- NOTE: Only created if 'invoicing' feature is enabled in package config
-- ============================================================================
CREATE TABLE `invoices` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship
    `invoiceable_type` VARCHAR(255) NOT NULL COMMENT 'Invoiceable polymorphic model class',
    `invoiceable_id` BIGINT UNSIGNED NOT NULL COMMENT 'Invoiceable polymorphic model ID',
    
    `payment_id` BIGINT UNSIGNED NOT NULL COMMENT 'Associated payment',
    `file_url` VARCHAR(500) NULL COMMENT 'PDF file path',
    `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Request date',
    `sent_at` TIMESTAMP NULL COMMENT 'Sent date',
    `status` ENUM('requested', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'requested' COMMENT 'Invoice status',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_invoices_payment` (`payment_id`) REFERENCES `payments`(`id`) ON DELETE RESTRICT,
    
    INDEX `idx_invoiceable` (`invoiceable_type`, `invoiceable_id`),
    INDEX `idx_payment_id` (`payment_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Electronic invoices [OPTIONAL]';

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
-- Tabla:  notifications [CORE - Polymorphic Relationship]
-- Descripción: Notification log (20+ types)
-- ============================================================================
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship
    `notifiable_type` VARCHAR(255) NOT NULL COMMENT 'Notifiable polymorphic model class',
    `notifiable_id` BIGINT UNSIGNED NOT NULL COMMENT 'Notifiable polymorphic model ID',
    
    `type` VARCHAR(100) NOT NULL COMMENT 'Notification type (20+ types)',
    `sent_at` TIMESTAMP NULL COMMENT 'Send date',
    `status` ENUM('pending', 'sent', 'failed', 'bounced') NOT NULL DEFAULT 'pending' COMMENT 'Send status',
    `metadata` JSON NULL COMMENT 'Additional data',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_notifiable` (`notifiable_type`, `notifiable_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_sent_at` (`sent_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notifications log';

-- ============================================================================
-- Tabla: audit_logs [CORE - Polymorphic Relationship]
-- Descripción: Audit log for critical actions
-- ============================================================================
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Polymorphic Relationship (nullable for system actions)
    `auditable_type` VARCHAR(255) NULL COMMENT 'Auditable polymorphic model class (NULL for system)',
    `auditable_id` BIGINT UNSIGNED NULL COMMENT 'Auditable polymorphic model ID (NULL for system)',
    
    `action` VARCHAR(100) NOT NULL COMMENT 'Action performed',
    `entity` VARCHAR(100) NOT NULL COMMENT 'Affected entity',
    `entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'Record ID',
    `before` JSON NULL COMMENT 'State before',
    `after` JSON NULL COMMENT 'State after',
    `ip` VARCHAR(45) NULL COMMENT 'Origin IP',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_auditable` (`auditable_type`, `auditable_id`),
    INDEX `idx_entity` (`entity`, `entity_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Audit logs';

-- ============================================================================
-- Additional composite indexes for optimization
-- ============================================================================

-- Daily renewal queries
CREATE INDEX idx_subscriptions_renewal_query 
ON subscriptions(next_billing_date, status, mit_enabled);

-- Pending 3DS payments queries
CREATE INDEX idx_payments_3ds_pending_query 
ON payments(requires_3ds, three_ds_status, authentication_required_notified_at) 
WHERE requires_3ds = TRUE AND three_ds_status = 'pending';

-- Current token period queries
CREATE INDEX idx_tokens_current_period 
ON tokens_usage(subscriber_type, subscriber_id, period_end DESC);

-- Active grace periods queries
CREATE INDEX idx_grace_periods_active 
ON grace_periods(ends_at, subscription_id) 
WHERE ends_at >= CURDATE();

-- ============================================================================
-- Sample data (OPTIONAL - development only)
-- ============================================================================

-- Sample plans
INSERT INTO `plans` (`name`, `description`, `tokens_monthly`, `periodicity`, `price_mxn`, `price_cop`, `trial_days`, `active`) VALUES
('Starter Plan', 'Basic plan with 5,000 tokens monthly', 5000, 'monthly', 299.00, 50000.00, 14, TRUE),
('Professional Plan', 'Professional plan with 10,000 tokens monthly', 10000, 'monthly', 499.00, 80000.00, 14, TRUE),
('Enterprise Plan', 'Enterprise plan with 20,000 tokens monthly', 20000, 'monthly', 899.00, 150000.00, 14, TRUE);

-- ============================================================================
-- Triggers for audit (OPTIONAL)
-- ============================================================================

DELIMITER $$

-- Trigger to audit subscription changes
CREATE TRIGGER trg_subscriptions_audit_update
AFTER UPDATE ON subscriptions
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status OR OLD.plan_id != NEW.plan_id THEN
        INSERT INTO audit_logs (auditable_type, auditable_id, action, entity, entity_id, `before`, `after`, ip)
        VALUES (
            NEW.subscriber_type,
            NEW.subscriber_id,
            'update',
            'subscription',
            NEW.id,
            JSON_OBJECT('status', OLD.status, 'plan_id', OLD.plan_id),
            JSON_OBJECT('status', NEW.status, 'plan_id', NEW.plan_id),
            NULL
        );
    END IF;
END$$

-- Trigger to audit payment changes
CREATE TRIGGER trg_payments_audit_update
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status OR OLD.three_ds_status != NEW.three_ds_status THEN
        INSERT INTO audit_logs (auditable_type, auditable_id, action, entity, entity_id, `before`, `after`, ip)
        SELECT 
            s.subscriber_type,
            s.subscriber_id,
            'update',
            'payment',
            NEW.id,
            JSON_OBJECT('status', OLD.status, 'three_ds_status', OLD.three_ds_status),
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
-- END OF SCRIPT
-- ============================================================================

-- NOTES:
-- 1. Execute this script on a clean database
-- 2. For production, adjust sample data as needed
-- 3. Audit triggers are optional but recommended
-- 4. Composite indexes improve performance of frequent queries
-- 5. 3DS fields (requires_3ds, three_ds_*, mit_enabled) are critical for payment flow
-- 6. Soft delete enabled only on subscriptions
-- 7. All relationships use POLYMORPHIC pattern for maximum flexibility
-- 8. The package does NOT create a users table - host application provides subscribable models
-- 9. Tables marked [OPTIONAL] are only created when corresponding feature is enabled
-- 10. Tables marked [CORE] are always created

-- VERSION: 2.0
-- CHANGES:
-- - ✅ Removed users table - package uses polymorphic relationships
-- - ✅ All foreign keys to users converted to polymorphic (subscriber_type/subscriber_id)
-- - ✅ Renamed user_coupons to subscriber_coupons
-- - ✅ Added billable_type/billable_id to billing_data
-- - ✅ Added referrer_type/referrer_id and referred_type/referred_id to referrals
-- - ✅ Added notifiable_type/notifiable_id to notifications
-- - ✅ Added invoiceable_type/invoiceable_id to invoices
-- - ✅ Added auditable_type/auditable_id to audit_logs
-- - ✅ Marked optional modules: tokens_usage, referrals, invoices
-- - ✅ Marked core modules: subscriptions, payments, coupons, subscriber_coupons
-- - ✅ Updated all indexes for polymorphic relationships
-- - ✅ Updated all triggers to use polymorphic fields
-- - ✅ Generalized sample data and comments