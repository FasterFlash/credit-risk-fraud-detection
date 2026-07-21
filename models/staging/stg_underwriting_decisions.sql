-- stg_underwriting_decisions.sql
select
    cast(decision_id as string)                as decision_id,
    cast(application_id as string)             as application_id,
    cast(customer_id as string)                as customer_id,
    cast(decision as string)                   as decision,
    cast(decision_timestamp as timestamp)      as decision_timestamp,
    cast(decision_date as date)                as decision_date,
    cast(approved_amount as double)            as approved_amount,
    cast(approved_tenure_months as int)        as approved_tenure_months,
    cast(interest_rate_annual as double)       as interest_rate_annual,
    cast(emi_amount as double)                 as emi_amount,
    cast(processing_fee as double)             as processing_fee,
    cast(processing_fee_gst as double)         as processing_fee_gst,
    cast(loan_insurance_amount as double)      as loan_insurance_amount,
    cast(cibil_score_at_decision as int)       as cibil_score_at_decision,
    cast(foir_after_approval as double)        as foir_after_approval,
    cast(ltv_ratio as double)                  as ltv_ratio,
    cast(rejection_reason_codes as string)     as rejection_reason_codes,
    cast(decision_model_version as string)     as decision_model_version,
    cast(underwriter_id as string)             as underwriter_id,
    cast(created_at as timestamp)              as created_at
from {{ source('bronze', 'underwriting_decisions') }}