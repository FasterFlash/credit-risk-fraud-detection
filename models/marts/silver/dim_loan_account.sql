{{ config(materialized='table') }}

with static_attrs as (
    select
        d.loan_account_id,
        d.customer_id,
        la.loan_type,
        la.product_code,
        d.disbursement_date,
        d.emi_start_date,
        d.loan_maturity_date  as maturity_date,
        ud.interest_rate_annual as interest_rate,
        ud.approved_tenure_months as tenure_months,
        ud.emi_amount,
        ud.cibil_score_at_decision,
        d.disbursed_amount,
        d.nach_registration_status
    from {{ ref('stg_disbursements') }} d
    left join {{ ref('stg_loan_applications') }} la
        on d.application_id = la.application_id
    left join {{ ref('stg_underwriting_decisions') }} ud
        on d.application_id = ud.application_id
),

history as (
    select
        loan_account_id,
        customer_id,
        after_loan_status        as loan_status,
        after_current_dpd        as current_dpd,
        after_outstanding_total  as outstanding_total,
        after_consecutive_missed as consecutive_missed,
        change_reason,
        triggered_by,
        commit_timestamp as valid_from,
        lead(commit_timestamp) over (
            partition by loan_account_id
            order by commit_timestamp, sequence_number
        ) as valid_to,
        row_number() over (
            partition by loan_account_id
            order by commit_timestamp desc, sequence_number desc
        ) = 1 as is_current
    from {{ ref('stg_cdc_loan_status') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['h.loan_account_id', 'h.valid_from']) }} as loan_account_sk,
    h.loan_account_id,
    h.customer_id,
    s.loan_type,
    s.product_code,
    s.disbursement_date,
    s.emi_start_date,
    s.maturity_date,
    s.interest_rate,
    s.tenure_months,
    s.emi_amount,
    s.cibil_score_at_decision,
    s.disbursed_amount,
    s.nach_registration_status,
    h.loan_status,
    h.current_dpd,
    h.outstanding_total,
    h.consecutive_missed,
    case
        when h.current_dpd = 0    then 'STANDARD'
        when h.current_dpd <= 90  then 'SPECIAL_MENTION'
        when h.current_dpd <= 180 then 'SUB_STANDARD'
        when h.current_dpd <= 270 then 'DOUBTFUL_1'
        when h.current_dpd <= 360 then 'DOUBTFUL_2'
        else 'LOSS'
    end as dpd_category,
    h.change_reason,
    h.triggered_by,
    h.valid_from,
    h.valid_to,
    h.is_current
from history h
left join static_attrs s
    on h.loan_account_id = s.loan_account_id