-- ════════════════════════════════════════════════
-- Singular test: no admissions in the future
-- Business rule: admit_date must be <= today
-- If this query returns rows, the test FAILS
-- ════════════════════════════════════════════════

SELECT
    admission_id,
    admit_date,
    CURRENT_DATE() AS today,
    DATEDIFF(day, CURRENT_DATE(), admit_date) AS days_in_future
FROM {{ ref('stg_admissions') }}
WHERE admit_date > CURRENT_DATE()