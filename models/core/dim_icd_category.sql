{{
    config(
        materialized='table',
        tags=['core', 'dimension', 'sub_dimension']
    )
}}

-- ════════════════════════════════════════════════
-- Sub-dimension: ICD-10 categories
-- Shared across thousands of diagnosis codes.
-- Snowflake schema parent of dim_diagnosis.
-- ════════════════════════════════════════════════

WITH source AS (
    -- Get distinct categories from staging
    SELECT DISTINCT diagnosis_category
    FROM {{ ref('stg_diagnoses') }}
    WHERE diagnosis_category IS NOT NULL
),

dim_with_attributes AS (
    SELECT
        -- Surrogate key for the sub-dimension
        {{ generate_surrogate_key(['diagnosis_category']) }}  AS icd_category_sk,
        
        diagnosis_category                                     AS category_name,
        
        -- Derived attribute — group categories for analytics
        CASE
            WHEN diagnosis_category IN ('Cardiovascular', 'Respiratory') THEN 'Critical Care'
            WHEN diagnosis_category IN ('Mental Health', 'Neurological') THEN 'Specialized Care'
            WHEN diagnosis_category IN ('Endocrine', 'Renal', 'Gastrointestinal') THEN 'Chronic Care'
            ELSE 'General Care'
        END                                                    AS care_domain,
        
        CURRENT_TIMESTAMP()                                    AS dim_loaded_at
    FROM source
)

SELECT * FROM dim_with_attributes