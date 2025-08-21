USE SWIFTRIDE;

-- =====================================================
-- SWIFTRIDE IAM SECURITY DATABASE - SQL SERVER
-- Identity and Access Management System
-- =====================================================

-- =====================================================
-- 1. USER MANAGEMENT TABLES
-- =====================================================
DROP TABLE IF EXISTS security_users

-- Core Users Table (All system users)
CREATE TABLE security_users (
    user_sk BIGINT IDENTITY(1,1) NOT NULL,     -- Surrogate Key
    user_id VARCHAR(50) NOT NULL UNIQUE,       -- Business Key (username/email)
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,       -- Hashed password (never store plain text)
    salt VARCHAR(100) NOT NULL,                -- Salt for password hashing
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),                         -- ADDED COMMA HERE
    
    -- User Status
    user_status VARCHAR(20) DEFAULT 'ACTIVE',
    account_type VARCHAR(20) DEFAULT 'DRIVER',
    email_verified BIT DEFAULT 0,
    phone_verified BIT DEFAULT 0,              -- ADDED COMMA HERE
    
    -- Security Fields
    failed_login_attempts INT DEFAULT 0,
    last_failed_login DATETIME2,
    account_locked_until DATETIME2,
    password_expires_at DATETIME2,
    must_change_password BIT DEFAULT 0,
    
    -- Multi-Factor Authentication
    mfa_enabled BIT DEFAULT 0,
    mfa_secret VARCHAR(100),                   -- TOTP secret
    backup_codes VARCHAR(500),                 -- Comma-separated backup codes
    
    -- Tracking
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50),
    last_login_at DATETIME2,
    last_password_change DATETIME2 DEFAULT GETDATE(),
    
    PRIMARY KEY (user_sk)
);
-- User Sessions Table (Active login sessions)
CREATE TABLE user_sessions (
    session_sk BIGINT IDENTITY(1,1) NOT NULL,
    session_id VARCHAR(128) NOT NULL UNIQUE,   -- JWT token ID or session token
    user_sk BIGINT NOT NULL,
    device_info VARCHAR(500),                  -- User agent, device type
    ip_address VARCHAR(45),                    -- IPv4 or IPv6
    location VARCHAR(100),                     -- City, Country from IP
    
    -- Session Details
    login_timestamp DATETIME2 DEFAULT GETDATE(),
    last_activity DATETIME2 DEFAULT GETDATE(),
    expires_at DATETIME2,
    is_active BIT DEFAULT 1,
    logout_timestamp DATETIME2,
    session_type VARCHAR(20) DEFAULT 'WEB',    -- WEB, MOBILE, API
    
    PRIMARY KEY (session_sk),
    FOREIGN KEY (user_sk) REFERENCES security_users(user_sk)
);

-- =====================================================
-- 2. ROLE-BASED ACCESS CONTROL (RBAC)
-- =====================================================

-- Roles Definition
CREATE TABLE security_roles (
    role_sk BIGINT IDENTITY(1,1) NOT NULL,
    role_code VARCHAR(50) NOT NULL UNIQUE,     -- SUPER_ADMIN, CITY_MANAGER, etc.
    role_name VARCHAR(100) NOT NULL,
    role_description VARCHAR(500),
    is_system_role BIT DEFAULT 0,              -- Cannot be deleted
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50),
    PRIMARY KEY (role_sk)
);

-- Permissions/Privileges Definition
CREATE TABLE security_permissions (
    permission_sk BIGINT IDENTITY(1,1) NOT NULL,
    permission_code VARCHAR(100) NOT NULL UNIQUE,  -- trips.read, drivers.write, etc.
    permission_name VARCHAR(150) NOT NULL,
    permission_description VARCHAR(500),
    resource_type VARCHAR(50),                 -- TABLE, VIEW, FUNCTION, API_ENDPOINT
    resource_name VARCHAR(100),               -- fact_trips, dim_drivers, etc.
    action_type VARCHAR(20),                  -- READ, WRITE, DELETE, EXECUTE
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    PRIMARY KEY (permission_sk)
);

-- Role-Permission Mapping (Many-to-Many)
CREATE TABLE role_permissions (
    role_permission_sk BIGINT IDENTITY(1,1) NOT NULL,
    role_sk BIGINT NOT NULL,
    permission_sk BIGINT NOT NULL,
    granted_by VARCHAR(50),
    granted_at DATETIME2 DEFAULT GETDATE(),
    is_active BIT DEFAULT 1,
    PRIMARY KEY (role_permission_sk),
    FOREIGN KEY (role_sk) REFERENCES security_roles(role_sk),
    FOREIGN KEY (permission_sk) REFERENCES security_permissions(permission_sk),
    UNIQUE (role_sk, permission_sk)
);

