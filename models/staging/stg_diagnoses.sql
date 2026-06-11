{{
    config(
        materialized='view',
        tags=['staging']
    )
}}

WITH source AS (
    select * from {{source('raw','diagnoses')}}
),

renamed AS (
   
select 

    diagnosis_id ::VARCHAR as diagnosis_id    ,
    icd10_code::VARCHAR as icd10_code,
    diagnosis_desc ::VARCHAR as diagnosis_desc,
    diagnosis_category::VARCHAR as diagnosis_category,
    severity::VARCHAR as severity,
    updated_at::DATE as updated_at,
    _load_ts ::TIMESTAMP_NTZ as load_ts,
    _file_name::VARCHAR as source_file

from source

),

deduplicated AS (
        SELECT *
    FROM renamed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY diagnosis_id 
        ORDER BY load_ts DESC
    ) = 1
    -- TODO: QUALIFY ROW_NUMBER() partitioned by diagnosis_id, ordered by load_ts DESC
)

SELECT * FROM deduplicated