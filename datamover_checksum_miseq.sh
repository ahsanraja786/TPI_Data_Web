#! /bin/bash
<<<<<<< HEAD
# Log output properly
Log()
=======
Log() 
>>>>>>> cf8fd9c1cc9d7c0cdfb82cf44294e5319b7ae74f
{
    local level="$1"
    shift
    local message="$@"
<<<<<<< HEAD
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$level] $message"
=======
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$level] $message" 
>>>>>>> cf8fd9c1cc9d7c0cdfb82cf44294e5319b7ae74f
}
# Create the checksum of the current archive, ignore the existing checksum file
function checksum_archive()
{
<<<<<<< HEAD
    find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort
=======
    find . -type f -exec md5sum {} \; |grep -v checksum.csv|sed 's/ \./ /g'|tr A-Z a-z|sort 
>>>>>>> cf8fd9c1cc9d7c0cdfb82cf44294e5319b7ae74f
}
# Filter existing checksum file to a common format
function filter_checksumfile()
{
    cat *checksum.csv|grep -v '"Algorithm"'| cut -c7- |tr -d '"'|sed 's/,/  /g'|sed "s%[^ ]*$RUNNAME\\\%\\\%" |tr \\\\ / |tr A-Z a-z  |sort
}
<<<<<<< HEAD
=======
function Parse_SampleSheet()
{
    V=$(cat SampleSheet.csv|dos2unix |grep ^Description|cut -f2- -d,) 
    BSP=$(echo $V|cut -f1 -d" " |cut -f1 -d'_')
    EMAIL="$EMAIL,"$(echo $V|cut -f2- -d" "|sed "s/^ *//g"|tr -s " " ,)
}

>>>>>>> cf8fd9c1cc9d7c0cdfb82cf44294e5319b7ae74f

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
exec > >(tee /ephemeral/datamover/log/miseq.$RUNNAME.log) 2>&1

<<<<<<< HEAD
cd /ephemeral/datamover/miseq/$RUNNAME
#We will set correct permissions
Log INFO Changing permissions of the archive
find /ephemeral/datamover/miseq/$RUNNAME -type d|while read F;do echo $F;sudo chmod o+x "$F";done >/dev/null
sudo chmod -R o+r /ephemeral/datamover/miseq/$RUNNAME
Log SUCCESS Done

Log INFO Creating checksum of the archive
filter_checksumfile > /tmp/checksum.miseq.$RUNNAME.org
dos2unix /tmp/checksum.miseq.$RUNNAME.org
checksum_archive > /tmp/checksum.miseq.$RUNNAME.tmp
Log SUCCESS Done

#We calculated the checksums, we will compare them now
if cmp /tmp/checksum.miseq.$RUNNAME.tmp /tmp/checksum.miseq.$RUNNAME.org ;
then
  Log INFO Transfer and Original Checksum Match
  Log INFO $(wc -l /tmp/checksum.miseq.$RUNNAME.tmp) files checked
  #Move file into the archive.
  if [ "$BSP" != "" ];
  then
     Log INFO moving the transfer to the archive
     sudo mkdir -p /archive/Sequencing/$BSP
     sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/$BSP
     cd /archive/Sequencing/$BSP/$RUNNAME
     Log INFO Move complete
  else
     Log INFO moving the transfer to Datamover_withoutBSP
     sudo mkdir -p /archive/Sequencing/$BSP
     sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/$BSP
     cd /archive/Sequencing/$BSP/$RUNNAME
     Log INFO Move complete
  else
     Log INFO moving the transfer to Datamover_withoutBSP
     sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
     cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
     Log INFO Move complete
  fi
  checksum_archive > /tmp/checksum.miseq.$RUNNAME.archive
  if cmp /tmp/checksum.miseq.$RUNNAME.tmp /tmp/checksum.miseq.$RUNNAME.archive ;
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
  
=======
#Redirect outputs to a log
exec > >(tee /ephemeral/datamover/log/miseq.$RUNNAME.log) 2>&1
if [ ! -d "/ephemeral/datamover/miseq/$RUNNAME" ];
then
    Log ERROR "Invalid Run name : $RUNNAME"
else
    cd /ephemeral/datamover/miseq/$RUNNAME
    #We will set correct permissions
    Log INFO Changing permissions of the archive
    find /ephemeral/datamover/miseq/$RUNNAME -type d|while read F;do echo $F;sudo chmod o+x "$F";done >/dev/null
    sudo chmod -R o+r /ephemeral/datamover/miseq/$RUNNAME
    Log SUCCESS Done

    Log INFO Creating checksum of the archive
    filter_checksumfile > /tmp/checksum.miseq.$RUNNAME.org
    dos2unix /tmp/checksum.miseq.$RUNNAME.org
    checksum_archive > /tmp/checksum.miseq.$RUNNAME.tmp
    Log SUCCESS Done

    if cmp /tmp/checksum.miseq.$RUNNAME.tmp /tmp/checksum.miseq.$RUNNAME.org ;
    then
        Log INFO Transfer and Original Checksum Match
        Log INFO  $(wc -l /tmp/checksum.miseq.$RUNNAME.tmp) files checked
        if [ -e SampleSheet.csv ]
        then
            Log INFO Sample sheet present 
            Parse_SampleSheet  
            Log INFO Run Name is $BSP and emails will be sent to $EMAIL 
        else
            Log ERROR No SampleSheet Found
        fi

        #Move file into the archive.
        if [ "$BSP" != "" ];
        then
            Log INFO moving the tranfer to the archive
            sudo mkdir -p /archive/Sequencing/$BSP
            sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/$BSP
            sudo mkdir -p /archive/Sequencing/$BSP/${RUNNAME}_Metadata
            sudo chown datamover:datamover /archive/Sequencing/$BSP/${RUNNAME}_Metadata
            cd /archive/Sequencing/$BSP/$RUNNAME
            Log INFO Move complete
        else
            Log INFO moving the tranfer to Datamover_withoutBSP
            sudo mv /ephemeral/datamover/miseq/$RUNNAME /archive/Sequencing/Datamover_withoutBSP
            cd /archive/Sequencing/Datamover_withoutBSP/$RUNNAME
            Log INFO Move complete
        fi

        checksum_archive > /tmp/checksum.miseq.$RUNNAME.archive
        if cmp /tmp/checksum.miseq.$RUNNAME.tmp /tmp/checksum.miseq.$RUNNAME.archive ;
        then
            Log SUCCESS Transfer was successful
            echo "your run $BSP:$RUNNAME was moved succssefully to /mnt/lustre/RDS-archive/Sequencing/$BSP/$RUNNAME"|mutt -s "$BSP:$RUNNAME Transferred to the archive" $EMAIL
        else
            Log ERROR Checksums of transfers do not match  
            echo "Transfer failed. Please check this manually"| cat - /ephemeral/datamover/log/miseq.$RUNNAME.log |mutt -s "Data move failed $BSP:$RUN" data.manager@pirbright.ac.uk
        fi
    else
        Log ERROR Checksum Failed
    fi
fi
>>>>>>> cf8fd9c1cc9d7c0cdfb82cf44294e5319b7ae74f
