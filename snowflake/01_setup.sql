-- ── DATABASE + SCHEMAS ──────────────────────────────
CREATE DATABASE IF NOT EXISTS HEALTHTRACK_DB;

USE DATABASE HEALTHTRACK_DB;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS CORE;
CREATE SCHEMA IF NOT EXISTS MARTS;
CREATE SCHEMA IF NOT EXISTS SNAPSHOTS;

-- ── VIRTUAL WAREHOUSE ───────────────────────────────
CREATE WAREHOUSE IF NOT EXISTS HEALTHTRACK_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Main warehouse for HealthTrack project';

-- ── ROLES ────────────────────────────────────────────
CREATE ROLE IF NOT EXISTS transformer;
CREATE ROLE IF NOT EXISTS reporter;

-- Grant transformer full access to transform data
GRANT USAGE  ON DATABASE HEALTHTRACK_DB        TO ROLE transformer;
GRANT USAGE  ON ALL SCHEMAS IN DATABASE HEALTHTRACK_DB TO ROLE transformer;
GRANT ALL    ON ALL SCHEMAS IN DATABASE HEALTHTRACK_DB TO ROLE transformer;
GRANT USAGE  ON WAREHOUSE HEALTHTRACK_WH       TO ROLE transformer;

-- Grant reporter read-only access to MARTS only
GRANT USAGE  ON DATABASE HEALTHTRACK_DB        TO ROLE reporter;
GRANT USAGE  ON SCHEMA HEALTHTRACK_DB.MARTS    TO ROLE reporter;
GRANT SELECT ON ALL TABLES IN SCHEMA HEALTHTRACK_DB.MARTS TO ROLE reporter;
GRANT USAGE  ON WAREHOUSE HEALTHTRACK_WH       TO ROLE reporter;

-- ── RAW TABLES ───────────────────────────────────────
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS RAW.PATIENTS (
    patient_id      VARCHAR,
    first_name      VARCHAR,
    last_name       VARCHAR,
    date_of_birth   DATE,
    gender          VARCHAR,
    blood_type      VARCHAR,
    city            VARCHAR,
    state           VARCHAR,
    insurance_type  VARCHAR,
    phone           VARCHAR,
    updated_at      DATE,
    _load_ts        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_name      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW.HOSPITALS (
    hospital_id     VARCHAR,
    hospital_name   VARCHAR,
    hospital_type   VARCHAR,
    city            VARCHAR,
    state           VARCHAR,
    bed_count       NUMBER,
    is_teaching     BOOLEAN,
    updated_at      DATE,
    _load_ts        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_name      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW.DIAGNOSES (
    diagnosis_id        VARCHAR,
    icd10_code          VARCHAR,
    diagnosis_desc      VARCHAR,
    diagnosis_category  VARCHAR,
    severity            VARCHAR,
    updated_at          DATE,
    _load_ts            TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_name          VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW.ADMISSIONS (
    admission_id        VARCHAR,
    patient_id          VARCHAR,
    hospital_id         VARCHAR,
    diagnosis_id        VARCHAR,
    admission_type      VARCHAR,
    admit_date          DATE,
    discharge_date      DATE,
    length_of_stay      NUMBER,
    total_cost          FLOAT,
    readmission_flag    BOOLEAN,
    updated_at          DATE,
    _load_ts            TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_name          VARCHAR
);

-- ── VERIFY ───────────────────────────────────────────
SHOW SCHEMAS IN DATABASE HEALTHTRACK_DB;
SHOW TABLES IN SCHEMA RAW;