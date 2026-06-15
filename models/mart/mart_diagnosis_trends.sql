{{
    config(
        materialized='table',
        tags=['marts', 'diagnosis']
    )
}}

-- ════════════════════════════════════════════════
-- Mart: Diagnosis Trends
-- Grain: one row per diagnosis category × month
-- Consumed by: Power BI clinical trends dashboard
-- ════════════════════════════════════════════════

WITH facts AS (
    SELECT * FROM {{ ref('fct_admissions') }}
),

diagnoses AS (
    SELECT * FROM {{ ref('dim_diagnosis') }}
),

categories AS (
    SELECT * FROM {{ ref('dim_icd_category') }}
),

aggregated AS (
    SELECT
        -- ── Dimensions (grouping keys via snowflake schema) ──
        c.category_name,
        c.care_domain,
        
        -- ── Time dimension ──
        DATE_TRUNC('month', f.admit_date)        AS admit_month,
        EXTRACT(YEAR FROM f.admit_date)          AS admit_year,
        EXTRACT(QUARTER FROM f.admit_date)       AS admit_quarter,
        
        -- ── MEASURES ──
        COUNT(*)                                  AS total_admissions,
        COUNT(DISTINCT f.patient_sk)              AS unique_patients,
        COUNT(DISTINCT f.hospital_sk)             AS hospitals_treating,
        SUM(f.total_cost)                         AS total_revenue,
        ROUND(AVG(f.length_of_stay), 2)           AS avg_los,
        ROUND(AVG(f.total_cost), 2)               AS avg_cost,
        
        -- ── Severity breakdown ──
        SUM(CASE WHEN d.severity = 'Critical' THEN 1 ELSE 0 END) AS critical_count,
        SUM(CASE WHEN d.severity = 'High'     THEN 1 ELSE 0 END) AS high_count,
        SUM(CASE WHEN d.severity = 'Medium'   THEN 1 ELSE 0 END) AS medium_count,
        SUM(CASE WHEN d.severity = 'Low'      THEN 1 ELSE 0 END) AS low_count,
        
        -- ── Readmission tracking ──
        SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) AS readmission_count,
        ROUND(
            100.0 * SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS readmission_rate_pct,
        
        -- ── Audit ──
        CURRENT_TIMESTAMP()                       AS mart_loaded_at
    
    FROM facts f
    INNER JOIN diagnoses  d ON f.diagnosis_sk = d.diagnosis_sk
    INNER JOIN categories c ON d.icd_category_sk = c.icd_category_sk
    
    GROUP BY 
        c.category_name, c.care_domain,
        DATE_TRUNC('month', f.admit_date),
        EXTRACT(YEAR FROM f.admit_date),
        EXTRACT(QUARTER FROM f.admit_date)
)

SELECT * FROM aggregated
ORDER BY admit_month DESC, total_admissions DESC