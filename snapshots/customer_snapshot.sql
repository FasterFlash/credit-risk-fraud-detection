{% snapshot customer_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='customer_id',
        strategy='check',
        check_cols=[
            'employment_type',
            'monthly_income',
            'employer_name',
            'city',
            'state',
            'pin_code',
            'kyc_status',
            'customer_segment',
            'is_active',
        ],
    )
}}

select * from {{ ref('stg_customers') }}

{% endsnapshot %}