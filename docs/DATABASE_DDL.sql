-- ============================================================================
-- DATABASE DDL - Paquete Gestor de Suscripciones Laravel
-- Sistema Genérico de Gestión de Suscripciones
-- ============================================================================
-- Versión: 2.0
-- Fecha:  Enero 2026
-- Actualización: Relaciones Polimórficas (subscriber_type/subscriber_id)
-- ============================================================================

-- Configuración de base de datos
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- NOTA: La tabla User/Subscriber NO está incluida en este paquete
-- El paquete usa RELACIONES POLIMÓRFICAS para trabajar con cualquier modelo:
--   - App\Models\User
--   - App\Models\Company
--   - App\Models\Team
--   - App\Models\Organization
-- La aplicación host debe proporcionar un modelo "suscribible" con el trait HasSubscription
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
-- Tabla: subscriptions [CORE - Relación Polimórfica]
-- Descripción: Suscripciones vinculadas a cualquier modelo suscribible
-- ============================================================================
CREATE TABLE `subscriptions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica (puede ser User, Company, Team, etc.)
    `subscriber_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico (App\\Models\\User, App\\Models\\Company, etc.)',
    `subscriber_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico',
    
    `plan_id` BIGINT UNSIGNED NOT NULL COMMENT 'Plan actual',
    `status` ENUM('trial', 'active', 'past_due', 'grace_period', 'cancelled', 'blocked') NOT NULL DEFAULT 'trial' COMMENT 'Estado de la suscripción',
    `periodicity` ENUM('monthly', 'annual', 'annual_monthly_billing') NOT NULL COMMENT 'Periodicidad de facturación',
    `starts_at` DATE NOT NULL COMMENT 'Fecha de inicio',
    `ends_at` DATE NULL COMMENT 'Fecha de fin (NULL si está activa)',
    `next_billing_date` DATE NOT NULL COMMENT 'Próxima fecha de facturación',
    `card_token` VARCHAR(255) NULL COMMENT 'Tarjeta tokenizada de la pasarela de pagos',
    `manual_payment_reference` VARCHAR(255) NULL COMMENT 'Referencia de pago manual',
    `mit_enabled` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'MIT habilitado para pagos recurrentes',
    `first_payment_3ds_completed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Primer pago con 3DS exitoso',
    `pending_plan_id` BIGINT UNSIGNED NULL COMMENT 'Cambio de plan programado (downgrade)',
    `pending_plan_change_date` DATE NULL COMMENT 'Fecha de cambio programada',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL COMMENT 'Borrado suave',
    
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Suscripciones - Relación polimórfica a cualquier modelo suscribible';

