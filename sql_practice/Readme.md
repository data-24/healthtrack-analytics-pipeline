# SQL Practice — HealthTrack Project

A collection of SQL exercises for students to practice on top of the HealthTrack data warehouse. Run these queries against the project's Snowflake database to build SQL skills relevant to data engineering interviews and healthcare analytics work.

## Prerequisites

- Access to a Snowflake account with the HealthTrack project loaded
- Familiarity with basic SQL (SELECT, JOIN, GROUP BY, WHERE)
- Run queries in the `HEALTHTRACK_DB.STAGING` schema

## Files

### 01_window_functions.sql
Core window function patterns every DE must know: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, running totals, moving averages, percentage of total. These appear in nearly every senior DE interview.

### 02_qualify_examples.sql
Modern Snowflake patterns: QUALIFY for filtering window functions, GROUPING SETS, ROLLUP, PIVOT, and LISTAGG. The QUALIFY clause is what separates juniors from seniors in Snowflake SQL.

### 03_healthcare_patterns.sql
Real-world healthcare analytics patterns: 30-day readmission detection, length of stay analysis, patient cohort analysis by age, hospital bed utilization, care gap identification, and hospital quality rankings.

## How to use

1. Open each file in any SQL editor connected to Snowflake
2. Read the comments explaining each pattern
3. Run the example queries to see results
4. Try the practice exercises at the bottom of each file
5. Modify queries with your own filters and groupings

## Why these patterns matter

Each file ends with PRACTICE EXERCISES — these are the kind of questions asked in real DE interviews. Solving them on YOUR project data is the best way to internalize the patterns.

## Tips

- Always understand the GRAIN of your results (one row per what?)
- Use QUALIFY instead of WHERE for filtering window functions
- LEFT JOIN preserves all rows; INNER JOIN can silently drop them
- Snowflake doesn't enforce constraints — always check your assumptions