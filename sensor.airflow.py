from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import datetime, timedelta

# Custom sensor imported here
from custom_sensors import DirectorySensor

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2024, 11, 29),
    'retries': 0,
    'retry_delay': timedelta(minutes=1),
}
    
dag = DAG('Download_Nextseq',catchup=False, default_args=default_args, schedule=timedelta(hours=20))

directory_sensor = DirectorySensor(
    task_id='sense_nextseq_directories',
    directory_path='/ephemeral/datamover/nextseq',
    poke_interval=60*30,
    timeout=19*60*60,
    dag=dag,
)

process_directory = BashOperator(
    retries = 8,
    retry_delay = timedelta(minutes=30),
    task_id='process_new_Nexseq_run',
    bash_command='~/airflow/bash/datamover_checksum_nextseq.sh {{ ti.xcom_pull(task_ids="sense_nextseq_directories", key="new_directory_name") }} ',
    dag=dag,
)

store_finished_path = BashOperator(
    retries = 8,
    retry_delay = timedelta(minutes=30),
    task_id='Store_Finished_Path',
    bash_command='~/airflow/bash/get_nextseq_path.sh {{ ti.xcom_pull(task_ids="sense_nextseq_directories", key="new_directory_name") }} ',
    dag=dag,
)

Trigger = TriggerDagRunOperator(
    task_id='Trigger_Sensor',
    trigger_dag_id=dag.dag_id,
    dag=dag,
)

directory_sensor >> process_directory >> store_finished_path >> Trigger
