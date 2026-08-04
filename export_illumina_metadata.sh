#!/usr/bin/env bash
# Export one Illumina metadata row from Incidents_Detail as a CSV report.

set -euo pipefail

MYSQL_BIN="${MYSQL_BIN:-mysql}"
MYSQL_DATABASE="${MYSQL_DATABASE:-Pirbright}"
REPORT_RECIPIENTS="sequencing.unit@pirbright.ac.uk chandana.tennakoon@pirbright.ac.uk data.manager@pirbright.ac.uk"

HEADER='DESCRIPTION,VALUE'

usage() {
    echo "Usage: $0 <numeric-bsp> <run-name> <output-csv>" >&2
}

sql_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\'/\\\'}
    printf '%s' "$value"
}

csv_value() {
    # Return a MySQL expression that always produces one RFC 4180 CSV field.
    local column="$1"
    printf "CONCAT(CHAR(34), REPLACE(REPLACE(REPLACE(COALESCE(CAST(%s AS CHAR), ''), CHAR(34), CONCAT(CHAR(34), CHAR(34))), CHAR(13), ' '), CHAR(10), ' '), CHAR(34))" "$column"
}

if [ "$#" -ne 3 ]; then
    usage
    exit 2
fi

BSPNO="$1"
RUNNAME="$2"
OUTPUT_FILE="$3"

if ! [[ "$BSPNO" =~ ^[0-9]+$ ]]; then
    echo "ERROR: BSP must be numeric; received '$BSPNO'" >&2
    exit 2
fi

OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory does not exist: $OUTPUT_DIR" >&2
    exit 2
fi

ESCAPED_RUNNAME=$(sql_escape "$RUNNAME")
COLUMNS=(
    BSP RUN_NAME ILLUMINA_RUN_ID PLATFORM INSTRUMENT_ID RUN_NUMBER RUN_DATE
    RUN_STATUS FLOWCELL_SERIAL CARTRIDGE_SERIAL EXPERIMENT_NAME APPLICATION_NAME
    RECIPE_NAME RTA_VERSION TOTAL_CYCLES READ1_CYCLES INDEX1_CYCLES INDEX2_CYCLES
    READ2_CYCLES READ_TYPE CONFIGURED_PHIX_PERCENT OBSERVED_PHIX_PERCENT
    TOTAL_CLUSTERS PF_CLUSTERS PF_PERCENT TOTAL_CLUSTER_DENSITY PF_CLUSTER_DENSITY
    TOTAL_READ_PAIRS_OR_CLUSTERS TOTAL_READ_ENDS YIELD_GB Q30_PERCENT
)
DESCRIPTIONS=(
    'User-supplied BSP identifier'
    'Run directory name'
    'Internal Illumina run identifier'
    'Detected sequencing platform'
    'Instrument identifier'
    'Instrument run number'
    'Run date as recorded by the instrument'
    'Complete, in progress, or unknown'
    'Flow-cell serial or barcode'
    'Reagent cartridge serial or barcode'
    'Experiment name'
    'Run application/workflow name'
    'Recipe name'
    'Real-Time Analysis software version'
    'Total cycles including index reads'
    'Read 1 cycles'
    'Index 1 cycles'
    'Index 2 cycles'
    'Read 2 cycles'
    'SINGLE_END or PAIRED_END'
    'Configured PhiX spike-in, when recorded'
    'PF clusters aligned to PhiX'
    'Total cluster count'
    'Passing-filter cluster count'
    'Clusters passing filter'
    'Total cluster density'
    'Passing-filter cluster density'
    'Clusters (read pairs for paired-end runs)'
    'Clusters multiplied by biological read count'
    'Estimated sequencing yield'
    'Bases at or above Q30'
)

QUERY=''
for index in "${!COLUMNS[@]}"; do
    description=${DESCRIPTIONS[$index]}
    escaped_description=$(sql_escape "$description")
    if [ -n "$QUERY" ]; then
        QUERY+=' UNION ALL '
    fi
    QUERY+="SELECT CONCAT(CHAR(34), '${escaped_description}', CHAR(34), ',', $(csv_value "${COLUMNS[$index]}")) FROM Incidents_Detail WHERE BSP = ${BSPNO} AND RUN_NAME = '${ESCAPED_RUNNAME}'"
done
QUERY+=';'

TEMP_FILE=$(mktemp "${OUTPUT_FILE}.tmp.XXXXXX")
trap 'rm -f "$TEMP_FILE"' EXIT
printf '%s\n' "$HEADER" > "$TEMP_FILE"

"$MYSQL_BIN" --batch --skip-column-names --raw -u helpdesk -D "$MYSQL_DATABASE" -e "$QUERY" >> "$TEMP_FILE"

if [ "$(wc -l < "$TEMP_FILE")" -ne 32 ]; then
    echo "ERROR: Expected 31 metadata values for BSP ${BSPNO}, run ${RUNNAME}" >&2
    exit 1
fi

mv "$TEMP_FILE" "$OUTPUT_FILE"
trap - EXIT
echo "SUCCESS: Exported Illumina metadata report to $OUTPUT_FILE"

if command -v mutt >/dev/null 2>&1; then
    printf 'Attached is the Illumina metadata CSV report for BSP %s, run %s.\n' "$BSPNO" "$RUNNAME" \
        | mutt -s "Illumina metadata report ${BSPNO}:${RUNNAME}" -a "$OUTPUT_FILE" -- $REPORT_RECIPIENTS
    echo "SUCCESS: Sent Illumina metadata report to $REPORT_RECIPIENTS"
else
    echo "ERROR: mutt is required to send the Illumina metadata report" >&2
    exit 1
fi
