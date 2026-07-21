{{ config(materialized='table') }}

with bounces as (
    select * from {{ ref('stg_nach_bounces') }}
),

loan_context as (
    select loan_account_id, loan_type
    from {{ ref('dim_loan_account') }}
    where is_current
)

select
    b.bounce_id,
    b.loan_account_id,
    lc.loan_type,
    b.repayment_event_id,
    b.customer_id,
    b.nach_debit_date,
    b.nach_debit_timestamp,
    b.amount_attempted,
    b.return_date,
    b.return_reason,
    b.return_code,
    b.bank_charges_applied,
    b.gst_on_charges,
    b.retry_attempted,
    b.retry_outcome,
    b.consecutive_bounce_count,
    b.is_first_bounce,
    b.account_balance_at_debit,
    b.shortfall_at_bounce,
    b.is_severe_bounce
from bounces b
left join loan_context lc
    on b.loan_account_id = lc.loan_account_id