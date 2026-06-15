{{
    config(
        materialized='table',
        tags=['core', 'dimension', 'scd_type_1']
    )
}}


-- ════════════════════════════════════════════════
-- Dimension: hospital  (SCD Type 1 — overwrite)
-- Hospitals attributes change rarely and analysts 
-- always want the CURRENT value, so we overwrite 
-- history instead of preserving it.
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ ref('stg_hospitals') }}
),

dim_with_attributes AS (
    SELECT
        -- ── Surrogate key (production-grade PK) ──
        {{ generate_surrogate_key(['hospital_id']) }}   AS hospital_sk,
        
        -- ── Natural key (kept for audit/joins) ──
        hospital_id,
        
        -- ── Hospital attributes ──
        hospital_name,
        hospital_type,
        city,
        state,
        bed_count,
        is_teaching,
        
        -- ── Derived attribute: hospital size category ──
        CASE 
            WHEN bed_count >= 500 THEN 'Large'
            WHEN bed_count >= 200 THEN 'Medium'
            ELSE 'Small'
        END                                              AS hospital_size_category,
        
        -- ── Audit columns ──
        CURRENT_TIMESTAMP()                              AS dim_loaded_at,
        load_ts                                          AS source_load_ts
    FROM source
)

SELECT * FROM dim_with_attributes