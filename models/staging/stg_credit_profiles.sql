-- stg_credit_profiles.sql
select
    cast(customer_id as string)                as customer_id,
    cast(cibil_score as int)                   as cibil_score,
    cast(is_new_to_credit as boolean)          as is_new_to_credit,
    cast(cibil_last_updated as date)           as cibil_last_updated,
    cast(total_active_loans as int)            as total_active_loans,
    cast(total_active_credit_cards as int)     as total_active_credit_cards,
    cast(total_outstanding_amount as double)   as total_outstanding_amount,
    cast(total_overdue_amount as double)       as total_overdue_amount,
    cast(hard_pull_count_last_30d as int)      as hard_pull_count_last_30d,
    cast(hard_pull_count_last_60d as int)      as hard_pull_count_last_60d,
    cast(hard_pull_count_last_90d as int)      as hard_pull_count_last_90d,
    cast(months_since_last_default as int)     as months_since_last_default,
    cast(max_dpd_last_12m as int)              as max_dpd_last_12m,
    cast(max_dpd_ever as int)                  as max_dpd_ever,
    cast(written_off_accounts as int)          as written_off_accounts,
    cast(settled_accounts as int)              as settled_accounts,
    cast(existing_emi_total as double)         as existing_emi_total,
    cast(foir_current as double)               as foir_current,
    cast(created_at as timestamp)              as created_at,
    cast(updated_at as timestamp)              as updated_at
from {{ source('bronze', 'credit_profiles') }}