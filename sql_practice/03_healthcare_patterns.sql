-- ════════════════════════════════════════════════════════════
-- HEALTHCARE ANALYTICS PATTERNS
-- Practice queries for HealthTrack project
-- ════════════════════════════════════════════════════════════
--
-- Real-world SQL patterns used in healthcare data engineering.
-- These are the queries you'd write in a hospital analytics team.
--
-- Run these against your HEALTHTRACK_DB.STAGING schema.
-- ════════════════════════════════════════════════════════════

USE DATABASE HEALTHTRACK_DB;
USE SCHEMA STAGING;


-- ───────────────────────────────────────────────────────
-- PATTERN 1: 30-DAY READMISSION DETECTION
-- ───────────────────────────────────────────────────────
-- Definition: Patient admitted again within 30 days of discharge
-- Healthcare KPI: Hospitals are penalized for high readmission rates

SELECT 
    f1.patient_sk,
    f1.admission_id    AS first_admission,
    f1.discharge_date,
    f2.admission_id    AS readmission,
    f2.admit_date      AS readmit_date,
    DATEDIFF(day, f1.discharge_date, f2.admit_date) AS days_between
FROM FCT_ADMISSIONS f1
JOIN FCT_ADMISSIONS f2 
    ON f1.patient_sk = f2.patient_sk
    AND f2.admit_date > f1.discharge_date
    AND f2.admit_date <= DATEADD(day, 30, f1.discharge_date)
ORDER BY f1.patient_sk, f1.discharge_date
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- PATTERN 2: LENGTH OF STAY (LOS) ANALYSIS BY DIAGNOSIS
-- ───────────────────────────────────────────────────────
-- Use case: Find diagnoses with longest avg LOS — resource planning

SELECT 
    d.icd10_code,
    d.diagnosis_desc,
    d.severity,
    COUNT(*) AS admission_count,
    AVG(f.length_of_stay) AS avg_los,
    MIN(f.length_of_stay) AS min_los,
    MAX(f.length_of_stay) AS max_los,
    MEDIAN(f.length_of_stay) AS median_los
FROM FCT_ADMISSIONS f
JOIN DIM_DIAGNOSIS d ON f.diagnosis_sk = d.diagnosis_sk
GROUP BY d.icd10_code, d.diagnosis_desc, d.severity
HAVING COUNT(*) >= 5
ORDER BY avg_los DESC
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- PATTERN 3: PATIENT COHORT ANALYSIS BY AGE BUCKET
-- ───────────────────────────────────────────────────────
-- Use case: Compare healthcare utilization across age groups

SELECT 
    p.age_bucket,
    COUNT(DISTINCT p.patient_id) AS unique_patients,
    COUNT(f.admission_id) AS total_admissions,
    ROUND(AVG(f.length_of_stay), 2) AS avg_los,
    ROUND(AVG(f.total_cost), 2) AS avg_cost_per_admission,
    SUM(f.total_cost) AS total_revenue,
    100.0 * SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) 
        / COUNT(f.admission_id) AS readmission_rate_pct
FROM DIM_PATIENT p
LEFT JOIN FCT_ADMISSIONS f ON p.patient_sk = f.patient_sk
WHERE p.is_current = TRUE
GROUP BY p.age_bucket
ORDER BY 
    CASE p.age_bucket
        WHEN 'Under 18' THEN 1
        WHEN '18-34'    THEN 2
        WHEN '35-49'    THEN 3
        WHEN '50-64'    THEN 4
        WHEN '65+'      THEN 5
    END;


-- ───────────────────────────────────────────────────────
-- PATTERN 4: HOSPITAL UTILIZATION RATE
-- ───────────────────────────────────────────────────────
-- Bed utilization = (total occupied bed-days / available bed-days)

