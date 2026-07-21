{{ config(materialized='table') }}

select
    d.loan_account_id,
    l.customer_id,
    l.loan_status,
    l.current_dpd,
    l.dpd_category,
    l.outstanding_total,
    l.interest_rate,
    l.tenure_months,
    l.emi_amount,
    l.disbursement_date,
    l.maturity_date,
    d.vehicle_category,
    d.vehicle_make,
    d.vehicle_model,
    d.manufacturing_year,
    d.is_new_vehicle,
    d.ex_showroom_price,
    d.on_road_price,
    d.down_payment_amount,
    d.ltv_ratio,
    d.current_market_value,
    d.depreciation_rate_annual,
    -- negative equity flag: outstanding balance exceeds the vehicle's current
    -- (depreciated) market value -- the collateral no longer fully covers the loan
    (l.outstanding_total > d.current_market_value) as is_negative_equity
from {{ ref('stg_loan_auto_detail') }} d
left join {{ ref('dim_loan_account') }} l
    on d.loan_account_id = l.loan_account_id
    and l.is_current