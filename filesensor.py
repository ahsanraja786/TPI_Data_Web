#system sensor method
from airflow import DAG
from airflow.sensors.filesystem import FileSensor
from airflow.operators.dummy import DummyOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

with DAG(
    'sense_new_directories',
    default_args=default_args,
    schedule_interval=None,  # Triggered by the sensor itself
    start_date=datetime(2023, 1, 1),
    catchup=False,
) as dag:
    # Dummy task to run after sensing the directory
    process_task = DummyOperator(task_id="process_directory")
    
    # Sensor to detect the new directory
    sense_directory = FileSensor(
        task_id='sense_new_directory',
        filepath='/path/to/parent_directory/new_directory_name',
        fs_conn_id='fs_default',  # Filesystem connection configured in Airflow
        poke_interval=60,  # Check every 60 seconds
        timeout=3600,  # Timeout after 1 hour
    )

    sense_directory >> process_task

