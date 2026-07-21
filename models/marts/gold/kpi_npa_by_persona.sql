{{ config(materialized='table') }}

with current_persona as (
    select customer_id, persona
    from {{ ref('customer_snapshot') }}
    where dbt_valid_to is null
),

current_loans as (
    select loan_account_id, customer_id, loan_status, dpd_category
    from {{ ref('dim_loan_account') }}
    where is_current
)

select
    p.persona,
    count(*) as total_loans,
    sum(case when l.loan_status = 'NPA' then 1 else 0 end) as npa_loans,
    round(sum(case when l.loan_status = 'NPA' then 1 else 0 end) / count(*), 4) as npa_rate,
    sum(case when l.dpd_category in ('DOUBTFUL_1', 'DOUBTFUL_2', 'LOSS') then 1 else 0 end) as severely_delinquent_loans
from current_loans l
join current_persona p
    on l.customer_id = p.customer_id
group by p.persona
order by npa_rate desc