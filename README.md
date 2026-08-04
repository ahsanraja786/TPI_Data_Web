# TPI_Data_Web
Need to install the illuminate package, currently it is at:
/mnt/lustre/RDS-live/datamover/illuminate
installed to the venv:
/mnt/lustre/RDS-live/datamover/venv/illuminate/bin/illuminate

## Testing `import_illumina_metadata.sh`

The helper exports an Illumina run with `illuminate` and imports one row into
`Incidents_Detail`. It replaces an existing row with the same BSP and run name.

## Illumina metadata reports

`export_illumina_metadata.sh` reads one imported Illumina row from
`Incidents_Detail` and writes a two-column `DESCRIPTION,VALUE` CSV. It contains
one row for each of the 31 reporting fields, using the supplied human-readable
description and its database value. It also emails that CSV to the sequencing
unit, Chandana Tennakoon, and the data manager. Both MiSeq and NextSeq transfer
scripts run it after their metadata import completes.

The helper can also be run manually:

```bash
MYSQL_DATABASE=Pirbright ./export_illumina_metadata.sh 123 run-name /tmp/BSP123_run-name.illumina-metadata.csv
```
Use a copied test run and a test database; do not use a production BSP/run name
for testing.

Prerequisites:

- `illuminate`, `mysql`, and `mutt` are available to the account running the test.
- The test database has an `Incidents_Detail` table with the production schema and
  contains the test BSP in `Incidents`.
- The account's MySQL configuration can connect as `helpdesk` and allows
  `LOCAL INFILE`.

Run the test from this repository, replacing the example values with a real
copied Illumina run and an unused BSP/run combination:

```bash
mkdir -p /tmp/illumina-metadata-test/log

ILLUMINATE_LOG_DIR=/tmp/illumina-metadata-test/log \
MYSQL_DATABASE=Pirbright_test \
./import_illumina_metadata.sh \
  123 \
  test-run \
  /path/to/copied/illumina-run \
  /mnt/lustre/RDS-archive/Sequencing/BSP123/test-run \
  /tmp/illumina-metadata-test/transfer.log
```

Confirm the metadata and provenance files were created, then query the test
database:

```bash
ls -l /tmp/illumina-metadata-test/log/BSP123_test-run.*
mysql -u helpdesk -D Pirbright_test -e "
  SELECT BSP, RUN_NAME, PATH, ILLUMINA_RUN_ID, PLATFORM, EXTRA_METADATA_JSON
  FROM Incidents_Detail
  WHERE BSP = 123 AND RUN_NAME = 'test-run';"
```

The helper defaults to the production `Pirbright` database and
`/ephemeral/datamover/log` when `MYSQL_DATABASE` and `ILLUMINATE_LOG_DIR` are
not set. Leave those defaults unchanged for the deployed transfer scripts.
