{{ config(materialized='table') }}

with totals as (
    select count(*) as total_violations from {{ ref('dq_violations') }}
)

select
    v.violation_type,
    v.source_table,
    count(*) as violation_count,
    round(count(*) / t.total_violations, 4) as pct_of_all_violations
from {{ ref('dq_violations') }} v
cross join totals t
group by v.violation_type, v.source_table, t.total_violations
order by violation_count desc