from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

# Define the variable for the number of days
CLEANUP_DAYS = 7

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'cleanup_airflow_db',
    default_args=default_args,
    description='Cleanup Airflow metadata older than a configurable number of days',
    schedule_interval='@weekly',  # Run weekly
    start_date=datetime(2024, 12, 7),
    catchup=False,
) as dag:

    cleanup_task = BashOperator(
        task_id='cleanup_old_records',
        bash_command=f'airflow db clean --clean-before {CLEANUP_DAYS}d;find ~/airflow/logs/ -type f -mtime +{CLEANUP_DAYS} -delete',
    )

    cleanup_task
