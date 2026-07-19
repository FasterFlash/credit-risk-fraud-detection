-- stg_repayment_schedules.sql
select
    cast(schedule_id as string)                as schedule_id,
    cast(loan_account_id as string)            as loan_account_id,
    cast(customer_id as string)                as customer_id,
    cast(installment_number as int)            as installment_number,
    cast(due_date as date)                     as due_date,
    cast(opening_principal as double)          as opening_principal,
    cast(emi_amount as double)                 as emi_amount,
    cast(principal_component as double)        as principal_component,
    cast(interest_component as double)         as interest_component,
    cast(closing_principal as double)          as closing_principal,
    cast(cumulative_principal_paid as double)  as cumulative_principal_paid,
    cast(cumulative_interest_paid as double)   as cumulative_interest_paid,
    cast(is_paid as boolean)                   as is_paid,
    cast(paid_date as date)                    as paid_date,
    cast(paid_amount as double)                as paid_amount,
    cast(created_at as timestamp)              as created_at
from {{ source('bronze', 'repayment_schedules') }}