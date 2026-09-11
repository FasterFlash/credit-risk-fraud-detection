
from databricks_langchain import ChatDatabricks, UCFunctionToolkit
from langgraph.prebuilt import create_react_agent
import mlflow

catalog = "credit_risk_fraud_detection"
FOUNDATION_MODEL_ENDPOINT = "databricks-meta-llama-3-3-70b-instruct"

llm = ChatDatabricks(endpoint=FOUNDATION_MODEL_ENDPOINT, temperature=0.1)

toolkit = UCFunctionToolkit(
    function_names=[
        f"{catalog}.ml.get_loan_risk_score",
        f"{catalog}.ml.get_loan_risk_factors",
        f"{catalog}.ml.get_fraud_score",
        f"{catalog}.ml.get_portfolio_summary",
        f"{catalog}.ml.get_dq_summary",
    ]
)
tools = toolkit.tools

SYSTEM_PROMPT = (
    "You are a credit risk and fraud analyst assistant for a lending portfolio. "
    "You have tools to: (1) look up a loan is delinquency escalation risk score "
    "and its risk factors given a loan_account_id, (2) look up a transaction is "
    "fraud probability given a transaction_id, (3) retrieve overall portfolio "
    "KPIs (default rate, fraud incidence, NPA by persona), and (4) retrieve a "
    "summary of current data quality violations in the pipeline. "
    "Use whichever tools are relevant to the question asked -- call multiple "
    "tools if the question has multiple parts. Be concise and factual: only "
    "state what the tool data actually supports, never invent numbers."
)

agent = create_react_agent(llm, tools, prompt=SYSTEM_PROMPT)

mlflow.models.set_model(agent)
