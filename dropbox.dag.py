from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
from airflow.operators.dummy import DummyOperator

non_resume_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 11, 29),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 0,
    'retry_delay': timedelta(seconds=5),
}

dag = DAG('dropbox_copy', default_args=non_resume_args, schedule=timedelta(minutes=10))

t1 = BashOperator(
    task_id='Copy_from_dropbox',
    bash_command='~/git/TPI_Data_Web/dropboxcopy.sh',
    dag=dag)

