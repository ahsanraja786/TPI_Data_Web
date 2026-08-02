#!/usr/bin/env bash
# Export Illumina run metadata and replace the matching Incidents_Detail row.

set -o pipefail

LOG_DIR="${ILLUMINATE_LOG_DIR:-/ephemeral/datamover/log}"
ILLUMINATE_BIN="${ILLUMINATE_BIN:-illuminate}"
MYSQL_BIN="${MYSQL_BIN:-mysql}"
MYSQL_DATABASE="${MYSQL_DATABASE:-Pirbright}"
ERROR_RECIPIENTS="data.manager@pirbright.ac.uk ahsan.riaz@pirbright.ac.uk chandana.tennakoon@pirbright.ac.uk"

EXPECTED_HEADER='BSP,RUN_NAME,ILLUMINA_RUN_ID,PLATFORM,INSTRUMENT_ID,RUN_NUMBER,RUN_DATE,RUN_STATUS,FLOWCELL_SERIAL,CARTRIDGE_SERIAL,EXPERIMENT_NAME,APPLICATION_NAME,RECIPE_NAME,RTA_VERSION,TOTAL_CYCLES,READ1_CYCLES,INDEX1_CYCLES,INDEX2_CYCLES,READ2_CYCLES,READ_TYPE,CONFIGURED_PHIX_PERCENT,OBSERVED_PHIX_PERCENT,TOTAL_CLUSTERS,PF_CLUSTERS,PF_PERCENT,TOTAL_CLUSTER_DENSITY,PF_CLUSTER_DENSITY,TOTAL_READ_PAIRS_OR_CLUSTERS,TOTAL_READ_ENDS,YIELD_GB,Q30_PERCENT,EXTRA_METADATA_JSON'

usage() {
    echo "Usage: $0 <numeric-bsp> <run-name> <run-directory> <database-path> <transfer-log>" >&2
}

send_error() {
    local message="$1"
    {
        echo "$message"
        echo
        echo "BSP: $BSPNO"
        echo "Run: $RUNNAME"
        echo "Metadata CSV: $METADATA_FILE"
        echo "Provenance CSV: $PROVENANCE_FILE"
        if [ -f "$TRANSFER_LOG" ]; then
            echo
            echo "Transfer log:"
            cat "$TRANSFER_LOG"
        fi
    } | mutt -s "Illumina metadata failed $BSPNO:$RUNNAME" $ERROR_RECIPIENTS
}

fail() {
    local message="$1"
    echo "ERROR: $message" >&2
    send_error "$message" || echo "ERROR: Could not send metadata failure email" >&2
    exit 1
}

sql_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\'/\\\'}
    printf '%s' "$value"
}

if [ "$#" -ne 5 ]; then
    usage
    exit 2
fi

BSPNO="$1"
RUNNAME="$2"
RUN_DIRECTORY="$3"
DATABASE_PATH="$4"
TRANSFER_LOG="$5"
METADATA_FILE="$LOG_DIR/BSP${BSPNO}_${RUNNAME}.metadata.csv"
PROVENANCE_FILE="$LOG_DIR/BSP${BSPNO}_${RUNNAME}.metadata.provenance.csv"

[[ "$BSPNO" =~ ^[0-9]+$ ]] || fail "BSP must be numeric; received '$BSPNO'"
[ -d "$RUN_DIRECTORY" ] || fail "Archived run directory does not exist: $RUN_DIRECTORY"
[ -d "$LOG_DIR" ] || fail "Log directory does not exist: $LOG_DIR"

"$ILLUMINATE_BIN" export \
    --bsp "$BSPNO" \
    --run-dir "$RUN_DIRECTORY" \
    --output "$METADATA_FILE" \
    --provenance-output "$PROVENANCE_FILE" || fail "illuminate export failed"

[ -s "$METADATA_FILE" ] || fail "illuminate did not create metadata CSV: $METADATA_FILE"
[ -s "$PROVENANCE_FILE" ] || fail "illuminate did not create provenance CSV: $PROVENANCE_FILE"

HEADER=$(head -n 1 "$METADATA_FILE" | tr -d '\r')
[ "$HEADER" = "$EXPECTED_HEADER" ] || fail "metadata CSV header does not match the Incidents_Detail import format"

ESCAPED_RUNNAME=$(sql_escape "$RUNNAME")
ESCAPED_DATABASE_PATH=$(sql_escape "$DATABASE_PATH")
ESCAPED_METADATA_FILE=$(sql_escape "$METADATA_FILE")

"$MYSQL_BIN" --local-infile=1 -u helpdesk -D "$MYSQL_DATABASE" -e "
START TRANSACTION;
DELETE FROM Incidents_Detail
 WHERE BSP = ${BSPNO} AND RUN_NAME = '${ESCAPED_RUNNAME}';
LOAD DATA LOCAL INFILE '${ESCAPED_METADATA_FILE}'
INTO TABLE Incidents_Detail
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' ESCAPED BY '\"'
LINES TERMINATED BY '\\n'
IGNORE 1 LINES
(@source_bsp, @source_run_name,
 ILLUMINA_RUN_ID, PLATFORM, INSTRUMENT_ID, RUN_NUMBER, RUN_DATE, RUN_STATUS,
 FLOWCELL_SERIAL, CARTRIDGE_SERIAL, EXPERIMENT_NAME, APPLICATION_NAME,
 RECIPE_NAME, RTA_VERSION, TOTAL_CYCLES, READ1_CYCLES, INDEX1_CYCLES,
 INDEX2_CYCLES, READ2_CYCLES, READ_TYPE, CONFIGURED_PHIX_PERCENT,
 OBSERVED_PHIX_PERCENT, TOTAL_CLUSTERS, PF_CLUSTERS, PF_PERCENT,
 TOTAL_CLUSTER_DENSITY, PF_CLUSTER_DENSITY, TOTAL_READ_PAIRS_OR_CLUSTERS,
 TOTAL_READ_ENDS, YIELD_GB, Q30_PERCENT, EXTRA_METADATA_JSON)
SET BSP = ${BSPNO}, RUN_NAME = '${ESCAPED_RUNNAME}', PATH = '${ESCAPED_DATABASE_PATH}';
COMMIT;
SHOW WARNINGS;" || fail "MySQL metadata import failed"

echo "SUCCESS: Imported Illumina metadata for BSP ${BSPNO}, run ${RUNNAME}"