-- ============================================================================
-- Tabla: tokens_usage [MÓDULO OPCIONAL - Relación Polimórfica]
-- Descripción: Seguimiento de consumo de tokens por período de facturación
-- NOTA: Solo se crea si la característica 'tokens' está habilitada en la configuración del paquete
-- ============================================================================
CREATE TABLE `tokens_usage` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica
    `subscriber_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico',
    `subscriber_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico',
    
    `subscription_id` BIGINT UNSIGNED NOT NULL COMMENT 'Suscripción',
    `period_start` DATE NOT NULL COMMENT 'Inicio del período',
    `period_end` DATE NOT NULL COMMENT 'Fin del período',
    `used` INT NOT NULL DEFAULT 0 COMMENT 'Tokens usados',
    `total` INT NOT NULL COMMENT 'Total de tokens para el período',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_tokens_subscription` (`subscription_id`) REFERENCES `subscriptions`(`id`) ON DELETE CASCADE,
    
    INDEX `idx_subscriber` (`subscriber_type`, `subscriber_id`),
    INDEX `idx_subscription_id` (`subscription_id`),
    INDEX `idx_period_start` (`period_start`),
    INDEX `idx_subscriber_period` (`subscriber_type`, `subscriber_id`, `period_start` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Seguimiento de consumo de tokens [OPCIONAL]';

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
-- Tabla: subscriber_coupons [CORE - Relación Polimórfica]
-- Descripción: Cupones aplicados por suscriptores (previene reutilización)
-- ============================================================================
CREATE TABLE `subscriber_coupons` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica
    `subscriber_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico',
    `subscriber_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico',
    
    `coupon_id` BIGINT UNSIGNED NOT NULL COMMENT 'Cupón',
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de aplicación',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_subscriber_coupons_coupon` (`coupon_id`) REFERENCES `coupons`(`id`) ON DELETE CASCADE,
    
    UNIQUE KEY `uk_subscriber_coupon` (`subscriber_type`, `subscriber_id`, `coupon_id`),
    INDEX `idx_subscriber` (`subscriber_type`, `subscriber_id`),
    INDEX `idx_coupon_id` (`coupon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cupones aplicados por suscriptores [CORE]';

-- ============================================================================
-- Tabla: referrals [MÓDULO OPCIONAL - Relación Polimórfica]
-- Descripción: Sistema de referidos con seguimiento de beneficios
-- NOTA: Solo se crea si la característica 'referrals' está habilitada en la configuración del paquete
-- ============================================================================
CREATE TABLE `referrals` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica para el Referidor
    `referrer_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico del referidor',
    `referrer_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico del referidor',
    
    -- Relación Polimórfica para el Referido
    `referred_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico del referido',
    `referred_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico del referido',
    
    `code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código único de referido',
    `referrer_benefit` JSON NOT NULL COMMENT 'Beneficios del referidor (descuento, tokens, crédito)',
    `referred_benefit` JSON NOT NULL COMMENT 'Beneficios del referido (descuento)',
    `status` ENUM('pending', 'completed', 'expired') NOT NULL DEFAULT 'pending' COMMENT 'Estado del referido',
    `completed_at` TIMESTAMP NULL COMMENT 'Fecha de completado',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_referrer` (`referrer_type`, `referrer_id`),
    INDEX `idx_referred` (`referred_type`, `referred_id`),
    INDEX `idx_code` (`code`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sistema de referidos [OPCIONAL]';

-- ============================================================================
-- Tabla: billing_data [CORE - Relación Polimórfica]
-- Descripción: Datos de facturación/impuestos para facturación electrónica
-- ============================================================================
CREATE TABLE `billing_data` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica
    `billable_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico facturable',
    `billable_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico facturable',
    
    `country` ENUM('MX', 'CO') NOT NULL COMMENT 'País',
    `tax_id` VARCHAR(50) NOT NULL COMMENT 'RFC (MX) o NIT (CO)',
    `legal_name` VARCHAR(255) NOT NULL COMMENT 'Nombre legal',
    `tax_regime` VARCHAR(100) NULL COMMENT 'Régimen fiscal (solo MX)',
    `postal_code` VARCHAR(10) NULL COMMENT 'Código postal (solo MX)',
    `cfdi_use` VARCHAR(10) NULL COMMENT 'Uso de CFDI (solo MX)',
    `person_type` ENUM('natural', 'legal') NULL COMMENT 'Tipo de persona (solo CO)',
    `address` TEXT NULL COMMENT 'Dirección (solo CO)',
    `city` VARCHAR(100) NULL COMMENT 'Ciudad (solo CO)',
    `state` VARCHAR(100) NULL COMMENT 'Estado/Departamento (solo CO)',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uk_billable` (`billable_type`, `billable_id`),
    INDEX `idx_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Datos de facturación/impuestos de suscriptores';

-- ============================================================================
-- Tabla: invoices [MÓDULO OPCIONAL - Relación Polimórfica]
-- Descripción: Solicitudes y registros de facturas electrónicas
-- NOTA: Solo se crea si la característica 'invoicing' está habilitada en la configuración del paquete
-- ============================================================================
CREATE TABLE `invoices` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica
    `invoiceable_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico facturable',
    `invoiceable_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico facturable',
    
    `payment_id` BIGINT UNSIGNED NOT NULL COMMENT 'Pago asociado',
    `file_url` VARCHAR(500) NULL COMMENT 'Ruta del archivo PDF',
    `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de solicitud',
    `sent_at` TIMESTAMP NULL COMMENT 'Fecha de envío',
    `status` ENUM('requested', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'requested' COMMENT 'Estado de la factura',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY `fk_invoices_payment` (`payment_id`) REFERENCES `payments`(`id`) ON DELETE RESTRICT,
    
    INDEX `idx_invoiceable` (`invoiceable_type`, `invoiceable_id`),
    INDEX `idx_payment_id` (`payment_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Facturas electrónicas [OPCIONAL]';

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
-- Tabla: notifications [CORE - Relación Polimórfica]
-- Descripción: Registro de notificaciones (20+ tipos)
-- ============================================================================
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica
    `notifiable_type` VARCHAR(255) NOT NULL COMMENT 'Clase del modelo polimórfico notificable',
    `notifiable_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del modelo polimórfico notificable',
    
    `type` VARCHAR(100) NOT NULL COMMENT 'Tipo de notificación (20+ tipos)',
    `sent_at` TIMESTAMP NULL COMMENT 'Fecha de envío',
    `status` ENUM('pending', 'sent', 'failed', 'bounced') NOT NULL DEFAULT 'pending' COMMENT 'Estado de envío',
    `metadata` JSON NULL COMMENT 'Datos adicionales',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_notifiable` (`notifiable_type`, `notifiable_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_sent_at` (`sent_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro de notificaciones';

-- ============================================================================
-- Tabla: audit_logs [CORE - Relación Polimórfica]
-- Descripción: Registro de auditoría para acciones críticas
-- ============================================================================
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Relación Polimórfica (nullable para acciones del sistema)
    `auditable_type` VARCHAR(255) NULL COMMENT 'Clase del modelo polimórfico auditable (NULL para sistema)',
    `auditable_id` BIGINT UNSIGNED NULL COMMENT 'ID del modelo polimórfico auditable (NULL para sistema)',
    
    `action` VARCHAR(100) NOT NULL COMMENT 'Acción realizada',
    `entity` VARCHAR(100) NOT NULL COMMENT 'Entidad afectada',
    `entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID del registro',
    `before` JSON NULL COMMENT 'Estado antes',
    `after` JSON NULL COMMENT 'Estado después',
    `ip` VARCHAR(45) NULL COMMENT 'IP de origen',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_auditable` (`auditable_type`, `auditable_id`),
    INDEX `idx_entity` (`entity`, `entity_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registros de auditoría';

-- ============================================================================
-- Índices compuestos adicionales para optimización
-- ============================================================================

-- Consultas de renovación diaria
CREATE INDEX idx_subscriptions_renewal_query 
ON subscriptions(next_billing_date, status, mit_enabled);

-- Consultas de pagos 3DS pendientes
CREATE INDEX idx_payments_3ds_pending_query 
ON payments(requires_3ds, three_ds_status, authentication_required_notified_at) 
WHERE requires_3ds = TRUE AND three_ds_status = 'pending';

-- Consultas de período actual de tokens
CREATE INDEX idx_tokens_current_period 
ON tokens_usage(subscriber_type, subscriber_id, period_end DESC);

-- Consultas de períodos de gracia activos
CREATE INDEX idx_grace_periods_active 
ON grace_periods(ends_at, subscription_id) 
WHERE ends_at >= CURDATE();

-- ============================================================================
-- Datos de ejemplo (OPCIONAL - solo desarrollo)
-- ============================================================================

-- Planes de ejemplo
INSERT INTO `plans` (`name`, `description`, `tokens_monthly`, `periodicity`, `price_mxn`, `price_cop`, `trial_days`, `active`) VALUES
('Starter Plan', 'Plan básico con 5,000 tokens mensuales', 5000, 'monthly', 299.00, 50000.00, 14, TRUE),
('Professional Plan', 'Plan profesional con 10,000 tokens mensuales', 10000, 'monthly', 499.00, 80000.00, 14, TRUE),
('Enterprise Plan', 'Plan empresarial con 20,000 tokens mensuales', 20000, 'monthly', 899.00, 150000.00, 14, TRUE);

-- ============================================================================
-- Triggers para auditoría (OPCIONAL)
-- ============================================================================

DELIMITER $$

-- Trigger para auditar cambios en suscripciones
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

-- Trigger para auditar cambios en pagos
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
-- FIN DEL SCRIPT
-- ============================================================================

-- NOTAS:
-- 1. Ejecutar este script en una base de datos limpia
-- 2. Para producción, ajustar los datos de ejemplo según sea necesario
-- 3. Los triggers de auditoría son opcionales pero recomendados
-- 4. Los índices compuestos mejoran el rendimiento de consultas frecuentes
-- 5. Los campos 3DS (requires_3ds, three_ds_*, mit_enabled) son críticos para el flujo de pagos
-- 6. El borrado suave solo está habilitado en suscripciones
-- 7. Todas las relaciones usan patrón POLIMÓRFICO para máxima flexibilidad
-- 8. El paquete NO crea una tabla de usuarios - la aplicación host proporciona modelos suscribibles
-- 9. Las tablas marcadas [OPCIONAL] solo se crean cuando la característica correspondiente está habilitada
-- 10. Las tablas marcadas [CORE] siempre se crean

-- VERSIÓN: 2.0
-- CAMBIOS:
-- - ✅ Removida tabla users - el paquete usa relaciones polimórficas
-- - ✅ Todas las llaves foráneas a users convertidas a polimórficas (subscriber_type/subscriber_id)
-- - ✅ Renombrado user_coupons a subscriber_coupons
-- - ✅ Agregado billable_type/billable_id a billing_data
-- - ✅ Agregado referrer_type/referrer_id y referred_type/referred_id a referrals
-- - ✅ Agregado notifiable_type/notifiable_id a notifications
-- - ✅ Agregado invoiceable_type/invoiceable_id a invoices
-- - ✅ Agregado auditable_type/auditable_id a audit_logs
-- - ✅ Marcados módulos opcionales: tokens_usage, referrals, invoices
-- - ✅ Marcados módulos core: subscriptions, payments, coupons, subscriber_coupons
-- - ✅ Actualizados todos los índices para relaciones polimórficas
-- - ✅ Actualizados todos los triggers para usar campos polimórficos
-- - ✅ Generalizados datos de ejemplo y comentarios