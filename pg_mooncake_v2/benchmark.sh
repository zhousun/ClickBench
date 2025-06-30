#!/bin/bash

set -eux

sudo apt-get update
sudo apt-get install -y docker.io

sudo apt-get install -y postgresql-client

memory=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
threads=$(nproc)
cpus=$(($threads / 2))
# Shared buffers is set to 25% of memory in AWS RDS by default. We do the same.
# https://docs.aws.amazon.com/prescriptive-guidance/latest/tuning-postgresql-parameters/shared-buffers.html
shared_buffers=$(($memory / 4))
# Effective cache size does not need to be perfect, but it should be somewhat
# close to the total memory minus what is expected to be used for queries.
# https://www.cybertec-postgresql.com/en/effective_cache_size-what-it-means-in-postgresql/
effective_cache_size=$(($memory - ($memory / 4)))
# By default, max_worker_processes is set to in postgres. We want to be able to
# use all the threads for parallel workers so we increase it. We also add a
# small buffer of 15 for any other background workers that might be created.
max_worker_processes=$(($threads + 15))
# Below we make sure to configure the rest of the parallel worker settings to
# match the number of cpu cores:
# https://www.crunchydata.com/blog/postgres-tuning-and-performance-for-analytics-data
#
# We also increase work_mem because we are doing an analytics workload to allow
# some more memory for sorting, aggregations, etc.
#
# It's necessary to increase max_wal_size to make the dataload not take very
# long. With the default value it's constantly checkpointing, and the PG logs
# warn you about that and tell you to increase max_wal_size.
sleep 2

sudo docker run -d --name pg_mooncake -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust mooncakelabs/pg_mooncake:17-v0.2-preview

sudo docker exec -it pg_mooncake bash -c "
cat >> /var/lib/postgresql/data/postgresql.conf <<'EOF'
shared_buffers=${shared_buffers}kB
max_worker_processes=${max_worker_processes}
max_parallel_workers=${threads}
max_parallel_maintenance_workers=${cpus}
max_parallel_workers_per_gather=${cpus}
max_wal_size=32GB
work_mem=64MB
effective_cache_size=${effective_cache_size}kB
EOF
"

sudo docker restart pg_mooncake

wget --continue 'https://datasets.clickhouse.com/hits_compatible/hits.tsv.gz'
gzip -d -f hits.tsv.gz

psql postgres://postgres:pg_mooncake@localhost:5432/postgres -f create.sql

time ./load.sh

# COPY 99997497
# Time: 2341543.463 ms (39:01.543)

./run.sh 2>&1 | tee log.txt

sudo docker exec -i pg_mooncake du -bcs /var/lib/postgresql/data

cat log.txt | grep -oP 'Time: \d+\.\d+ ms' | sed -r -e 's/Time: ([0-9]+\.[0-9]+) ms/\1/' |
    awk '{ if (i % 3 == 0) { printf "[" }; printf $1 / 1000; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'
