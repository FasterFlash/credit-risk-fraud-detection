{{ config(materialized='table') }}

with current_loans as (
    select *
    from {{ ref('dim_loan_account') }}
    where is_current
      and loan_type is not null
),

by_type as (
    select
        loan_type,
        count(*) as total_loans,
        sum(case when loan_status in ('DEFAULT', 'NPA', 'WRITTEN_OFF') then 1 else 0 end) as defaulted_loans,
        round(
            sum(case when loan_status in ('DEFAULT', 'NPA', 'WRITTEN_OFF') then 1 else 0 end) / count(*),
            4
        ) as default_rate
    from current_loans
    group by loan_type
),

overall as (
    select
        'ALL' as loan_type,
        count(*) as total_loans,
        sum(case when loan_status in ('DEFAULT', 'NPA', 'WRITTEN_OFF') then 1 else 0 end) as defaulted_loans,
        round(
            sum(case when loan_status in ('DEFAULT', 'NPA', 'WRITTEN_OFF') then 1 else 0 end) / count(*),
            4
        ) as default_rate
    from current_loans
)

select * from overall
union all
select * from by_type
order by loan_type