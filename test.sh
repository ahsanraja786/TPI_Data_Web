
mkdir -p /tmp/illumina-metadata-test/log
BSP=BSP414
ILLUMINATE_LOG_DIR=/tmp/illumina-metadata-test/log \
./import_illumina_metadata.sh \
  802 \
  260202_M02063_0362_000000000-M6WF7 \
  /archive/Sequencing/$BSP/260202_M02063_0362_000000000-M6WF7 \
  /mnt/lustre/RDS-archive/Sequencing/$BSP/260202_M02063_0362_000000000-M6WF7 \
  /tmp/illumina-metadata-test/transfer.log


echo "==============================================================================="
echo                                      VERIFY
echo "==============================================================================="

ls -l /tmp/illumina-metadata-test/log/BSP800_260202_M02063_0362_000000000-M6WF7.*
mysql -u helpdesk -D Pirbright -e " SELECT BSP, RUN_NAME, PATH, ILLUMINA_RUN_ID, PLATFORM, EXTRA_METADATA_JSON FROM Incidents_Detail WHERE BSP = 802 AND RUN_NAME = '260202_M02063_0362_000000000-M6WF7';"
