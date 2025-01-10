# pg_mooncake

pg_mooncake is a Postgres extension that adds columnstore tables and vectorized execution (DuckDB). 

The extension is maintained by [Mooncake Labs](https://mooncake.dev)

- [repo](https://github.com/Mooncake-Labs/pg_mooncake/)
- [docs](https://pgmooncake.com/docs)

This benchmarks pg_mooncake `v0.1.0`.

## Run the benchmark. 

1. Spin up a `c6a.4xlarge` instance with Ubuntu Server 22.04 LTS, Root 500GB gp2 SSD, no EBS optimized. 
2. SSH into the instance and close repo. git clone `https://github.com/ClickHouse/ClickBench`.
3. Navigate to pg_mooncake directory. cd ClickBench/pg_mooncake. 
4. Run the benchmark via `./benchmark.sh`. 

For any questions, join our [slack](https://join.slack.com/t/mooncakelabs/shared_invite/zt-2sepjh5hv-rb9jUtfYZ9bvbxTCUrsEEA).
