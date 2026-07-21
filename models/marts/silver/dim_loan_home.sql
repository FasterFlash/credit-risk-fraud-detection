{{ config(materialized='table') }}

select
    d.loan_account_id,
    l.customer_id,
    l.loan_status,
    l.current_dpd,
    l.dpd_category,
    l.outstanding_total,
    l.interest_rate as current_effective_rate_dim,   -- from CDC/dim; compare against source below
    l.tenure_months,
    l.emi_amount,
    l.disbursement_date,
    l.maturity_date,
    d.property_type,
    d.property_city,
    d.property_state,
    d.property_value,
    d.ltv_ratio,
    d.is_rera_approved,
    d.co_applicant_relation,
    d.co_applicant_income,
    d.base_rate_type,
    d.spread_over_base,
    d.current_effective_rate,
    d.rate_reset_date,
    -- flag: is the loan's outstanding LTV recomputed from current dim state
    -- vs. the property value here worse than the underwriting-time ltv_ratio?
    round(l.outstanding_total / nullif(d.property_value, 0), 4) as current_ltv_recomputed
from {{ ref('stg_loan_home_detail') }} d
left join {{ ref('dim_loan_account') }} l
    on d.loan_account_id = l.loan_account_id
    and l.is_current