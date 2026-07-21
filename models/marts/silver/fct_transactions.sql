{{ config(materialized='table') }}

select
    transaction_id,
    customer_id,
    account_id,
    loan_account_id,
    transaction_type,
    transaction_mode,
    amount,
    transaction_date,
    transaction_timestamp,
    merchant_category,
    device_id,
    channel,
    velocity_1hr,
    velocity_24hr,
    amount_vs_30d_avg_ratio,
    is_new_device,
    is_new_merchant_category,
    is_night_transaction,
    time_since_last_txn_mins,
    is_fraud,
    fraud_type,
    fraud_scenario_id
from {{ ref('int_transactions_features') }}