-- stg_loan_personal_detail.sql
select
    cast(loan_account_id as string)            as loan_account_id,
    cast(purpose as string)                    as purpose,
    cast(collateral_type as string)            as collateral_type,
    cast(insurance_opted as boolean)           as insurance_opted,
    cast(insurance_premium as double)          as insurance_premium,
    cast(prepayment_penalty_rate as double)    as prepayment_penalty_rate,
    cast(foreclosure_charges_pct as double)    as foreclosure_charges_pct,
    cast(lock_in_period_months as int)         as lock_in_period_months,
    cast(created_at as timestamp)              as created_at
from {{ source('bronze', 'loan_personal_detail') }}