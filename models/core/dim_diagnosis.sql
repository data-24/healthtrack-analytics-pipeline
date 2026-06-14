{{
    config(
        materialized='table',
        tags=['core', 'dimension', 'snowflake_schema']
    )
}}

-- ════════════════════════════════════════════════
-- Dimension: diagnosis  (Snowflake Schema)
-- Normalised: links to dim_icd_category via FK.
-- Reduces redundancy when category is shared 
-- across thousands of diagnosis codes.
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ ref('stg_diagnoses') }}
),

categories AS (
    SELECT * FROM {{ ref('dim_icd_category') }}
),

dim_with_attributes AS (
    SELECT
        -- ── Surrogate key ──
        {{ generate_surrogate_key(['s.diagnosis_id']) }}  AS diagnosis_sk,
        
        -- ── Natural key ──
        s.diagnosis_id,
        
        -- ── Diagnosis attributes ──
        s.icd10_code,
        s.diagnosis_desc,
        s.severity,
        
        -- ── Foreign key to sub-dimension (snowflake!) ──
        c.icd_category_sk,
        
        -- ── Audit ──
        CURRENT_TIMESTAMP()                                AS dim_loaded_at
    FROM source s
    LEFT JOIN categories c
        ON s.diagnosis_category = c.category_name
)

SELECT * FROM dim_with_attributes