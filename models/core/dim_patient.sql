{{
    config(
        materialized='table',
        tags=['core', 'dimension', 'scd_type_2']
    )
}}

-- ════════════════════════════════════════════════
-- Dimension: patient  (SCD Type 2)
-- Reads from snp_patients snapshot.
-- Includes ALL versions (current + historical).
-- Fact tables join using BETWEEN dbt_valid_from 
-- AND dbt_valid_to for temporally-correct history.
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ ref('snp_patients') }}
),

dim_with_attributes AS (
    SELECT
        -- ── Surrogate key (uses dbt_scd_id from snapshot) ──
        dbt_scd_id                              AS patient_sk,
        
        -- ── Natural key ──
        patient_id,
        
        -- ── Patient attributes ──
        first_name,
        last_name,
        date_of_birth,
        gender,
        blood_type,
        city,
        state,
        insurance_type,
        phone,
        
        -- ── SCD Type 2 validity columns ──
        dbt_valid_from                          AS valid_from,
        dbt_valid_to                            AS valid_to,
        
        -- ── Is this the current version? ──
        CASE 
            WHEN dbt_valid_to IS NULL THEN TRUE 
            ELSE FALSE 
        END                                      AS is_current,
        
        -- ── Derived attribute: age bucket ──
        CASE 
            WHEN DATEDIFF(year, date_of_birth, CURRENT_DATE()) < 18 THEN 'Under 18'
            WHEN DATEDIFF(year, date_of_birth, CURRENT_DATE()) < 35 THEN '18-34'
            WHEN DATEDIFF(year, date_of_birth, CURRENT_DATE()) < 50 THEN '35-49'
            WHEN DATEDIFF(year, date_of_birth, CURRENT_DATE()) < 65 THEN '50-64'
            ELSE '65+'
        END                                      AS age_bucket,
        
        -- ── Audit ──
        CURRENT_TIMESTAMP()                      AS dim_loaded_at
    FROM source
)

SELECT * FROM dim_with_attributes