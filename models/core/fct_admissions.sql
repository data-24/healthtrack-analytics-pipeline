{{
    config(
        materialized='incremental',
        unique_key='admission_id',
        incremental_strategy='merge',
        on_schema_change='fail',
        cluster_by=['admit_date', 'hospital_sk'],
        tags=['core', 'fact', 'incremental']
    )
}}

-- ════════════════════════════════════════════════
-- Fact: hospital admissions
-- Star schema center — joins to all 4 dimensions.
-- Incremental load — only NEW admissions processed.
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ ref('stg_admissions') }}
    
    {% if is_incremental() %}
        -- Only process admissions newer than what we already have
        WHERE load_ts > (SELECT MAX(fact_loaded_at) FROM {{ this }})
    {% endif %}
)
,

dimensions_joined AS (
    SELECT
        -- ── Natural key (kept for traceability) ──
        s.admission_id,
        
        -- ── Foreign keys to dimensions ──
        h.hospital_sk,
        p.patient_sk,
        d.diagnosis_sk,
        
        -- ── Degenerate dimension (lives in fact, not in a dim) ──
        s.admission_type,
        
        -- ── Date attributes ──
        s.admit_date,
        s.discharge_date,
        
        -- ── MEASURES (the numbers analysts aggregate) ──
        s.length_of_stay,
        s.total_cost,
        s.readmission_flag,
        
        -- ── Derived measure: cost per day ──
        CASE 
            WHEN s.length_of_stay > 0 
            THEN ROUND(s.total_cost / s.length_of_stay, 2)
            ELSE NULL 
        END AS cost_per_day,
        
        -- ── Audit ──
        s.load_ts                          AS source_load_ts,
        CURRENT_TIMESTAMP()                AS fact_loaded_at
    
    FROM source s
    
    -- ── SCD Type 1 join (simple equi-join) ──
    LEFT JOIN {{ ref('dim_hospital') }} h
        ON s.hospital_id = h.hospital_id
    
    -- ── SCD Type 2 join (temporal join!) ──
    LEFT JOIN {{ ref('dim_patient') }} p
        ON s.patient_id = p.patient_id
        AND p.is_current = TRUE

    
    -- ── SCD Type 1 join (simple equi-join) ──
    LEFT JOIN {{ ref('dim_diagnosis') }} d
        ON s.diagnosis_id = d.diagnosis_id
)

SELECT * FROM dimensions_joined