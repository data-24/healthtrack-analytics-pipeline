
{{
    config(
        materialized='view',
        tags=['staging']
    )
}}

-- ════════════════════════════════════════════════
-- Staging model: patients
-- Cleans raw.patients — casts types, renames cols,
-- deduplicates, adds surrogate key
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ source('raw', 'patients') }}
),

renamed AS (
    SELECT
        -- ── Natural key ──
        patient_id::VARCHAR              AS patient_id,
        
        -- ── Personal info ──
        first_name::VARCHAR              AS first_name,
        last_name::VARCHAR               AS last_name,
        date_of_birth::DATE              AS date_of_birth,
        gender::VARCHAR                  AS gender,
        blood_type::VARCHAR              AS blood_type,
        
        -- ── Location ──
        city::VARCHAR                    AS city,
        state::VARCHAR                   AS state,
        
        -- ── Insurance ──
        insurance_type::VARCHAR          AS insurance_type,
        phone::VARCHAR                   AS phone,
        
        -- ── Audit columns ──
        updated_at::DATE                 AS updated_at,
        _load_ts::TIMESTAMP_NTZ          AS load_ts,
        _file_name::VARCHAR              AS source_file
    FROM source
),

deduplicated AS (
    SELECT *
    FROM renamed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY patient_id 
        ORDER BY load_ts DESC
    ) = 1
)

SELECT * FROM deduplicated