-- stg_kyc_profiles.sql
select
    cast(customer_id as string)                    as customer_id,
    cast(pan_verified as boolean)                  as pan_verified,
    cast(aadhaar_verified as boolean)               as aadhaar_verified,
    cast(address_proof_type as string)              as address_proof_type,
    cast(address_proof_verified as boolean)         as address_proof_verified,
    cast(income_proof_type as string)               as income_proof_type,
    cast(income_proof_verified as boolean)          as income_proof_verified,
    cast(video_kyc_completed as boolean)            as video_kyc_completed,
    cast(video_kyc_date as date)                    as video_kyc_date,
    cast(video_kyc_agent_id as string)              as video_kyc_agent_id,
    cast(is_politically_exposed_person as boolean)  as is_politically_exposed_person,
    cast(is_high_risk_customer as boolean)          as is_high_risk_customer,
    cast(risk_category as string)                   as risk_category,
    cast(annual_income_declared as double)          as annual_income_declared,
    cast(kyc_initiated_date as date)                as kyc_initiated_date,
    cast(kyc_completed_date as date)                as kyc_completed_date,
    cast(kyc_expiry_date as date)                   as kyc_expiry_date,
    cast(created_at as timestamp)                   as created_at
from {{ source('bronze', 'kyc_profiles') }}