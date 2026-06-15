{{
    config(
        materialized='table',
        tags=['marts', 'hospital']
    )
}}

-- ════════════════════════════════════════════════
-- Mart: Hospital KPIs
-- Grain: one row per hospital × month
-- Consumed by: Power BI hospital performance dashboard
-- ════════════════════════════════════════════════

WITH facts AS (
    SELECT * FROM {{ ref('fct_admissions') }}
),

hospitals AS (
    SELECT * FROM {{ ref('dim_hospital') }}
),

aggregated AS (
    SELECT
        -- ── Dimensions (the grouping keys) ──
        h.hospital_id,
        h.hospital_name,
        h.hospital_type,
        h.hospital_size_category,
        h.state,
        
        -- ── Time dimension ──
        DATE_TRUNC('month', f.admit_date)        AS admit_month,
        EXTRACT(YEAR FROM f.admit_date)          AS admit_year,
        
        -- ── MEASURES (the aggregated business KPIs) ──
        COUNT(*)                                  AS total_admissions,
        COUNT(DISTINCT f.patient_sk)              AS unique_patients,
        SUM(f.total_cost)                         AS total_revenue,
        ROUND(AVG(f.length_of_stay), 2)           AS avg_los,
        ROUND(AVG(f.total_cost), 2)               AS avg_cost_per_admission,
        SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) AS readmission_count,
        ROUND(
            100.0 * SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) / COUNT(*),
            2
        )                                          AS readmission_rate_pct,
        
        -- ── Audit ──
        CURRENT_TIMESTAMP()                       AS mart_loaded_at
    
    FROM facts f
    INNER JOIN hospitals h ON f.hospital_sk = h.hospital_sk
    
    GROUP BY 
        h.hospital_id, h.hospital_name, h.hospital_type,
        h.hospital_size_category, h.state,
        DATE_TRUNC('month', f.admit_date),
        EXTRACT(YEAR FROM f.admit_date)
)

SELECT * FROM aggregated
ORDER BY admit_month DESC, total_admissions DESC