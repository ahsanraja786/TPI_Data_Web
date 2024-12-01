#Authentication token in /mnt/lustre/RDS-live/tennakoon/.config/dbxcli/auth.json
Log() 
{
    local level="$1"
    shift
    local message="$@"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$level] $message" 
}
function Parse_Name()
{
    local F=$(echo $1|sed "s/.email//g"|tr -d /)
    BSP=$(echo $F|cut -f1 -d"@")
    RUN=$(echo $F|cut -f2 -d"@")
    FILENAME=$(echo $F|cut -f3 -d"@")
}

function Email()
{
   local F=$1
   Log INFO emailing with "$F" 
   Parse_Name "$F"
   if [ -e /archive/Sequencing/$BSP/${RUN}_Metadata/$FILENAME ]
   then
       Log SUCCESS Move successful
       dbx get "$F"
       EMAIL=$(cat "$F")
       echo -e  "BSP: $BSP \n RUN: $RUN \n File: $FILENAME \n was recently added to \n /archive/Sequencing/$BSP/${RUN}_Metadata/$FILENAME"  |mutt -s "$BSP:$RUN New file added" $EMAIL
       Log INFO removing $F
       rm "$F"
       dbx rm "$F"
   else
       Log ERROR Missing metadata file 
   fi
}

ADMIN_EMAIL=chandana.tennakoon@pirbright.ac.uk

exec > >(tee -a /ephemeral/datamover/log/dropboxmove.log) 2>&1
dbx ls > /tmp/dbxlist
echo|cat /tmp/dbxlist -|grep -v email|tr -d /|while read F;
do
    if [ "$F" != "" ];
    then
       Log INFO moving "$F" 
       Parse_Name "$F"
       Log INFO BSP: $BSP, RUN: $RUN, File: $FILENAME
       dbx get "$F"
       if mv "$F" /archive/Sequencing/$BSP/${RUN}_Metadata/$FILENAME
       then
           Log SUCCESS Move successful
           echo -e  "BSP: $BSP \n RUN: $RUN \n File: $FILENAME \n was recently added to \n /archive/Sequencing/$BSP/${RUN}_Metadata/$FILENAME"  |mutt -s "$BSP:$RUN New file added" $ADMIN_EMAIL
           Log INFO removing $F
           dbx rm "$F"
       else
           Log ERROR Move failed
           echo BSP: $BSP, RUN: $RUN, File: $FILENAME |mutt -s "$BSP:$RUN:$FILENAME failed move" $ADMIN_EMAIL
       fi
    fi
done

echo|cat /tmp/dbxlist -|grep email|tr -d /|while read F;
do
    if [ "$F" != "" ];
    then
       Email $F 
    fi
done
