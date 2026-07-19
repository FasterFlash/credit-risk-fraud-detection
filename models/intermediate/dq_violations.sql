{{ config(materialized='table') }}

with pan_checksum_failures as (
    select
        customer_id as record_id,
        'customers' as source_table,
        'pan_checksum_failure' as violation_type,
        concat('customer_id ', customer_id, ' appears ', count(*), ' times — PAN checksum mismatch injection') as violation_details,
        max(created_at) as source_created_at
    from {{ ref('stg_customers') }}
    group by customer_id
    having count(*) > 1
),

underage_customers as (
    select
        customer_id as record_id,
        'customers' as source_table,
        'underage_customer' as violation_type,
        concat('date_of_birth ', cast(date_of_birth as string), ' — customer under 18') as violation_details,
        created_at as source_created_at
    from {{ ref('stg_customers') }}
    where date_of_birth > current_date() - interval 18 years
),

cibil_out_of_range as (
    select
        bureau_pull_id as record_id,
        'bureau_pulls' as source_table,
        'cibil_out_of_range' as violation_type,
        concat('cibil_score ', cast(cibil_score as string), ' — outside valid 300-900 range') as violation_details,
        created_at as source_created_at
    from {{ ref('stg_bureau_pulls') }}
    where cibil_score is not null
      and (cibil_score < 300 or cibil_score > 900)
),

missing_required_fields as (
    select
        application_id as record_id,
        'loan_applications' as source_table,
        'missing_required_field' as violation_type,
        concat_ws(', ',
            case when customer_id is null then 'customer_id is null' end,
            case when applied_amount is null then 'applied_amount is null' end,
            case when loan_type is null then 'loan_type is null' end
        ) as violation_details,
        created_at as source_created_at
    from {{ ref('stg_loan_applications') }}
    where customer_id is null or applied_amount is null or loan_type is null
),

invalid_ifsc as (
    select
        disbursement_id as record_id,
        'disbursements' as source_table,
        'invalid_ifsc' as violation_type,
        concat('beneficiary_ifsc ', beneficiary_ifsc, ' — fails IFSC format') as violation_details,
        created_at as source_created_at
    from {{ ref('stg_disbursements') }}
    where beneficiary_ifsc is not null
      and not (beneficiary_ifsc rlike '^[A-Z]{4}0[A-Z0-9]{6}$')
),

utr_collisions as (
    select
        any_value(disbursement_id) as record_id,
        'disbursements' as source_table,
        'utr_collision' as violation_type,
        concat('utr_number ', utr_number, ' used by ', count(*), ' disbursements') as violation_details,
        max(created_at) as source_created_at
    from {{ ref('stg_disbursements') }}
    group by utr_number
    having count(*) > 1
),

negative_amounts as (
    select
        transaction_id as record_id,
        'transactions' as source_table,
        'negative_amount' as violation_type,
        concat('amount ', cast(amount as string), ' — must be > 0') as violation_details,
        created_at as source_created_at
    from {{ ref('stg_transactions') }}
    where amount <= 0
),

unioned as (
    select * from pan_checksum_failures
    union all select * from underage_customers
    union all select * from cibil_out_of_range
    union all select * from missing_required_fields
    union all select * from invalid_ifsc
    union all select * from utr_collisions
    union all select * from negative_amounts
)

select
    md5(concat_ws('|', source_table, record_id, violation_type)) as violation_id,
    source_table,
    record_id,
    violation_type,
    violation_details,
    source_created_at,
    current_timestamp() as detected_at
from unioned