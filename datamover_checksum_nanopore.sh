#! /bin/bash
# Log output properly
Log() 
{
    local level="$1"
    shift
    local message="$@"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$level] $message" 
}
# Create the checksum of the current archive, ignore the existing checksum file
function checksum_archive()
{
    find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort
}
# Filter existing checksum file to a common format
function filter_checksumfile()
{
    cat *checksum.csv|grep -v '"Algorithm"'| cut -c7- |tr -d '"'|sed 's/,/  /g'|sed "s%[^ ]*$RUNNAME\\\%\\\%" |tr \\\\ / |tr A-Z a-z  |sort
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

#Redirect outputs to a log
exec > >(tee /ephemeral/datamover/log/nanopore.$RUNNAME.log) 2>&1

cd /ephemeral/datamover/nanopore/$RUNNAME
#We will set correct permissions
Log INFO Changing permissions of the archive
find /ephemeral/datamover/nanopore/$RUNNAME -type d|while read F;do echo $F;sudo chmod o+x "$F";done >/dev/null
sudo chmod -R o+r /ephemeral/datamover/nanopore/$RUNNAME
Log SUCCESS Done

Log INFO Creating checksum of the archive
filter_checksumfile > /tmp/checksum.nanopore.$RUNNAME.org
dos2unix /tmp/checksum.nanopore.$RUNNAME.org
checksum_archive > /tmp/checksum.nanopore.$RUNNAME.tmp
Log SUCCESS Done

#We calculated the checksums, we will compare them now
if cmp /tmp/checksum.nanopore.$RUNNAME.tmp /tmp/checksum.nanopore.$RUNNAME.org ;
then
  Log INFO Transfer and Original Checksum Match
  Log INFO $(wc -l /tmp/checksum.nanopore.$RUNNAME.tmp) files checked
  #Move file into the archive.
  if [ "$BSP" != "" ];
  then
     Log INFO moving the transfer to the archive
     sudo mkdir -p /archive/Sequencing/$BSP
     sudo mv /ephemeral/datamover/nanopore/$RUNNAME /archive/Sequencing/$BSP
     cd /archive/Sequencing/$BSP/$RUNNAME
     Log INFO Move complete
  else
     Log INFO moving the transfer to Datamover_withoutBSP
     sudo mv /ephemeral/datamover/nanopore/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
     cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
     Log INFO Move complete
  fi
  checksum_archive > /tmp/checksum.nanopore.$RUNNAME.archive
  if cmp /tmp/checksum.nanopore.$RUNNAME.tmp /tmp/checksum.nanopore.$RUNNAME.archive ;
  then
     Log SUCCESS Transfer was successful
     echo "your run $BSP:$RUNNAME was moved succssefully to /mnt/lustre/RDS-archive/Sequencing/$BSP/$RUNNAME"|mutt -s "$BSP:$RUNNAME Transferred to the archive" $EMAIL 
  else
     Log ERROR Checsums of transfers do not match  
     echo "Transfer failed. Please check this manually"|mutt -s "Data move failed $BSP:$RUN" data.manager@pirbright.ac.uk 
  fi
else
  Log ERROR Checksum Failed
fi