-- User-Role Assignment (Many-to-Many)
CREATE TABLE user_roles (
    user_role_sk BIGINT IDENTITY(1,1) NOT NULL,
    user_sk BIGINT NOT NULL,
    role_sk BIGINT NOT NULL,
    assigned_by VARCHAR(50),
    assigned_at DATETIME2 DEFAULT GETDATE(),
    expires_at DATETIME2,                     -- Optional role expiration
    is_active BIT DEFAULT 1,
    PRIMARY KEY (user_role_sk),
    FOREIGN KEY (user_sk) REFERENCES security_users(user_sk),
    FOREIGN KEY (role_sk) REFERENCES security_roles(role_sk)
);

-- =====================================================
-- 3. ATTRIBUTE-BASED ACCESS CONTROL (ABAC)
-- =====================================================

-- User Attributes (for fine-grained access control)
CREATE TABLE user_attributes (
    user_attribute_sk BIGINT IDENTITY(1,1) NOT NULL,
    user_sk BIGINT NOT NULL,
    attribute_name VARCHAR(50) NOT NULL,      -- city_code, department, clearance_level
    attribute_value VARCHAR(200) NOT NULL,   -- NYC, finance, confidential
    attribute_type VARCHAR(20) DEFAULT 'STRING', -- STRING, NUMBER, BOOLEAN, DATE
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    PRIMARY KEY (user_attribute_sk),
    FOREIGN KEY (user_sk) REFERENCES security_users(user_sk)
);

-- Resource Access Policies (Dynamic access rules)
CREATE TABLE access_policies (
    policy_sk BIGINT IDENTITY(1,1) NOT NULL,
    policy_name VARCHAR(100) NOT NULL,
    policy_description VARCHAR(500),
    resource_pattern VARCHAR(200),            -- fact_trips, dim_drivers.city_code=NYC
    policy_condition VARCHAR(1000),           -- JSON or SQL-like condition
    action_type VARCHAR(20),                  -- READ, WRITE, DELETE
    is_active BIT DEFAULT 1,
    priority_order INT DEFAULT 100,           -- Lower number = higher priority
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50),
    PRIMARY KEY (policy_sk)
);

-- =====================================================
-- 4. AUDIT AND MONITORING
-- =====================================================

-- Security Audit Log
CREATE TABLE security_audit_log (
    audit_sk BIGINT IDENTITY(1,1) NOT NULL,
    user_sk BIGINT,
    session_id VARCHAR(128),
    event_type VARCHAR(50),                   -- LOGIN, LOGOUT, ACCESS_DENIED, PERMISSION_CHANGE
    event_description VARCHAR(1000),
    resource_accessed VARCHAR(200),          -- Table, view, or API endpoint accessed
    action_attempted VARCHAR(50),            -- SELECT, INSERT, UPDATE, DELETE
    success BIT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    event_timestamp DATETIME2 DEFAULT GETDATE(),
    additional_data NVARCHAR(MAX),           -- JSON for extra context
    risk_score INT DEFAULT 0,                -- 0-100 risk assessment
    PRIMARY KEY (audit_sk),
    FOREIGN KEY (user_sk) REFERENCES security_users(user_sk)
);

-- Failed Login Attempts (Security monitoring)
CREATE TABLE failed_login_attempts (
    attempt_sk BIGINT IDENTITY(1,1) NOT NULL,
    username_attempted VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    failure_reason VARCHAR(100),             -- INVALID_PASSWORD, ACCOUNT_LOCKED, etc.
    attempt_timestamp DATETIME2 DEFAULT GETDATE(),
    PRIMARY KEY (attempt_sk)
);

-- =====================================================
-- 5. DATA SECURITY & ENCRYPTION
-- =====================================================

-- Encryption Keys Management
CREATE TABLE encryption_keys (
    key_sk BIGINT IDENTITY(1,1) NOT NULL,
    key_id VARCHAR(50) NOT NULL UNIQUE,
    key_type VARCHAR(20),                    -- AES256, RSA2048, etc.
    key_purpose VARCHAR(50),                 -- DATABASE, API, FILE_STORAGE
    key_status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, REVOKED
    created_at DATETIME2 DEFAULT GETDATE(),
    expires_at DATETIME2,
    rotated_at DATETIME2,
    created_by VARCHAR(50),
    PRIMARY KEY (key_sk)
);

