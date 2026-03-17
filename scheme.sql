-- schema.sql
-- Run once against `my_database`.
-- Safe to re-run: CREATE statements use IF NOT EXISTS.
-- The ALTER TABLE is guarded with IF NOT EXISTS so it is safe on both
-- fresh databases and databases already created from the previous schema.

-- ── Tables ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(255)  NOT NULL UNIQUE,  -- stores the email address
    password   VARCHAR(255)  NOT NULL,          -- bcrypt hash, NEVER plaintext
    is_admin   TINYINT(1)    NOT NULL DEFAULT 0,
    created_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Adds is_admin to an existing users table; no-op if column already present.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS is_admin TINYINT(1) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS files (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(255)  NOT NULL,
    content     TEXT,
    access_code CHAR(6)       NOT NULL UNIQUE,
    owner_id    INT           NOT NULL,
    created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS uploaded_files (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    room_code   CHAR(6)       NOT NULL,
    file_name   VARCHAR(255)  NOT NULL,
    file_path   VARCHAR(512)  NOT NULL,
    file_size   INT UNSIGNED  NOT NULL DEFAULT 0,
    uploaded_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_code) REFERENCES files(access_code) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
