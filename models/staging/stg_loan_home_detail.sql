-- stg_loan_home_detail.sql
select
    cast(loan_account_id as string)            as loan_account_id,
    cast(property_type as string)              as property_type,
    cast(property_address as string)           as property_address,
    cast(property_city as string)              as property_city,
    cast(property_state as string)             as property_state,
    cast(property_pin_code as string)          as property_pin_code,
    cast(property_value as double)             as property_value,
    cast(ltv_ratio as double)                  as ltv_ratio,
    cast(construction_stage as string)         as construction_stage,
    cast(builder_name as string)               as builder_name,
    cast(expected_possession_date as date)     as expected_possession_date,
    cast(is_rera_approved as boolean)          as is_rera_approved,
    cast(co_applicant_relation as string)      as co_applicant_relation,
    cast(co_applicant_income as double)        as co_applicant_income,
    cast(base_rate_type as string)             as base_rate_type,
    cast(spread_over_base as double)           as spread_over_base,
    cast(current_effective_rate as double)     as current_effective_rate,
    cast(rate_reset_date as date)              as rate_reset_date,
    cast(insurance_opted as boolean)           as insurance_opted,
    cast(insurance_premium as double)          as insurance_premium,
    cast(created_at as timestamp)              as created_at
from {{ source('bronze', 'loan_home_detail') }}