-- Data Classification (for sensitive data handling)
CREATE TABLE data_classification (
    classification_sk BIGINT IDENTITY(1,1) NOT NULL,
    table_name VARCHAR(128),
    column_name VARCHAR(128),
    classification_level VARCHAR(20),        -- PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED
    data_type VARCHAR(50),                   -- PII, FINANCIAL, HEALTH, etc.
    encryption_required BIT DEFAULT 0,
    masking_rule VARCHAR(200),               -- How to mask data for non-privileged users
    retention_period_days INT,               -- Data retention policy
    created_at DATETIME2 DEFAULT GETDATE(),
    PRIMARY KEY (classification_sk)
);

-- =====================================================
-- 6. INITIAL SECURITY DATA
-- =====================================================

-- Insert System Roles
INSERT INTO security_roles (role_code, role_name, role_description, is_system_role) VALUES
('SUPER_ADMIN', 'Super Administrator', 'Full system access', 1),
('DB_ADMIN', 'Database Administrator', 'Database management access', 1),
('DATA_ANALYST', 'Data Analyst', 'Read access to analytical data', 1),
('CITY_MANAGER', 'City Operations Manager', 'City-specific operational access', 1),
('DRIVER_SUPPORT', 'Driver Support Agent', 'Driver assistance and basic data access', 1),
('RIDER_SUPPORT', 'Rider Support Agent', 'Rider assistance and basic data access', 1),
('FINANCIAL_ANALYST', 'Financial Analyst', 'Financial data and reporting access', 1),
('API_USER', 'API User', 'Programmatic API access', 1);

-- Insert Core Permissions
INSERT INTO security_permissions (permission_code, permission_name, resource_type, resource_name, action_type) VALUES
-- Data Warehouse Permissions
('fact_trips.read', 'Read Trip Data', 'TABLE', 'fact_trips', 'READ'),
('fact_trips.write', 'Write Trip Data', 'TABLE', 'fact_trips', 'WRITE'),
('dim_drivers.read', 'Read Driver Data', 'TABLE', 'dim_drivers', 'READ'),
('dim_drivers.write', 'Write Driver Data', 'TABLE', 'dim_drivers', 'WRITE'),
('dim_riders.read', 'Read Rider Data', 'TABLE', 'dim_riders', 'READ'),
('fact_payments.read', 'Read Payment Data', 'TABLE', 'fact_payments', 'READ'),
('analytics.execute', 'Execute Analytics Queries', 'VIEW', 'v_trip_summary', 'READ'),

-- System Permissions
('users.manage', 'Manage Users', 'TABLE', 'security_users', 'WRITE'),
('roles.manage', 'Manage Roles', 'TABLE', 'security_roles', 'WRITE'),
('audit.read', 'Read Audit Logs', 'TABLE', 'security_audit_log', 'READ'),
('system.admin', 'System Administration', 'SYSTEM', '*', 'EXECUTE');

-- Assign Permissions to Roles
INSERT INTO role_permissions (role_sk, permission_sk, granted_by) 
SELECT r.role_sk, p.permission_sk, 'SYSTEM'
FROM security_roles r, security_permissions p
WHERE r.role_code = 'SUPER_ADMIN'; -- Super admin gets all permissions

INSERT INTO role_permissions (role_sk, permission_sk, granted_by)
SELECT r.role_sk, p.permission_sk, 'SYSTEM'
FROM security_roles r, security_permissions p
WHERE r.role_code = 'DATA_ANALYST' 
  AND p.action_type = 'READ' 
  AND p.resource_type IN ('TABLE', 'VIEW');

-- =====================================================
-- 7. SECURITY INDEXES
-- =====================================================

CREATE NONCLUSTERED INDEX IX_security_users_email ON security_users(email);
CREATE NONCLUSTERED INDEX IX_security_users_status ON security_users(user_status);
CREATE NONCLUSTERED INDEX IX_user_sessions_active ON user_sessions(is_active, last_activity);
CREATE NONCLUSTERED INDEX IX_audit_log_timestamp ON security_audit_log(event_timestamp);
CREATE NONCLUSTERED INDEX IX_audit_log_user_event ON security_audit_log(user_sk, event_type);
CREATE NONCLUSTERED INDEX IX_failed_logins_ip ON failed_login_attempts(ip_address, attempt_timestamp);

-- =====================================================
-- 8. SECURITY VIEWS AND FUNCTIONS
-- =====================================================

-- Active Users View
CREATE VIEW v_active_users AS
SELECT 
    u.user_id,
    u.email,
    u.first_name + ' ' + u.last_name AS full_name,
    u.account_type,
    u.user_status,
    u.last_login_at,
    u.email_verified,
    u.mfa_enabled
FROM security_users u
WHERE u.user_status = 'ACTIVE';

-- User Permissions View (Effective permissions per user)
GO
CREATE VIEW  v_user_permissions AS
SELECT DISTINCT
    u.user_id,
    u.email,
    r.role_name,
    p.permission_code,
    p.permission_name,
    p.resource_name,
    p.action_type
