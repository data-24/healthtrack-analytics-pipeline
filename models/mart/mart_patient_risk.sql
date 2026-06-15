{{
    config(
        materialized='table',
        tags=['marts', 'patient', 'risk_scoring']
    )
}}

-- ════════════════════════════════════════════════
-- Mart: Patient Risk Scoring
-- Grain: one row per patient (CURRENT version only)
-- Risk = composite score based on admission history
-- Consumed by: clinical risk dashboards, care management
-- ════════════════════════════════════════════════

WITH facts AS (
    SELECT * FROM {{ ref('fct_admissions') }}
),

patients AS (
    -- Only CURRENT version of each patient (SCD2 filter)
    SELECT * FROM {{ ref('dim_patient') }}
    WHERE is_current = TRUE
),

diagnoses AS (
    SELECT * FROM {{ ref('dim_diagnosis') }}
),

patient_history AS (
    SELECT
        p.patient_id,
        p.patient_sk,
        p.first_name,
        p.last_name,
        p.age_bucket,
        p.gender,
        p.city,
        p.state,
        p.insurance_type,
        
        -- ── Admission history metrics ──
        COUNT(*)                                  AS total_admissions,
        COUNT(DISTINCT f.hospital_sk)             AS hospitals_visited,
        SUM(f.total_cost)                         AS lifetime_cost,
        ROUND(AVG(f.length_of_stay), 2)           AS avg_los,
        MAX(f.admit_date)                         AS last_admission_date,
        DATEDIFF(day, MAX(f.admit_date), CURRENT_DATE()) AS days_since_last_admit,
        
        -- ── Risk indicators ──
        SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) AS readmission_count,
        SUM(CASE WHEN d.severity = 'Critical' THEN 1 ELSE 0 END) AS critical_admissions,
        SUM(CASE WHEN d.severity IN ('Critical', 'High') THEN 1 ELSE 0 END) AS severe_admissions,
        SUM(CASE WHEN f.admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_admissions
    
    FROM facts f
    INNER JOIN patients  p ON f.patient_sk = p.patient_sk
    INNER JOIN diagnoses d ON f.diagnosis_sk = d.diagnosis_sk
    
    GROUP BY 
        p.patient_id, p.patient_sk, p.first_name, p.last_name,
        p.age_bucket, p.gender, p.city, p.state, p.insurance_type
),

risk_scored AS (
    SELECT
        *,
        
        -- ── Composite risk score (0-100 scale) ──
        ROUND(
            -- Frequency: 3 points per admission, capped at 30
            LEAST(total_admissions * 3, 30) +
            
            -- Readmissions: 5 points each, capped at 25
            LEAST(readmission_count * 5, 25) +
            
            -- Severity: 7 points per critical, capped at 21
            LEAST(critical_admissions * 7, 21) +
            
            -- Emergency: 4 points per emergency, capped at 16
            LEAST(emergency_admissions * 4, 16) +
            
            -- Age bonus
            CASE 
                WHEN age_bucket = '65+'   THEN 8
                WHEN age_bucket = '50-64' THEN 4
                ELSE 0
            END
        , 2) AS risk_score,
        
        CURRENT_TIMESTAMP() AS mart_loaded_at
    FROM patient_history
),

final AS (
    SELECT 
        *,
        -- ── Risk tier classification ──
        CASE
            WHEN risk_score >= 60 THEN 'High Risk'
            WHEN risk_score >= 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_tier
    FROM risk_scored
)

SELECT * FROM final
ORDER BY risk_score DESC