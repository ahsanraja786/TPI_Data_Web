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
cat *checksum*.csv |tr -d '"'|sed 's/,/  /g'|sed "s/[^ ]*$RUNNAME//" |grep -v "Hash  Path"|sort > /tmp/checksum.nextseq.$RUNNAME.org
find .  -type f -exec md5sum {} \; |grep -v checksums.csv|sed 's/ \./ /g'|sort > /tmp/checksum.nextseq.$RUNNAME.tmp
echo Done

if cmp /tmp/checksum.nextseq.$RUNNAME.tmp /tmp/checksum.nextseq.$RUNNAME.org ;
then
 echo Checksum Successful
 echo $(wc -l /tmp/checksum.nextseq.$RUNNAME.tmp) files checked
 if [ -e SampleSheet.csv ]
 then
    echo Run Name is $(grep RunDescription SampleSheet.csv|awk -v FS=, '{print $2}')
 else
    echo No SampleSheet Found
 fi
 #Move file into the archive.
 if [ "$BSP" != "" ];
 then
	 sudo mkdir -p /archive/Sequencing/$BSP
	 sudo mv /ephemeral/datamover/nextseq/$RUNNAME /archive/Sequencing/$BSP
	 cd /archive/Sequencing/$BSP/$RUNNAME
         find .  -type f -exec md5sum {} \; |grep -v checksums.csv|sed 's/ \./ /g'|sort > /tmp/checksum.nextseq.$RUNNAME.archive
 else
	 sudo mv /ephemeral/datamover/nextseq/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
	 cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
         find .  -type f -exec md5sum {} \; |grep -v checksums.csv|sed 's/ \./ /g'|sort > /tmp/checksum.nextseq.$RUNNAME.archive
 fi
 if cmp /tmp/checksum.nextseq.$RUNNAME.tmp /tmp/checksum.nextseq.$RUNNAME.archive ;
 then
    echo "your run $BSP:$RUNNAME was moved succssefully to /mnt/lustre/RDS-archive/Sequencing/$BSP/$RUNNAME"|mutt -s "$BSP:$RUNNAME Tranferred to the archive" $EMAIL
 else
    echo "Transfer failed. Please check this manually"|mutt -s "Data move failed $BSP:$RUN" data.manager@pirbright.ac.uk
 fi
else
  echo Checksum Failed
fi

