-- ════════════════════════════════════════════════════════════
-- QUALIFY & MODERN SNOWFLAKE PATTERNS
-- Practice queries for HealthTrack project
-- ════════════════════════════════════════════════════════════
--
-- QUALIFY is Snowflake's modern way to filter window function results.
-- Cleaner than the old "WITH numbered AS ... WHERE rn = 1" pattern.
-- 
-- Run these queries against your HEALTHTRACK_DB.STAGING schema.
-- ════════════════════════════════════════════════════════════

USE DATABASE HEALTHTRACK_DB;
USE SCHEMA STAGING;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 1: QUALIFY for deduplication (the dbt pattern)
-- ───────────────────────────────────────────────────────
-- Use case: Keep only the LATEST version of each patient

SELECT *
FROM STG_PATIENTS
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY patient_id 
    ORDER BY load_ts DESC
) = 1;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 2: QUALIFY for "first" record
-- ───────────────────────────────────────────────────────
-- Use case: Get each patient's FIRST admission

SELECT 
    patient_sk,
    admit_date,
    hospital_sk,
    total_cost
FROM FCT_ADMISSIONS
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY patient_sk 
    ORDER BY admit_date ASC
) = 1
ORDER BY patient_sk;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 3: QUALIFY for top-N per group
-- ───────────────────────────────────────────────────────
-- Use case: Top 3 most expensive admissions per hospital

SELECT 
    hospital_sk,
    admit_date,
    total_cost,
    RANK() OVER (
        PARTITION BY hospital_sk 
        ORDER BY total_cost DESC
    ) AS cost_rank
FROM FCT_ADMISSIONS
QUALIFY cost_rank <= 3
ORDER BY hospital_sk, cost_rank;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 4: QUALIFY with multiple conditions
-- ───────────────────────────────────────────────────────
-- Use case: Patients with multiple admissions to SAME hospital

SELECT 
    patient_sk,
    hospital_sk,
    COUNT(*) AS visit_count
FROM FCT_ADMISSIONS
GROUP BY patient_sk, hospital_sk
QUALIFY COUNT(*) > 1
ORDER BY visit_count DESC
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 5: GROUPING SETS — multiple aggregations in ONE query
-- ───────────────────────────────────────────────────────
-- Use case: Get summary at MULTIPLE levels simultaneously

SELECT 
    h.hospital_type,
    h.state,
    COUNT(*) AS admission_count,
    SUM(f.total_cost) AS total_revenue
FROM FCT_ADMISSIONS f
JOIN DIM_HOSPITAL h ON f.hospital_sk = h.hospital_sk
GROUP BY GROUPING SETS (
    (h.hospital_type, h.state),  -- by type AND state
    (h.hospital_type),           -- just by type
    (h.state),                   -- just by state
    ()                           -- grand total
)
ORDER BY h.hospital_type, h.state;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 6: ROLLUP — hierarchical aggregation
-- ───────────────────────────────────────────────────────
-- Use case: Year → Quarter → Month drill-down

SELECT 
    EXTRACT(YEAR FROM admit_date) AS year,
    EXTRACT(QUARTER FROM admit_date) AS quarter,
    EXTRACT(MONTH FROM admit_date) AS month,
    COUNT(*) AS admissions
FROM FCT_ADMISSIONS
GROUP BY ROLLUP (
    EXTRACT(YEAR FROM admit_date),
    EXTRACT(QUARTER FROM admit_date),
    EXTRACT(MONTH FROM admit_date)
)
ORDER BY year NULLS FIRST, quarter NULLS FIRST, month NULLS FIRST;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 7: PIVOT — turn rows into columns
-- ───────────────────────────────────────────────────────
-- Use case: Admission count by hospital and admission_type

SELECT *
FROM (
    SELECT 
        hospital_sk,
        admission_type
    FROM FCT_ADMISSIONS
) src
PIVOT (
    COUNT(*) 
    FOR admission_type IN ('Emergency', 'Elective', 'Urgent', 'Newborn')
)
LIMIT 10;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 8: LISTAGG — concatenate values per group
-- ───────────────────────────────────────────────────────
-- Use case: Comma-separated list of diagnoses per patient

SELECT 
    f.patient_sk,
    LISTAGG(DISTINCT d.icd10_code, ', ') 
        WITHIN GROUP (ORDER BY d.icd10_code) AS all_diagnoses,
    COUNT(*) AS admission_count
FROM FCT_ADMISSIONS f
JOIN DIM_DIAGNOSIS d ON f.diagnosis_sk = d.diagnosis_sk
GROUP BY f.patient_sk
HAVING COUNT(*) > 2
ORDER BY admission_count DESC
LIMIT 10;


-- ───────────────────────────────────────────────────────
-- PRACTICE EXERCISES — Try these on your own!
-- ───────────────────────────────────────────────────────
-- 
-- 1. Find each hospital's most common diagnosis using QUALIFY
-- 
-- 2. Use GROUPING SETS to get totals by hospital_type, state, AND admission_type
-- 
-- 3. Use LISTAGG to show comma-separated hospital names per US state
-- 
-- 4. PIVOT to show monthly admission counts by hospital_type
-- 
-- 5. Find diagnoses that appear in MORE than 50% of one hospital's admissions