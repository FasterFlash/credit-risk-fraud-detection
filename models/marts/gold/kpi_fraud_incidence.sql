{{ config(materialized='table') }}

with totals as (
    select
        count(*) as total_transactions,
        sum(case when is_fraud then 1 else 0 end) as total_fraud_transactions
    from {{ ref('fct_transactions') }}
),

by_fraud_type as (
    select
        fraud_type,
        count(*) as fraud_transactions
    from {{ ref('fct_transactions') }}
    where is_fraud
    group by fraud_type
)

select
    'ALL' as fraud_type,
    t.total_fraud_transactions as fraud_transactions,
    t.total_transactions,
    round(t.total_fraud_transactions / t.total_transactions, 6) as fraud_incidence_rate
from totals t

union all

select
    b.fraud_type,
    b.fraud_transactions,
    t.total_transactions,
    round(b.fraud_transactions / t.total_transactions, 6) as fraud_incidence_rate
from by_fraud_type b
cross join totals t

order by fraud_transactions desc