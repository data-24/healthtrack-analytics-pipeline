{{
    config(
        materialized='view',
        tags=['staging']
    )
    
}}
with source as (
    select * from {{source('raw','hospitals')}}

),
renamed as(
select 
hospital_id ::VARCHAR as hospital_id    ,
hospital_name::VARCHAR as hospital_name,
hospital_type ::VARCHAR as hospital_type,
city::VARCHAR as city,
state::VARCHAR as state,
bed_count::NUMBER as bed_count,
is_teaching::BOOLEAN as is_teaching,
updated_at::DATE as updated_at,
_load_ts ::TIMESTAMP_NTZ as load_ts,
_file_name::VARCHAR as source_file
from source
),
deduplicated as(
    SELECT *
    FROM renamed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY hospital_id 
        ORDER BY load_ts DESC
    ) = 1
)

select * from deduplicated
