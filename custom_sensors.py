import os
from airflow.sensors.base import BaseSensorOperator
from airflow.utils.decorators import apply_defaults

class DirectorySensor(BaseSensorOperator):
    @apply_defaults
    def __init__(self, directory_path, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.directory_path = directory_path

    def poke(self, context):
        current_directories = os.listdir("/ephemeral/datamover/nextseq")
        print(current_directories)
        for Dir in current_directories:
            Base = os.path.basename(Dir)
            if os.path.exists("/ephemeral/datamover/log/airflow."+Base):
                print("Polled "+ Base)
            else:
                open("/ephemeral/datamover/log/airflow."+Base,"w")
                context['ti'].xcom_push(key='new_directory_name', value=Base)
                return True
        return False 

