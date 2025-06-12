RUN=$1
Path=$(tail -n 1 /archive/Sequencing/*/$RUN/*checksum*.csv|tr -d \"|cut -d, -f2|sed "s/$RUN.*//")
echo $Path$RUN >> /ephemeral/datamover/log/finished.miseq.txt 
