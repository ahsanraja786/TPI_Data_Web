RUNNAME=$1
BSP=$2
EMAIL=$3
if [ "$EMAIL" == "" ]
then
   EMAIL=data.manager@pirbright.ac.uk,sequencing.unit@pirbright.ac.uk
else
   EMAIL=data.manager@pirbright.ac.uk,sequencing.unit@pirbright.ac.uk,$EMAIL
fi

cd /ephemeral/datamover/nanopore/$RUNNAME
#We will set correct permissions
find /ephemeral/datamover/nanopore/$RUNNAME -type d|while read F;do echo $F;sudo chmod o+x "$F";done >/dev/null
sudo chmod -R o+r /ephemeral/datamover/nanopore/$RUNNAME

cat *checksum.csv|grep -v '"Algorithm"'| cut -c7- |tr -d '"'|sed 's/,/  /g'|sed "s%[^ ]*$RUNNAME\\\%\\\%" |tr \\\\ / |tr A-Z a-z  |sort > /tmp/checksum.nanopore.$RUNNAME.org
dos2unix /tmp/checksum.nanopore.$RUNNAME.org
find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort > /tmp/checksum.nanopore.$RUNNAME.tmp
echo Checksum Generated 
#We calculated the checksums, we will compare them now
if cmp /tmp/checksum.nanopore.$RUNNAME.tmp /tmp/checksum.nanopore.$RUNNAME.org ;
then
  echo Checksum Successful
  echo $(wc -l /tmp/checksum.nanopore.$RUNNAME.tmp) files checked
  #Move file into the archive.
  if [ "$BSP" != "" ];
  then
     sudo mkdir -p /archive/Sequencing/$BSP
     sudo mv /ephemeral/datamover/nanopore/$RUNNAME /archive/Sequencing/$BSP
     cd /archive/Sequencing/$BSP/$RUNNAME
     find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort > /tmp/checksum.nanopore.$RUNNAME.archive
  else
     sudo mv /ephemeral/datamover/nanopore/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
     cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
     find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort > /tmp/checksum.nanopore.$RUNNAME.archive
  fi
  if cmp /tmp/checksum.nanopore.$RUNNAME.tmp /tmp/checksum.nanopore.$RUNNAME.archive ;
  then
     
     echo "your run $BSP:$RUNNAME was moved succssefully to /mnt/lustre/RDS-archive/Sequencing/$BSP/$RUNNAME"|mutt -s "$BSP:$RUNNAME Tranferred to the archive" $EMAIL 
  else
     echo "Transfer failed. Please check this manually"|mutt -s "Data move failed $BSP:$RUN" data.manager@pirbright.ac.uk 
  fi
else
  echo Checksum Failed
fi
