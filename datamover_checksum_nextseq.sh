#! /bin/bash
# Create the checksum of the current archive, ignore the existing checksum file
function checksum_archive()
{
    find .  -type f -exec md5sum {} \; |grep -Ev "checksum.?\.csv"|sed 's/ \./ /g'|sort
}
# Filter existing checksum file to a common format
function filter_checksumfile()
{
    cat *checksum*.csv |tr -d '"'|sed 's/,/  /g'|sed "s/[^ ]*$RUNNAME//" |grep -v "Hash  Path"|sort 
}
function Parse_SampleSheet()
{
    V=$(cat SampleSheet.csv |grep RunDescription|cut -f2- -d,) 
    BSP=$(echo $V|cut -f1 -d:|cut -f1 -d'_')
    EMAIL="$EMAIL,"$(echo $V|cut -f2 -d:|tr -d ' ')
}


RUNNAME=$1
BSP=$2
EMAIL=$3

if [ "$EMAIL" == "" ]
then
   EMAIL=data.manager@pirbright.ac.uk,sequencing.unit@pirbright.ac.uk
else
   EMAIL=data.manager@pirbright.ac.uk,sequencing.unit@pirbright.ac.uk,$EMAIL
fi

cd /ephemeral/datamover/nextseq/$RUNNAME
echo Changing permissions of the archive
find /ephemeral/datamover/nextseq/$RUNNAME -type d|while read F;do echo $F;sudo chmod o+x "$F";done >/dev/null
sudo chmod -R o+r /ephemeral/datamover/nextseq/$RUNNAME
echo Done

echo Creating checksum of the archive
filter_checksumfile > /tmp/checksum.nextseq.$RUNNAME.org
checksum_archive > /tmp/checksum.nextseq.$RUNNAME.tmp

echo Done

if cmp /tmp/checksum.nextseq.$RUNNAME.tmp /tmp/checksum.nextseq.$RUNNAME.org ;
then
 echo Checksum Successful
 echo $(wc -l /tmp/checksum.nextseq.$RUNNAME.tmp) files checked
 if [ -e SampleSheet.csv ]
 then
    Parse_SampleSheet  
    echo Run Name is $BSP and emails will be sent to $EMAIL 
 else
    echo No SampleSheet Found
 fi
 #Move file into the archive.
 if [ "$BSP" != "" ];
 then
	 sudo mkdir -p /archive/Sequencing/$BSP
	 sudo mv /ephemeral/datamover/nextseq/$RUNNAME /archive/Sequencing/$BSP
	 cd /archive/Sequencing/$BSP/$RUNNAME
 else
	 sudo mv /ephemeral/datamover/nextseq/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
	 cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
 fi
 checksum_archive > /tmp/checksum.nextseq.$RUNNAME.archive

 if cmp /tmp/checksum.nextseq.$RUNNAME.tmp /tmp/checksum.nextseq.$RUNNAME.archive ;
 then
    echo "your run $BSP:$RUNNAME was moved succssefully to /mnt/lustre/RDS-archive/Sequencing/$BSP/$RUNNAME"|mutt -s "$BSP:$RUNNAME Tranferred to the archive" $EMAIL
 else
    echo "Transfer failed. Please check this manually"|mutt -s "Data move failed $BSP:$RUN" data.manager@pirbright.ac.uk
 fi
else
  echo Checksum Failed
fi

