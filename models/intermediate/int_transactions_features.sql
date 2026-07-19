with base as (
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
        is_fraud,
        fraud_type,
        fraud_scenario_id
    from {{ ref('stg_transactions') }}
),

windowed as (
    select
        *,

        -- velocity: count of this customer's transactions in trailing time windows,
        -- INCLUDING the current row (matches source semantics: "my Nth txn in the
        -- last hour" counts itself)
        count(*) over (
            partition by customer_id
            order by transaction_timestamp
            range between interval 1 hours preceding and current row
        ) as velocity_1hr,

        count(*) over (
            partition by customer_id
            order by transaction_timestamp
            range between interval 24 hours preceding and current row
        ) as velocity_24hr,

        -- trailing 30-day average, EXCLUDING the current row so a fraud spike
        -- doesn't dilute its own baseline
        -- trailing 30-day average, EXCLUDING the current row so a fraud spike
        -- doesn't dilute its own baseline
        -- NOTE: both frame bounds must share the same interval granularity in
        -- Spark SQL, so 30 days is expressed in seconds (30*24*60*60) to match
        -- the 1-second bound, rather than mixing "days" and "seconds" literals.
        avg(amount) over (
            partition by customer_id
            order by transaction_timestamp
            range between interval 2592000 seconds preceding and interval 1 seconds preceding
        ) as avg_amount_30d,

        -- first-ever occurrence of this (customer, device) / (customer, category) pair
        min(transaction_timestamp) over (
            partition by customer_id, device_id
        ) as first_seen_device_ts,

        min(transaction_timestamp) over (
            partition by customer_id, merchant_category
        ) as first_seen_category_ts,

        -- previous transaction timestamp for this customer
        lag(transaction_timestamp) over (
            partition by customer_id
            order by transaction_timestamp
        ) as prev_transaction_timestamp

    from base
)

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

    round(
        amount / nullif(coalesce(avg_amount_30d, amount), 0),
        4
    ) as amount_vs_30d_avg_ratio,

    case
        when device_id is null then false
        else transaction_timestamp = first_seen_device_ts
    end as is_new_device,

    case
        when merchant_category is null then false
        else transaction_timestamp = first_seen_category_ts
    end as is_new_merchant_category,

    hour(transaction_timestamp) >= 23 or hour(transaction_timestamp) <= 4
        as is_night_transaction,

    case
        when prev_transaction_timestamp is null then null
        else round(
            (unix_timestamp(transaction_timestamp) - unix_timestamp(prev_transaction_timestamp)) / 60.0,
            2
        )
    end as time_since_last_txn_mins,

    is_fraud,
    fraud_type,
    fraud_scenario_id

from windowed