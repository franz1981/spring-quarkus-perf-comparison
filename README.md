# spring-quarkus-perf-comparison
Performance comparison between Spring Boot and Quarkus

This project contains the following modules:
- [springboot3](springboot3)
    - A Spring Boot 3.x version of the application
- [quarkus3](quarkus3)
    - A Quarkus 3.x version of the application
- [quarkus3-spring-compatibility](quarkus3-spring-compatibility)
    - A Quarkus 3.x version of the application using the Spring compatibility layer
 
## Building

`./mvnw clean verify -Dquarkus.hibernate-orm.sql-load-script=import.sql`

## Application requirements/dependencies
             
- (macOS) You need to have a `timeout` compatible command:
  - Via `coreutils` (installed via Homebrew): `brew install coreutils` but note that this will install lots of GNU utils that will duplicate native commands and prefix them with `g` (e.g. `gdate`)
  - Use [this implementation](https://github.com/aisk/timeout) via Homebrew: `brew install aisk/homebrew-tap/timeout`
  - More options at https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x

- Base JVM Version: 21

The application expects a PostgreSQL database to be running on localhost:5432. You can use Docker or Podman to start a PostgreSQL container:

```shell
cd scripts
./infra.sh -s
```

This will start the database, create the required tables and populate them with some data.

To stop the database:

```shell
cd scripts
./infra.sh -d
```

## Scripts

There are some [scripts](scripts) available to help you run the application:
- [`1strequest.sh`](scripts/1strequest.sh)
    - Runs an application X times and computes the time to 1st request and RSS for each iteration as well as an average over the X iterations.
- [`run-requests.sh`](scripts/run-requests.sh)
    - Runs a set of requests against a running application.
- [`infra.sh`](scripts/infra.sh)
    - Starts/stops required infrastructure 

## Running performance comparisons

Of course you want to start generating some numbers and doing some comparisons, that's why you're here! 
There are lots of *wrong* ways to run benchmarks, and running them reliably requires a controlled environment, strong automation, and multiple machines.
Realistically, that kind of setup isn't always possible. 

Here's a range of options, from easiest to best practice. 
Remember that the easy setup will *not* be particularly accurate, but it does sidestep some of the worst pitfalls of casual benchmarking.


### Quick and dirty: Single laptop, simple scripts

Before we go any further, know that this kind of test is not going to be reliable. 
Laptops usually have a number of other processes running on them, and modern laptop CPUs are subject to power management which can wildly skew results. 
Often, some cores are 'fast' and some are 'slow', and without extra care, you don't know which core your test is running on. 
Thermal management also means 'fast' jobs get throttled, while 'slow' jobs might run at their normal speed.

Load shouldn't be generated on the same machine as the one running the workload, because the work of load generation can interfere with what's being measured. 

But if you accept all that, and know these results should be treated with caution, here's our recommendation for the least-worst way of running a quick and dirty test. 
We use [Hyperfoil](https://hyperfoil.io/https://hyperfoil.io/) instead of [wrk](https://github.com/wg/wrk), to avoid [coordinated omission](https://redhatperf.github.io/post/coordinated-omission/) issues. For simplicity, we use the [wrk2](https://github.com/giltene/wrk2) Hyperfoil bindings. 

You can run these in any order. 

```shell
scripts/stress.sh quarkus3/target/quarkus-app/quarkus-run.jar
scripts/stress.sh quarkus3-spring-compatibility/target/quarkus-app/quarkus-run.jar
scripts/stress.sh springboot3/target/springboot3.jar
```

For each test, you should see output like 

```shell
  6001 requests in 30.002s,   4.84MB read
Requests/sec: 200.02
Transfer/sec: 165.29kB
```
### Acceptable: Run on a single machine, with solid automation and detailed output

These scripts are being developed.

### The best: Run tests in a controlled lab

These tests are run on a regular schedule in Red Hat/IBM performance labs.
The results are available in an internal [Horreum](https://github.com/Hyperfoil/Horreum) instance. 
We are working on publishing these externally.




