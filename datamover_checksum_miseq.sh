RUNNAME=$1
BSP=$2
EMAIL=$3

if [ "$EMAIL" == "" ]
then
   EMAIL=data.manager@pirbright.ac.uk,sequencing.unit@pirbright.ac.uk
else
   EMAIL=data.manager@pirbright.ac.uk,sequencing.unit@pirbright.ac.uk,$EMAIL
fi

cd /ephemeral/datamover/miseq/$RUNNAME
#We will set correct permissions
find /ephemeral/datamover/miseq/$RUNNAME -type d|while read F;do echo $F;sudo chmod o+x "$F";done >/dev/null
sudo chmod -R o+r /ephemeral/datamover/miseq/$RUNNAME

cat *checksum.csv|grep -v '"Algorithm"'| cut -c7- |tr -d '"'|sed 's/,/  /g'|sed "s%[^ ]*$RUNNAME\\\%\\\%" |tr \\\\ / |tr A-Z a-z  |sort > /tmp/checksum.miseq.$RUNNAME.org
dos2unix /tmp/checksum.miseq.$RUNNAME.org
find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort > /tmp/checksum.miseq.$RUNNAME.tmp

#We calculated the checksums, we will compare them now
if cmp /tmp/checksum.miseq.$RUNNAME.tmp /tmp/checksum.miseq.$RUNNAME.org ;
then
  echo Checksum Successful
  echo $(wc -l /tmp/checksum.miseq.$RUNNAME.tmp) files checked
  if [ -e SampleSheet.csv ]
  then
     echo Run Name is $(grep ^Description SampleSheet.csv|awk -v FS=, '{print $2}')
  else
     echo No SampleSheet Found
  fi
  #Move file into the archive.
  if [ "$BSP" != "" ];
  then
     sudo mkdir -p /archive/Sequencing/$BSP
     sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/$BSP
     cd /archive/Sequencing/$BSP/$RUNNAME
     find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort > /tmp/checksum.miseq.$RUNNAME.archive
  else
     sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
     cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
     find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort > /tmp/checksum.miseq.$RUNNAME.archive
  fi
  if cmp /tmp/checksum.miseq.$RUNNAME.tmp /tmp/checksum.miseq.$RUNNAME.archive ;  then
     echo "File move was Successful!"
  else
     echo "File move Failed, Please check the archive"
  fi
else
  echo Checksum Failed
fi

