{{
    config(
        materialized='ephemeral'
    )
}}

-- ════════════════════════════════════════════════
-- Ephemeral model: admission date attributes
-- Inlined as CTE in downstream models.
-- Never materialized in Snowflake.
-- ════════════════════════════════════════════════

WITH source AS (
    SELECT * FROM {{ ref('stg_admissions') }}
),

date_attributes AS (
    SELECT
        admission_id,
        admit_date,
        discharge_date,
        
        -- Date dimensions
        EXTRACT(YEAR FROM admit_date)         AS admit_year,
        EXTRACT(MONTH FROM admit_date)        AS admit_month,
        EXTRACT(QUARTER FROM admit_date)      AS admit_quarter,
        EXTRACT(DAYOFWEEK FROM admit_date)    AS admit_day_of_week,
        
        -- Useful derivations
        TO_CHAR(admit_date, 'YYYY-MM')        AS admit_year_month,
        DATEDIFF(day, admit_date, discharge_date) AS calculated_los
    FROM source
)

SELECT * FROM date_attributes