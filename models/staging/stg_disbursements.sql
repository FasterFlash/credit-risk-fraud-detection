-- stg_disbursements.sql
select
    cast(disbursement_id as string)            as disbursement_id,
    cast(application_id as string)             as application_id,
    cast(loan_account_id as string)            as loan_account_id,
    cast(customer_id as string)                as customer_id,
    cast(disbursement_date as date)            as disbursement_date,
    cast(disbursement_timestamp as timestamp)  as disbursement_timestamp,
    cast(disbursed_amount as double)           as disbursed_amount,
    cast(disbursement_mode as string)          as disbursement_mode,
    cast(beneficiary_account as string)        as beneficiary_account,
    cast(beneficiary_ifsc as string)           as beneficiary_ifsc,
    cast(utr_number as string)                 as utr_number,
    cast(emi_start_date as date)               as emi_start_date,
    cast(loan_maturity_date as date)           as loan_maturity_date,
    cast(first_emi_amount as double)           as first_emi_amount,
    cast(nach_registration_status as string)   as nach_registration_status,
    cast(nach_bank_account as string)          as nach_bank_account,
    cast(nach_registration_date as date)       as nach_registration_date,
    cast(created_at as timestamp)              as created_at
from {{ source('bronze', 'disbursements') }}