{{
    config(
        materialized='incremental',
        unique_key='admission_id',
        incremental_strategy='merge',
        on_schema_change='fail',
        tags=['staging', 'incremental']
    )
}}

-- ════════════════════════════════════════════════
-- Staging model: admissions  (INCREMENTAL)
-- Loads only new admissions since last run.
-- Uses MERGE strategy via admission_id.
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ source('raw', 'admissions') }}
    
    {% if is_incremental() %}
        -- Only process rows newer than what we already have
        WHERE _LOAD_TS > (SELECT MAX(load_ts) FROM {{ this }})
    {% endif %}
),

renamed AS (
    SELECT
        admission_id::VARCHAR        AS admission_id,
        patient_id::VARCHAR          AS patient_id,
        hospital_id::VARCHAR         AS hospital_id,
        diagnosis_id::VARCHAR        AS diagnosis_id,
        admission_type::VARCHAR      AS admission_type,
        admit_date::DATE             AS admit_date,
        discharge_date::DATE         AS discharge_date,
        length_of_stay::NUMBER       AS length_of_stay,
        total_cost::FLOAT            AS total_cost,
        readmission_flag::BOOLEAN    AS readmission_flag,
        updated_at::DATE             AS updated_at,
        _load_ts::TIMESTAMP_NTZ      AS load_ts,
        _file_name::VARCHAR          AS source_file
    FROM source
),

deduplicated AS (
    SELECT *
    FROM renamed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY admission_id
        ORDER BY load_ts DESC
    ) = 1
)

SELECT * FROM deduplicated