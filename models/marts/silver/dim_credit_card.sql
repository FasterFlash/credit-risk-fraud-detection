{{ config(materialized='table') }}

select
    d.card_account_id as loan_account_id,
    d.customer_id,
    l.loan_status,
    l.current_dpd,
    l.dpd_category,
    d.card_type,
    d.card_network,
    d.card_status,
    d.credit_limit,
    d.available_credit,
    d.current_outstanding,
    d.statement_day,
    d.payment_due_day,
    d.last_statement_balance,
    d.min_amount_due,
    d.total_amount_due,
    d.payment_behavior,
    d.utilization_ratio,
    d.is_overlimit,
    d.overlimit_count_lifetime,
    d.revolving_balance,
    d.revolving_apr,
    d.card_issue_date,
    d.card_expiry_date,
    -- monthly interest charge on the current revolving balance, recomputed here
    -- rather than trusting a stored value
    round(d.revolving_balance * (d.revolving_apr / 12), 2) as monthly_interest_charge
from {{ ref('stg_credit_card_detail') }} d
left join {{ ref('dim_loan_account') }} l
    on d.card_account_id = l.loan_account_id
    and l.is_current