FROM security_users u
INNER JOIN user_roles ur ON u.user_sk = ur.user_sk AND ur.is_active = 1
INNER JOIN security_roles r ON ur.role_sk = r.role_sk AND r.is_active = 1
INNER JOIN role_permissions rp ON r.role_sk = rp.role_sk AND rp.is_active = 1
INNER JOIN security_permissions p ON rp.permission_sk = p.permission_sk AND p.is_active = 1
WHERE u.user_status = 'ACTIVE';
GO
-- Audit Summary View
GO
CREATE VIEW v_security_audit_summary AS
SELECT 
    u.user_id,
    u.email,
    a.event_type,
    COUNT(*) AS event_count,
    MAX(a.event_timestamp) AS last_event,
    SUM(CASE WHEN a.success = 0 THEN 1 ELSE 0 END) AS failed_attempts
FROM security_audit_log a
INNER JOIN security_users u ON a.user_sk = u.user_sk
WHERE a.event_timestamp >= DATEADD(DAY, -30, GETDATE())
GROUP BY u.user_id, u.email, a.event_type;
GO
-- =====================================================
-- 9. STORED PROCEDURES FOR SECURITY OPERATIONS
-- =====================================================

-- User Authentication Procedure
GO
CREATE PROCEDURE sp_auth_user
    @username VARCHAR(255),
    @password VARCHAR(255),
    @ip_address VARCHAR(45),
    @user_agent VARCHAR(500)
AS
BEGIN
    DECLARE @user_sk BIGINT, @stored_hash VARCHAR(255), @salt VARCHAR(100);
    DECLARE @failed_attempts INT, @account_locked_until DATETIME2;
    DECLARE @is_authenticated BIT = 0;

    -- Check if user exists and get security info
    SELECT @user_sk = user_sk, @stored_hash = password_hash, @salt = salt,
           @failed_attempts = failed_login_attempts, @account_locked_until = account_locked_until
    FROM security_users 
    WHERE user_id = @username OR email = @username;

    IF @user_sk IS NULL
    BEGIN
        -- Log failed attempt
        INSERT INTO failed_login_attempts (username_attempted, ip_address, user_agent, failure_reason)
        VALUES (@username, @ip_address, @user_agent, 'USER_NOT_FOUND');
        
        RETURN 0; -- Authentication failed
    END

    -- Check if account is locked
    IF @account_locked_until IS NOT NULL AND @account_locked_until > GETDATE()
    BEGIN
        INSERT INTO security_audit_log (user_sk, event_type, event_description, success, ip_address, user_agent)
        VALUES (@user_sk, 'LOGIN_ATTEMPT', 'Account locked', 0, @ip_address, @user_agent);
        
        RETURN -1; -- Account locked
    END

    -- Verify password (in real implementation, use proper hashing like bcrypt)
    -- This is simplified - use proper password verification in production
    IF @stored_hash = HASHBYTES('SHA2_256', @password + @salt)
    BEGIN
        SET @is_authenticated = 1;
        
        -- Reset failed attempts
        UPDATE security_users 
        SET failed_login_attempts = 0, last_login_at = GETDATE()
        WHERE user_sk = @user_sk;
        
        -- Log successful login
        INSERT INTO security_audit_log (user_sk, event_type, event_description, success, ip_address, user_agent)
        VALUES (@user_sk, 'LOGIN_SUCCESS', 'User authenticated', 1, @ip_address, @user_agent);
    END
    ELSE
    BEGIN
        -- Increment failed attempts
        UPDATE security_users 
        SET failed_login_attempts = failed_login_attempts + 1,
            last_failed_login = GETDATE(),
            account_locked_until = CASE 
                WHEN failed_login_attempts + 1 >= 5 
                THEN DATEADD(MINUTE, 30, GETDATE()) 
                ELSE NULL END
        WHERE user_sk = @user_sk;
        
        -- Log failed attempt
        INSERT INTO security_audit_log (user_sk, event_type, event_description, success, ip_address, user_agent)
        VALUES (@user_sk, 'LOGIN_FAILED', 'Invalid password', 0, @ip_address, @user_agent);
    END

    RETURN @is_authenticated;
END;
GO

-- Check User Permission Procedure
CREATE PROCEDURE sp_verify_user_permission
    @user_id VARCHAR(50),
    @permission_code VARCHAR(100)
AS
BEGIN
    DECLARE @has_permission BIT = 0;
    
    SELECT @has_permission = 1
    FROM v_user_permissions
    WHERE user_id = @user_id AND permission_code = @permission_code;
    
    RETURN ISNULL(@has_permission, 0);
END;
GO