WITH monthly_usage AS (
    SELECT 
        h.hospital_sk,
        h.hospital_name,
        h.bed_count,
        DATE_TRUNC('month', f.admit_date) AS month,
        SUM(f.length_of_stay) AS occupied_bed_days
    FROM FCT_ADMISSIONS f
    JOIN DIM_HOSPITAL h ON f.hospital_sk = h.hospital_sk
    GROUP BY h.hospital_sk, h.hospital_name, h.bed_count, 
             DATE_TRUNC('month', f.admit_date)
)
SELECT 
    hospital_name,
    bed_count,
    month,
    occupied_bed_days,
    bed_count * DAY(LAST_DAY(month)) AS available_bed_days,
    ROUND(
        100.0 * occupied_bed_days / (bed_count * DAY(LAST_DAY(month))),
        2
    ) AS utilization_pct
FROM monthly_usage
ORDER BY utilization_pct DESC
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- PATTERN 5: CARE GAPS — patients overdue for follow-up
-- ───────────────────────────────────────────────────────
-- Use case: Patients with critical diagnoses but no recent visit

SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.age_bucket,
    p.insurance_type,
    MAX(f.admit_date) AS last_admission_date,
    DATEDIFF(day, MAX(f.admit_date), CURRENT_DATE()) AS days_since_last_visit
FROM DIM_PATIENT p
JOIN FCT_ADMISSIONS f ON p.patient_sk = f.patient_sk
JOIN DIM_DIAGNOSIS d ON f.diagnosis_sk = d.diagnosis_sk
WHERE p.is_current = TRUE
  AND d.severity IN ('Critical', 'High')
GROUP BY p.patient_id, p.first_name, p.last_name, p.age_bucket, p.insurance_type
HAVING DATEDIFF(day, MAX(f.admit_date), CURRENT_DATE()) > 180
ORDER BY days_since_last_visit DESC
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- PATTERN 6: HOSPITAL RANKINGS BY CARE QUALITY
-- ───────────────────────────────────────────────────────
-- Composite score: lower readmission + shorter LOS + lower cost = better

WITH hospital_metrics AS (
    SELECT 
        h.hospital_name,
        h.hospital_type,
        COUNT(*) AS total_admissions,
        ROUND(AVG(f.length_of_stay), 2) AS avg_los,
        ROUND(
            100.0 * SUM(CASE WHEN f.readmission_flag THEN 1 ELSE 0 END) 
                / COUNT(*), 2
        ) AS readmission_rate,
        ROUND(AVG(f.total_cost), 2) AS avg_cost
    FROM FCT_ADMISSIONS f
    JOIN DIM_HOSPITAL h ON f.hospital_sk = h.hospital_sk
    GROUP BY h.hospital_name, h.hospital_type
    HAVING COUNT(*) >= 10
)
SELECT 
    hospital_name,
    hospital_type,
    total_admissions,
    avg_los,
    readmission_rate,
    avg_cost,
    -- Lower rank = better hospital
    RANK() OVER (ORDER BY readmission_rate ASC) AS readmission_rank,
    RANK() OVER (ORDER BY avg_los ASC) AS los_rank,
    RANK() OVER (ORDER BY avg_cost ASC) AS cost_rank
FROM hospital_metrics
ORDER BY readmission_rank + los_rank + cost_rank
LIMIT 10;


-- ───────────────────────────────────────────────────────
-- PRACTICE EXERCISES — Try these on your own!
-- ───────────────────────────────────────────────────────
-- 
-- 1. Find the top 10 most common diagnosis combinations
--    (patients who had 2+ different diagnoses)
-- 
-- 2. Calculate 90-day readmission rate by hospital
-- 
-- 3. Identify high-cost outlier admissions
--    (cost > 2 standard deviations above hospital average)
-- 
-- 4. Find seasonal patterns in admissions
--    (which month has the most cardiovascular admissions?)
-- 
-- 5. Calculate per-patient lifetime healthcare cost ranking
-- 
-- 6. Build a "hospital efficiency score" combining:
--    - readmission rate (weight 40%)
--    - avg LOS (weight 30%)
--    - cost per admission (weight 30%)