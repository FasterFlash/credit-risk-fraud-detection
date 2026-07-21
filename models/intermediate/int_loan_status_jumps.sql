with valid_transitions as (
    select * from (
        values
            ('ACTIVE',      array('ACTIVE', 'CURRENT')),
            ('CURRENT',     array('CURRENT', '30_DPD')),
            ('30_DPD',      array('CURRENT', '30_DPD', '60_DPD')),
            ('60_DPD',      array('CURRENT', '30_DPD', '60_DPD', '90_DPD')),
            ('90_DPD',      array('CURRENT', '60_DPD', '90_DPD', 'DEFAULT', 'NPA')),
            ('DEFAULT',     array('DEFAULT', 'SETTLED', 'WRITTEN_OFF', 'NPA')),
            ('NPA',         array('NPA', 'SETTLED', 'WRITTEN_OFF')),
            ('SETTLED',     array('SETTLED')),
            ('WRITTEN_OFF', array('WRITTEN_OFF')),
            ('CLOSED',      array('CLOSED'))
    ) as t(before_status, valid_next_statuses)
),

cdc_with_validity as (
    select
        cdc.*,
        vt.valid_next_statuses
    from {{ ref('stg_cdc_loan_status') }} cdc
    left join valid_transitions vt
        on cdc.before_loan_status = vt.before_status
)

select
    cdc_event_id,
    loan_account_id,
    customer_id,
    before_loan_status,
    after_loan_status,
    before_current_dpd,
    after_current_dpd,
    change_reason,
    triggered_by,
    commit_timestamp,
    -- INSERT events (before_loan_status is null) are never a jump violation --
    -- there's no prior state to jump from.
    case
        when before_loan_status is null then false
        when valid_next_statuses is null then true   -- unknown before_status = suspicious by definition
        when array_contains(valid_next_statuses, after_loan_status) then false
        else true
    end as is_state_jump_violation
from cdc_with_validity