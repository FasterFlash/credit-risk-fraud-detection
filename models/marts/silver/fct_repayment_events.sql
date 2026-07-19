{{ config(materialized='table') }}

with events as (
    select * from {{ ref('stg_repayment_events') }}
),

loan_context as (
    select loan_account_id, loan_type, customer_id as loan_customer_id
    from {{ ref('dim_loan_account') }}
    where is_current
)

select
    e.repayment_event_id,
    e.loan_account_id,
    lc.loan_type,
    e.schedule_id,
    e.customer_id,
    e.installment_number,
    e.due_date,
    e.amount_due,
    e.payment_date,
    e.amount_paid,
    e.shortfall,
    e.is_partial,
    e.is_missed,
    e.is_on_time,
    e.within_grace_period,
    e.days_late,
    e.payment_mode,
    e.payment_reference,
    e.nach_presented,
    e.nach_return_reason,
    e.grace_period_used,
    e.penalty_charged,
    e.penal_interest_rate,
    e.dpd_at_event,
    e.loan_status_at_event,
    e.consecutive_missed_at_event,
    e.salary_credited_this_month
from events e
left join loan_context lc
    on e.loan_account_id = lc.loan_account_id