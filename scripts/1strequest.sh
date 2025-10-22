#!/bin/bash

thisdir=$(dirname "$0")

# defaults
RATE=200
ITERS=1
JAR=""
THREADS=2
PROC=8
CONNECTIONS=100
DURATION=30s
XMS=512m
XMX=512m
JVM_ARGS_APPEND=""

# parse args (first non-option is the jar)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rate) RATE="$2"; shift 2 ;;
    --rate=*) RATE="${1#*=}"; shift ;;
    --iters) ITERS="$2"; shift 2 ;;
    --iters=*) ITERS="${1#*=}"; shift ;;
    --threads) THREADS="$2"; shift 2 ;;
    --threads=*) THREADS="${1#*=}"; shift ;;
    --proc) PROC="$2"; shift 2 ;;
    --proc=*) PROC="${1#*=}"; shift ;;
    --connections) CONNECTIONS="$2"; shift 2 ;;
    --connections=*) CONNECTIONS="${1#*=}"; shift ;;
    --duration) DURATION="$2"; shift 2 ;;
    --duration=*) DURATION="${1#*=}"; shift ;;
    --xms) XMS="$2"; shift 2 ;;
    --xms=*) XMS="${1#*=}"; shift ;;
    --xmx) XMX="$2"; shift 2 ;;
    --xmx=*) XMX="${1#*=}"; shift ;;
    --jvmArgsAppend) JVM_ARGS_APPEND="$2"; shift 2 ;;
    --jvmArgsAppend=*) JVM_ARGS_APPEND="${1#*=}"; shift ;;
    --help|-h) echo "Usage: $0 <jar-file> [--rate N] [--iters N] [--threads N] [--proc N] [--connections N] [--duration DURATION] [--xms SIZE] [--xmx SIZE] [--jvmArgsAppend ARGS]"; exit 0 ;;
    --*) echo "Unknown option $1" >&2; exit 1 ;;
    *) if [[ -z "$JAR" ]]; then JAR="$1"; shift; else echo "Unexpected argument: $1" >&2; exit 1; fi ;;
  esac
done

if [[ -z "${JAR}" ]]; then
  echo "Usage: $0 <jar-file> [--rate N] [--iters N] [--threads N] [--proc N] [--connections N] [--duration DURATION] [--xms SIZE] [--xmx SIZE] [--jvmArgsAppend ARGS]" >&2
  exit 1
fi

# make sure the port is clear before enabling halting-on-error
kill $(lsof -t -i:8080) &>/dev/null || true

set -euo pipefail

${thisdir}/infra.sh -s
java -XX:ActiveProcessorCount=${PROC} -Xms${XMS} -Xmx${XMX} ${JVM_ARGS_APPEND} -jar "${JAR}" &
JAVA_PID=$!

echo "-----------------------------------------"
echo "Starting application (pid=${JAVA_PID})"
echo "-----------------------------------------"

printf "Waiting for the application to respond at http://localhost:8080"
# wait until any HTTP response is received (connect succeeds)
until curl -sS http://localhost:8080 >/dev/null 2>&1; do
  printf "."
  sleep 0.5
done
echo " First Request succeeded!"

for i in $(seq 1 "${ITERS}"); do
  echo "-----------------------------------------"
  echo "Starting test run ${i}/${ITERS} (rate=${RATE}, threads=${THREADS}, connections=${CONNECTIONS}, duration=${DURATION})"
  echo "-----------------------------------------"
  jbang wrk2@hyperfoil -t"${THREADS}" -c"${CONNECTIONS}" -d"${DURATION}" -R "${RATE}" http://localhost:8080/fruits
done

${thisdir}/infra.sh -d

kill "${JAVA_PID}" &>/dev/null || true
kill $(lsof -t -i:8080) &>/dev/null || true