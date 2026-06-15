{% snapshot snp_patients %}

{{
    config(
        target_schema='snapshots',
        unique_key='patient_id',
        strategy='check',
        check_cols=['city', 'state', 'insurance_type'],
        invalidate_hard_deletes=True
    )
}}

SELECT * FROM {{ ref('stg_patients') }}

{% endsnapshot %}