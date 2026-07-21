{{ config(materialized='table') }}

select
    d.loan_account_id,
    l.customer_id,
    l.loan_status,
    l.current_dpd,
    l.dpd_category,
    l.outstanding_total,
    l.interest_rate,
    l.tenure_months,
    l.emi_amount,
    l.disbursement_date,
    l.maturity_date,
    d.purpose,
    d.collateral_type,
    d.insurance_opted,
    d.insurance_premium,
    d.prepayment_penalty_rate,
    d.foreclosure_charges_pct,
    d.lock_in_period_months
from {{ ref('stg_loan_personal_detail') }} d
left join {{ ref('dim_loan_account') }} l
    on d.loan_account_id = l.loan_account_id
    and l.is_current