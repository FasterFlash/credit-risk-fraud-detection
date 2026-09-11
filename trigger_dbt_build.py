"""
trigger_dbt_build.py
Databricks Workflow task (Python script type).
Triggers the dbt Cloud "Silver/Gold build" job via the dbt Cloud API and
blocks until it finishes -- polling for success/failure -- so downstream
ML training tasks only run against a build that actually succeeded.

TEMPORARY: API_TOKEN is hardcoded below for local testing only.
Before committing this file to git, replace it with:
    API_TOKEN = dbutils.secrets.get(scope="dbt_cloud", key="api_token")
"""

import sys
import time
import requests

DBT_CLOUD_ACCOUNT_ID = "70506183133215"
DBT_CLOUD_JOB_ID = "70506183135626"
DBT_CLOUD_BASE_URL = "https://uh882.us1.dbt.com"

POLL_INTERVAL_SECONDS = 15
TIMEOUT_SECONDS = 1800   # 30 min safety cap

API_TOKEN = "dbtc_vvLJPOcp452ZXBDLyuE-JgZdJ9wDuBtmGDeiqk5uiTQsmGHhbo"   # TEMP -- do not commit

HEADERS = {"Authorization": f"Token {API_TOKEN}"}


def trigger_run() -> int:
    url = f"{DBT_CLOUD_BASE_URL}/api/v2/accounts/{DBT_CLOUD_ACCOUNT_ID}/jobs/{DBT_CLOUD_JOB_ID}/run/"
    resp = requests.post(url, headers=HEADERS, json={"cause": "Triggered from Databricks Workflow"})
    resp.raise_for_status()
    run_id = resp.json()["data"]["id"]
    print(f"Triggered dbt Cloud run {run_id}")
    return run_id


def poll_run(run_id: int) -> str:
    url = f"{DBT_CLOUD_BASE_URL}/api/v2/accounts/{DBT_CLOUD_ACCOUNT_ID}/runs/{run_id}/"
    elapsed = 0
    while elapsed < TIMEOUT_SECONDS:
        resp = requests.get(url, headers=HEADERS)
        resp.raise_for_status()
        status = resp.json()["data"]["status"]
        status_humanized = resp.json()["data"]["status_humanized"]
        print(f"  run {run_id} status: {status_humanized}")

        if status == 10:
            return "success"
        if status in (20, 30):
            return "failed"

        time.sleep(POLL_INTERVAL_SECONDS)
        elapsed += POLL_INTERVAL_SECONDS

    return "timeout"


def main():
    run_id = trigger_run()
    result = poll_run(run_id)
    if result != "success":
        raise Exception(f"dbt Cloud run {run_id} did not succeed (result: {result})")
    print("dbt Cloud build succeeded.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)