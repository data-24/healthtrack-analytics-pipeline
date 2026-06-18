-- ════════════════════════════════════════════════════════════
-- WINDOW FUNCTIONS — Practice queries for HealthTrack project
-- ════════════════════════════════════════════════════════════
--
-- Window functions perform calculations across rows WITHOUT 
-- collapsing them like GROUP BY does. Essential for DE interviews.
--
-- Pattern: function() OVER (PARTITION BY ... ORDER BY ...)
--
-- Run these queries against your HEALTHTRACK_DB.STAGING schema.
-- ════════════════════════════════════════════════════════════

USE DATABASE HEALTHTRACK_DB;
USE SCHEMA STAGING;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 1: ROW_NUMBER — rank admissions per patient
-- ───────────────────────────────────────────────────────
-- Use case: "What was each patient's 1st, 2nd, 3rd admission?"

SELECT 
    patient_sk,
    admit_date,
    hospital_sk,
    total_cost,
    ROW_NUMBER() OVER (
        PARTITION BY patient_sk 
        ORDER BY admit_date
    ) AS admission_sequence
FROM FCT_ADMISSIONS
ORDER BY patient_sk, admit_date
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 2: RANK vs DENSE_RANK — top hospitals by revenue
-- ───────────────────────────────────────────────────────
-- RANK skips numbers on ties (1, 1, 3)
-- DENSE_RANK doesn't skip (1, 1, 2)

SELECT 
    hospital_sk,
    SUM(total_cost) AS total_revenue,
    RANK() OVER (ORDER BY SUM(total_cost) DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY SUM(total_cost) DESC) AS dense_rank
FROM FCT_ADMISSIONS
GROUP BY hospital_sk
ORDER BY total_revenue DESC
LIMIT 10;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 3: LAG — compare admission to PREVIOUS one
-- ───────────────────────────────────────────────────────
-- Use case: "How many days between consecutive admissions?"

SELECT 
    patient_sk,
    admit_date,
    LAG(admit_date) OVER (
        PARTITION BY patient_sk 
        ORDER BY admit_date
    ) AS previous_admit_date,
    DATEDIFF(day, 
        LAG(admit_date) OVER (PARTITION BY patient_sk ORDER BY admit_date),
        admit_date
    ) AS days_between_admissions
FROM FCT_ADMISSIONS
ORDER BY patient_sk, admit_date
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 4: LEAD — compare admission to NEXT one
-- ───────────────────────────────────────────────────────
-- Use case: "When was each patient's next admission?"

SELECT 
    patient_sk,
    admit_date,
    LEAD(admit_date) OVER (
        PARTITION BY patient_sk 
        ORDER BY admit_date
    ) AS next_admit_date
FROM FCT_ADMISSIONS
ORDER BY patient_sk, admit_date
LIMIT 20;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 5: Running totals — cumulative revenue
-- ───────────────────────────────────────────────────────
-- Use case: "What's the cumulative revenue per hospital over time?"

SELECT 
    hospital_sk,
    admit_date,
    total_cost,
    SUM(total_cost) OVER (
        PARTITION BY hospital_sk 
        ORDER BY admit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM FCT_ADMISSIONS
ORDER BY hospital_sk, admit_date
LIMIT 30;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 6: Moving average — 3-admission rolling avg LOS
-- ───────────────────────────────────────────────────────
-- Use case: "Smooth out trend by averaging last 3 admissions"

SELECT 
    hospital_sk,
    admit_date,
    length_of_stay,
    AVG(length_of_stay) OVER (
        PARTITION BY hospital_sk 
        ORDER BY admit_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_avg_los
FROM FCT_ADMISSIONS
ORDER BY hospital_sk, admit_date
LIMIT 30;


-- ───────────────────────────────────────────────────────
-- EXAMPLE 7: Percentage of total
-- ───────────────────────────────────────────────────────
-- Use case: "What % of total revenue comes from each hospital?"

SELECT 
    hospital_sk,
    SUM(total_cost) AS hospital_revenue,
    SUM(SUM(total_cost)) OVER () AS total_revenue,
    ROUND(
        100.0 * SUM(total_cost) / SUM(SUM(total_cost)) OVER (),
        2
    ) AS pct_of_total
FROM FCT_ADMISSIONS
GROUP BY hospital_sk
ORDER BY hospital_revenue DESC
LIMIT 10;


-- ───────────────────────────────────────────────────────
-- PRACTICE EXERCISES — Try these on your own!
-- ───────────────────────────────────────────────────────
-- 
-- 1. Find each patient's MOST EXPENSIVE admission using ROW_NUMBER + QUALIFY
-- 
-- 2. Rank diagnoses by frequency WITHIN each ICD category
-- 
-- 3. Calculate the rolling 30-day admission count per hospital
-- 
-- 4. Find patients whose admissions are getting more expensive over time
--    (current cost > previous cost)
--
-- 5. Identify top 3 hospitals by revenue in each state