# Credit Risk & Fraud Detection — Databricks + dbt Cloud

![Databricks](https://img.shields.io/badge/Databricks-FF3621?style=for-the-badge&logo=databricks&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-00ADD8?style=for-the-badge&logo=delta&logoColor=white)
![Apache Spark](https://img.shields.io/badge/Apache%20Spark-E25A1C?style=for-the-badge&logo=apachespark&logoColor=white)
![MLflow](https://img.shields.io/badge/MLflow-0194E2?style=for-the-badge&logo=mlflow&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

> **Hybrid Lakehouse** — Databricks handles raw ingestion and ML; dbt Cloud owns all transformation logic from staging through silver dimensions, fact tables, and gold KPIs. Orchestrated end-to-end via a Databricks Workflows DAG that triggers dbt Cloud jobs and blocks on their success before proceeding to ML training.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Data Flow](#data-flow)
- [dbt Model Layers](#dbt-model-layers)
  - [Staging](#staging)
  - [Intermediate](#intermediate)
  - [Silver Marts](#silver-marts)
  - [Gold Marts](#gold-marts)
  - [Snapshots](#snapshots)
- [ML Pipeline](#ml-pipeline)
- [Orchestration](#orchestration)
- [dbt Tests](#dbt-tests)
- [Key Results](#key-results)
- [Design Decisions](#design-decisions)
- [Limitations](#limitations)

---

## Overview

This project extends a production-grade credit risk Lakehouse by introducing **dbt Cloud as the transformation layer** between raw Bronze Delta tables and the ML pipeline. The result is a clean separation of concerns:

| Responsibility | Tool |
|---|---|
| Raw ingestion | Databricks Auto Loader |
| Schema repair | Databricks Workflows For Each |
| Transformation logic | dbt Cloud |
| Data quality enforcement | dbt tests (generic + singular) |
| SCD Type 2 history | dbt Snapshots |
| ML training | Databricks (XGBoost + LightGBM) |
| Experiment tracking | MLflow + UC Model Registry |
| Orchestration | Databricks Workflows DAG |
| dbt job triggering | `trigger_dbt_build.py` (dbt Cloud API) |

### Simulation

730-day Indian banking simulation across 10,000 customers:

| Metric | Value |
|---|---|
| Total transactions | 20,299,749 |
| Fraud transactions | 148 (0.3% incidence) |
| Loan applications | 7,334 |
| Portfolio default rate | ~15% |
| Raw data size | 1.86 GB |
| Bronze tables | 15 |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SIMULATION ENGINE                               │
│         Python · 3 State Machines · 730-day backfill · IST-aware       │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │  Parquet → Databricks Volume
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    DATABRICKS — BRONZE LAYER                            │
│        Auto Loader · foreachBatch · Cast Recovery · Schema Repair      │
│                      15 Delta tables                                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │  bronze.* Delta tables
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       dbt Cloud — STAGING                               │
│              17 views · type casting · column renaming                  │
│              source freshness · generic + singular tests                │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     dbt Cloud — INTERMEDIATE                            │
│   dq_violations · int_loan_status_jumps · int_transactions_features    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                          ┌──────┴──────┐
                          ▼             ▼
           ┌──────────────────┐  ┌──────────────────────┐
           │  SILVER MARTS    │  │    GOLD MARTS         │
           │  5 dimensions    │  │  4 KPI tables         │
           │  3 fact tables   │  │  materialized: table  │
           │  mat: table      │  └──────────────────────┘
           └────────┬─────────┘
                    │  silver.* + gold.* Delta tables
                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    DATABRICKS — ML PIPELINE                             │
│     XGBoost Fraud Classifier · LightGBM Default Predictor              │
│     Optuna HPO · MLflow · UC Model Registry · Batch Scoring            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Category | Technology |
|---|---|
| Platform | Databricks (Serverless + Unity Catalog) |
| Transformation | dbt Cloud (dbt-databricks adapter) |
| Storage | Delta Lake |
| Ingestion | Auto Loader (`cloudFiles`), `foreachBatch` |
| Orchestration | Databricks Workflows DAG |
| dbt Triggering | dbt Cloud API (`trigger_dbt_build.py`) |
| ML Training | XGBoost, LightGBM, Optuna |
| ML Tracking | MLflow, UC Model Registry |
| Version Control | Git + Databricks Repos |

---

## Project Structure

```
credit-risk-fraud-detection/
│
├── dbt_project.yml                  ← dbt project config, materialization rules
├── packages.yml                     ← dbt packages (dbt_utils, dbt_expectations)
├── trigger_dbt_build.py             ← dbt Cloud API trigger + polling script
│
├── models/
│   ├── staging/                     ← 17 views, one per bronze source table
│   │   ├── sources.yml              ← declares bronze.* as dbt sources
│   │   ├── staging.yml              ← column tests for all staging models
│   │   ├── stg_transactions.sql
│   │   ├── stg_customers.sql
│   │   ├── stg_loan_applications.sql
│   │   ├── stg_bureau_pulls.sql
│   │   ├── stg_underwriting_decisions.sql
│   │   ├── stg_disbursements.sql
│   │   ├── stg_repayment_schedules.sql
│   │   ├── stg_repayment_events.sql
│   │   ├── stg_nach_bounces.sql
│   │   ├── stg_cdc_loan_status.sql
│   │   ├── stg_cdc_customer_updates.sql
│   │   ├── stg_credit_profiles.sql
│   │   ├── stg_kyc_profiles.sql
│   │   ├── stg_credit_card_detail.sql
│   │   ├── stg_loan_personal_detail.sql
│   │   ├── stg_loan_home_detail.sql
│   │   └── stg_loan_auto_detail.sql
│   │
│   ├── intermediate/                ← 3 intermediate views + DQ violations
│   │   ├── intermediate.yml
│   │   ├── dq_violations.sql        ← unified DQ violation capture
│   │   ├── int_loan_status_jumps.sql← detects invalid DPD state transitions
│   │   └── int_transactions_features.sql ← pre-aggregated fraud signals
│   │
│   └── marts/
│       ├── silver/                  ← 8 Delta tables (dimensions + facts)
│       │   ├── dim_loan_account.sql
│       │   ├── dim_credit_card.sql
│       │   ├── dim_loan_personal.sql
│       │   ├── dim_loan_home.sql
│       │   ├── dim_loan_auto.sql
│       │   ├── fct_transactions.sql
│       │   ├── fct_repayment_events.sql
│       │   └── fct_nach_bounces.sql
│       │
│       └── gold/                    ← 4 KPI Delta tables
│           ├── kpi_npa_by_persona.sql
│           ├── kpi_portfolio_default_rate.sql
│           ├── kpi_fraud_incidence.sql
│           └── kpi_dq_violation_summary.sql
│
├── snapshots/                       ← SCD Type 2 via dbt snapshots → silver schema
│
├── macros/                          ← reusable SQL macros
├── tests/                           ← singular + custom dbt tests
├── seeds/                           ← reference data
├── analyses/                        ← ad-hoc SQL analyses
├── sql/                             ← raw SQL utilities
│
├── 01_bronze/                       ← Databricks notebooks (Auto Loader ingestion)
└── 04_ml/                           ← Databricks notebooks (ML pipeline)
```

---

## Data Flow

```
bronze.transactions          →  stg_transactions
                                      ↓
                             int_transactions_features   ← pre-agg fraud signals
                                      ↓
                             silver.fct_transactions     ← cleaned fact table

bronze.cdc_loan_status       →  stg_cdc_loan_status
                                      ↓
                             int_loan_status_jumps       ← detects invalid transitions
                                      ↓
                             snapshots (SCD Type 2)      → silver schema

bronze.loan_applications     →  stg_loan_applications
bronze.underwriting_decisions→  stg_underwriting_decisions
                                      ↓
                             silver.dim_loan_account     ← joined dimension

All staging models           →  dq_violations            ← unified DQ capture
                                      ↓
                             gold.kpi_dq_violation_summary

silver.* + gold.*            →  Databricks ML notebooks  ← feature engineering
                                      ↓
                             XGBoost fraud classifier
                             LightGBM default predictor
```

---

## dbt Model Layers

### Staging

**17 views** — one per bronze source table. Responsibilities:

```
- Declare all bronze.* tables as dbt sources (sources.yml)
- Rename columns to consistent snake_case conventions
- Cast types where needed (coerces any remaining type issues)
- Apply column-level generic tests: not_null, unique, accepted_values
- No business logic — pure cleaning and aliasing
```

| Model | Source | Key transformations |
|---|---|---|
| `stg_transactions` | bronze.transactions | Fraud signal passthrough, amount validation |
| `stg_customers` | bronze.customers | PAN format, DOB validation |
| `stg_loan_applications` | bronze.loan_applications | FOIR range, applied_amount coercion |
| `stg_bureau_pulls` | bronze.bureau_pulls | CIBIL range enforcement (300-900) |
| `stg_underwriting_decisions` | bronze.underwriting_decisions | Null handling for REJECTED rows |
| `stg_cdc_loan_status` | bronze.cdc_loan_status | Before/after field typing |
| `stg_cdc_customer_updates` | bronze.cdc_customer_updates | Income change typing |
| `stg_repayment_events` | bronze.repayment_events | Payment category derivation |
| `stg_nach_bounces` | bronze.nach_bounces | Return code validation |
| `stg_disbursements` | bronze.disbursements | IFSC format validation |
| `stg_repayment_schedules` | bronze.repayment_schedules | Amortization validation |
| `stg_credit_card_detail` | bronze.credit_card_detail | Utilisation ratio range |
| `stg_kyc_profiles` | bronze.customers | KYC-specific columns |
| `stg_credit_profiles` | bronze.customers | Credit profile columns |
| `stg_loan_personal_detail` | bronze.loan_personal_detail | Insurance premium casting |
| `stg_loan_home_detail` | bronze.loan_home_detail | LTV, co-applicant income |
| `stg_loan_auto_detail` | bronze.loan_auto_detail | Vehicle depreciation |

---

### Intermediate

**3 views + DQ violations** — business logic and cross-table enrichment.

#### `dq_violations.sql`
Unified DQ violation capture across all staging models. Every violation from every source lands in one place with violation type, source table, and raw payload — queryable for audit and governance.

#### `int_loan_status_jumps.sql`
Detects **invalid DPD state transitions** in the CDC stream:
```
Valid:   CURRENT → 30_DPD → 60_DPD → 90_DPD → NPA
Invalid: CURRENT → 90_DPD (skipped intermediate states)
         30_DPD  → CURRENT without cure event
```
State jump violations are flagged, logged to DQ, and excluded from silver dimensions.

#### `int_transactions_features.sql`
Pre-aggregates behavioral fraud signals per customer per day:
```
- velocity_1hr, velocity_24hr
- amount_vs_30d_avg_ratio
- distance_from_home_km
- is_new_device, is_night_transaction
- merchant_risk_score
```
These flow into `silver.fct_transactions` and directly into the ML feature engineering step.

---

### Silver Marts

**8 Delta tables** — materialized as `table` in the `silver` schema. Star schema design: 5 dimensions + 3 facts.

#### Dimensions

| Model | Description |
|---|---|
| `dim_loan_account` | Core loan dimension — disbursed amount, EMI, NACH status, maturity date |
| `dim_credit_card` | Credit card dimension — limit, utilisation band, billing cycle, revolving APR |
| `dim_loan_personal` | Personal loan attributes — purpose, insurance, prepayment terms |
| `dim_loan_home` | Home loan attributes — LTV ratio, property value, co-applicant income, RERA |
| `dim_loan_auto` | Auto loan attributes — vehicle details, on-road price, depreciation |

#### Facts

| Model | Description | Key metrics |
|---|---|---|
| `fct_transactions` | Cleaned transaction fact — 20M+ rows | Fraud label, velocity signals, geo distance |
| `fct_repayment_events` | Monthly EMI outcomes | is_missed, days_late, DPD, salary credited |
| `fct_nach_bounces` | NACH auto-debit failures | Return reason, consecutive bounce count, balance shortfall |

---

### Gold Marts

**4 KPI Delta tables** — business intelligence layer, materialized as `table` in the `gold` schema.

| Model | Business Question |
|---|---|
| `kpi_npa_by_persona` | What is the NPA rate and provision requirement by customer persona? |
| `kpi_portfolio_default_rate` | What is the month-on-month default rate across the loan portfolio? |
| `kpi_fraud_incidence` | How many fraud transactions occurred by type, channel, and month? |
| `kpi_dq_violation_summary` | How many DQ violations exist per source table and violation type? |

---

### Snapshots

dbt Snapshots implement **SCD Type 2** for slowly changing entities. Targets the `silver` schema.

```sql
-- Snapshot strategy: timestamp
-- Unique key: customer_id / loan_account_id
-- Updated_at column triggers new version row
-- Full history preserved: every state, every transition date
```

Enables point-in-time queries:
```sql
-- What was this customer's employment status on 2024-06-15?
SELECT * FROM silver.customers_snapshot
WHERE customer_id = 'CUS_00001234'
AND dbt_valid_from <= '2024-06-15'
AND (dbt_valid_to > '2024-06-15' OR dbt_valid_to IS NULL)
```

---

## ML Pipeline

Same models as the Databricks-only version, now reading from dbt-built silver tables.

### Model 1 — Fraud Detector (XGBoost)

| Parameter | Value |
|---|---|
| Training source | `silver.fct_transactions` (via dbt) |
| Features | 16 pre-computed behavioral signals |
| Class imbalance | 1:135,000 → `scale_pos_weight` |
| HPO | Optuna, 50 trials, TPE sampler |
| PR-AUC | 1.0 *(simulation artifact — see Limitations)* |
| Registry | `credit_risk_lakehouse.ml_models.fraud_detector@champion` |

### Model 2 — Default Predictor (LightGBM)

| Parameter | Value |
|---|---|
| Training source | Silver dims + facts (via dbt) |
| Features | 25 point-in-time correct loan-month features |
| Default rate | 15% |
| HPO | Optuna, 50 trials |
| ROC-AUC | 0.80 |
| KS Statistic | 0.47 |
| Registry | `credit_risk_lakehouse.ml_models.default_predictor@champion` |

### Top Default Predictors (SHAP)

```
total_bounces (NACH)             0.697  ← leading indicator
consecutive_missed_running       0.403
persona_encoded                  0.402
current_monthly_income           0.367
had_insufficient_funds           0.279
max_dpd_ever (bureau)            0.259
```

---

## Orchestration

The Databricks Workflow DAG bridges Databricks and dbt Cloud:

```
verify_environment
        │
        ├── [FAILED] → setup_environment
        │
        └── [AT_LEAST_ONE_SUCCESS]
                    ↓
          bronze_ingestion_v2 (Auto Loader)
                    │
          bronze_schema_repair
          (For Each · 7 tables · concurrency 4)
                    │
                    ↓
          trigger_dbt_build          ← Python script task
          (dbt Cloud API call)       ← polls until SUCCESS or FAIL
          (30-min timeout cap)       ← blocks downstream tasks
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
    fraud_model_train   default_model_train   (parallel)
          │                    │
          └─────────┬──────────┘
                    ▼
              batch_scoring
```

### `trigger_dbt_build.py`

The key integration piece. A Python script task in the Workflow that:

```python
# 1. Triggers the dbt Cloud Silver/Gold job via REST API
# 2. Polls every 15 seconds for job status
# 3. Returns success → ML tasks proceed
#    Returns failure → Workflow marks task FAILED, ML tasks skip
# 4. 30-minute timeout safety cap

# dbt Cloud job runs:
#   dbt run --select staging intermediate marts
#   dbt test --select staging intermediate marts
#   dbt snapshot
```

This pattern ensures the ML layer **never trains on stale or failed transformation output.**

---

## dbt Tests

Three categories of tests enforced across all model layers:

### Generic Tests (schema.yml)

```yaml
# Applied across staging and marts
- not_null:      primary keys, foreign keys, critical amounts
- unique:        transaction_id, application_id, bureau_pull_id
- accepted_values:
    loan_type:   [PERSONAL, HOME, AUTO, CREDIT_CARD]
    persona:     [PRIME, NEAR_PRIME, SUBPRIME, STRESSED]
    decision:    [APPROVED, REJECTED]
    __change_type: [INSERT, UPDATE]
- relationships: FK integrity between fact and dimension tables
```

### Singular Tests (tests/)

```sql
-- No negative transaction amounts in fact table
-- CIBIL scores within valid range (300-900)
-- EMI amount > 0 for all repayment schedule rows
-- Disbursed amount matches approved amount ± tolerance
-- No future-dated transactions beyond simulation end
-- DPD values non-negative
```

### Custom Macros (macros/)

Reusable test logic abstracted into macros — applied consistently across tables without copy-paste SQL.

---

## Key Results

| Metric | Value |
|---|---|
| Bronze tables | 15 |
| dbt Staging models | 17 (views) |
| dbt Intermediate models | 4 (views) |
| dbt Silver mart models | 8 (tables) |
| dbt Gold mart models | 4 (tables) |
| dbt Snapshots | SCD Type 2 on key entities |
| dbt Tests | Generic + singular + custom |
| Default model ROC-AUC | 0.80 |
| Default model KS | 0.47 |
| Fraud model PR-AUC | 1.0 (simulation artifact) |
| Optuna trials per model | 50 |
| MLflow tracked models | 2 (@champion aliases) |

---

## Design Decisions

**Why dbt Cloud over dbt Core?**
dbt Cloud provides a managed scheduler, a web IDE for model development, lineage graph UI, and a job API — all accessible on the free tier. The dbt Cloud job API is what `trigger_dbt_build.py` calls to block the Databricks DAG on transformation success.

**Why staging as views, silver/gold as tables?**
Staging views add zero storage cost and always reflect the latest bronze data. Silver and gold are materialised as tables because the ML pipeline and BI layer need fast, pre-computed reads — not repeated joins across 20M+ bronze rows at query time.

**Why intermediate models?**
Three cross-cutting concerns don't belong in staging (too early) or silver (too embedded):
- DQ violations span all sources — one intermediate model captures them all
- Loan status jump detection requires joining CDC events — intermediate layer
- Transaction feature aggregations are expensive — compute once in intermediate, reuse in silver and ML

**Why dbt Snapshots for SCD Type 2?**
dbt's `snapshot` command handles the SCD Type 2 pattern natively — it adds `dbt_valid_from`, `dbt_valid_to`, and `dbt_scd_id` columns automatically. No manual MERGE INTO logic needed. The snapshot targets the `silver` schema, making historical records available for point-in-time ML feature joins.

**Why poll dbt Cloud from Databricks instead of scheduling separately?**
The ML training tasks depend on transformation success. If dbt fails halfway, training on partial silver tables produces incorrect models. Polling from `trigger_dbt_build.py` inside the Databricks Workflow creates a hard dependency — ML only runs on confirmed, fully-built, test-passing transformation output.

---

## Limitations

| Limitation | Reason | Production Path |
|---|---|---|
| Fraud model PR-AUC = 1.0 | Simulation artifact — deterministic signal injection | Real data would yield ~0.85-0.92 PR-AUC |
| dbt API token hardcoded in `trigger_dbt_build.py` | Dev convenience | Replace with `dbutils.secrets.get(scope, key)` before committing |
| No dbt Cloud CI/CD | Free tier limitation | Add dbt Cloud Slim CI job on PR with `dbt build --select state:modified+` |
| No Model Serving | Serverless plan limitation | Deploy @champion via MLflow REST endpoint on paid tier |
| 33K default training observations | Simulation window | Production portfolio generates millions of loan-month rows |
| No Feature Store | `databricks.feature_engineering` requires paid tier | Register silver fact tables as Feature Store tables |

---



---

*Databricks · dbt Cloud · Delta Lake · Unity Catalog · MLflow · XGBoost · LightGBM · Optuna*
