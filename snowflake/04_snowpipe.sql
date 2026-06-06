USE DATABASE HEALTHTRACK_DB;
USE SCHEMA RAW;
USE WAREHOUSE HEALTHTRACK_WH;

-- Snowpipe for PATIENTS
CREATE PIPE raw.pipe_patients
    AUTO_INGEST = FALSE
    AS
    COPY INTO RAW.PATIENTS (
        patient_id, first_name, last_name, date_of_birth,
        gender, blood_type, city, state, insurance_type,
        phone, updated_at, _file_name
    )
    FROM (
        SELECT 
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
            METADATA$FILENAME
        FROM @s3_healthtrack_stage/patients/
    )
    FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Snowpipe for HOSPITALS
CREATE PIPE raw.pipe_hospitals
    AUTO_INGEST = FALSE
    AS
    COPY INTO RAW.HOSPITALS (
        hospital_id, hospital_name, hospital_type,
        city, state, bed_count, is_teaching, updated_at, _file_name
    )
    FROM (
        SELECT 
            $1, $2, $3, $4, $5, $6, $7, $8,
            METADATA$FILENAME
        FROM @s3_healthtrack_stage/hospitals/
    )
    FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Snowpipe for DIAGNOSES
CREATE PIPE raw.pipe_diagnoses
    AUTO_INGEST = FALSE
    AS
    COPY INTO RAW.DIAGNOSES (
        diagnosis_id, icd10_code, diagnosis_desc,
        diagnosis_category, severity, updated_at, _file_name
    )
    FROM (
        SELECT 
            $1, $2, $3, $4, $5, $6,
            METADATA$FILENAME
        FROM @s3_healthtrack_stage/diagnoses/
    )
    FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Snowpipe for ADMISSIONS
CREATE PIPE raw.pipe_admissions
    AUTO_INGEST = FALSE
    AS
    COPY INTO RAW.ADMISSIONS (
        admission_id, patient_id, hospital_id, diagnosis_id,
        admission_type, admit_date, discharge_date,
        length_of_stay, total_cost, readmission_flag, updated_at, _file_name
    )
    FROM (
        SELECT 
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
            METADATA$FILENAME
        FROM @s3_healthtrack_stage/admissions/
    )
    FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Verify pipes created
SHOW PIPES IN SCHEMA RAW;



------------------
-- Load all 4 tables
ALTER PIPE raw.pipe_patients REFRESH;
ALTER PIPE raw.pipe_hospitals REFRESH;
ALTER PIPE raw.pipe_diagnoses REFRESH;
ALTER PIPE raw.pipe_admissions REFRESH;

-- Wait 30 seconds then check row counts
SELECT 'patients'   AS table_name, COUNT(*) AS row_count FROM RAW.PATIENTS
UNION ALL
SELECT 'hospitals'  AS table_name, COUNT(*) AS row_count FROM RAW.HOSPITALS
UNION ALL
SELECT 'diagnoses'  AS table_name, COUNT(*) AS row_count FROM RAW.DIAGNOSES
UNION ALL
SELECT 'admissions' AS table_name, COUNT(*) AS row_count FROM RAW.ADMISSIONS;