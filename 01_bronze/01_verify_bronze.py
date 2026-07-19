"""
verify_bronze.py

Databricks Workflow task (Python script task type, NOT a notebook).
Verifies the Unity Catalog objects required before Bronze ingestion can run:
  - catalog: credit_risk_fraud_detection
  - schema:  bronze

Idempotent: if an object already exists, does nothing. If missing, creates it.
Exits 0 on success (whether things already existed or were just created),
non-zero on any failure -- the Workflow DAG gates the downstream
`ingest_bronze` notebook task on this task succeeding.
"""

import sys
from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import NotFound

CATALOG_NAME = "credit_risk_fraud_detection"
SCHEMA_NAME = "bronze"


def catalog_exists(w: WorkspaceClient, name: str) -> bool:
    try:
        w.catalogs.get(name)
        return True
    except NotFound:
        return False


def schema_exists(w: WorkspaceClient, catalog: str, schema: str) -> bool:
    try:
        w.schemas.get(full_name=f"{catalog}.{schema}")
        return True
    except NotFound:
        return False


def main() -> None:
    w = WorkspaceClient()

    print(f"Verifying catalog '{CATALOG_NAME}'...")
    if catalog_exists(w, CATALOG_NAME):
        print("  OK - catalog already exists")
    else:
        print(f"  MISSING - creating catalog '{CATALOG_NAME}'")
        w.catalogs.create(name=CATALOG_NAME)
        print("  Created.")

    print(f"Verifying schema '{CATALOG_NAME}.{SCHEMA_NAME}'...")
    if schema_exists(w, CATALOG_NAME, SCHEMA_NAME):
        print("  OK - schema already exists")
    else:
        print(f"  MISSING - creating schema '{CATALOG_NAME}.{SCHEMA_NAME}'")
        w.schemas.create(name=SCHEMA_NAME, catalog_name=CATALOG_NAME)
        print("  Created.")

    print("Bronze environment verified.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"ERROR: bronze environment verification failed: {e}", file=sys.stderr)
        sys.exit(1)