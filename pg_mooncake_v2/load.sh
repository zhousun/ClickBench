#!/bin/bash

set -eux
CONNECTION=postgres://postgres:pg_mooncake@localhost:5432/postgres

# Load data: wrap TRUNCATE and \copy FREEZE in a single transaction
# If we dont' do this, Postgres will throw an error:
#     "ERROR: cannot perform COPY FREEZE because the table was not created or truncated in the current subtransaction"
# (i.e. Postgres requires that the table be either created or truncated in the current subtransaction)
time psql $CONNECTION <<'EOF'
BEGIN;
TRUNCATE TABLE hits_row_store;
\copy hits_row_store FROM 'hits.tsv' with freeze;
COMMIT;
EOF
