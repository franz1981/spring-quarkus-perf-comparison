#!/bin/bash

thisdir=$(dirname "$0")

WRK_SETTINGS="--timeout 2s --threads 2 --connections 10 --duration 30s --rate 200"
JVM_PARAMS="-XX:ActiveProcessorCount=8 -Xms512m -Xmx512m"
WAIT_SERVER=${WAIT_SERVER:-true}

# if no jar is provided as argument, exit and complain
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <path-to-jar>"
  exit 1
fi

# make sure the port is clear before enabling halting-on-error
kill $(lsof -t -i:8080) &>/dev/null || true

set -euo pipefail

${thisdir}/infra.sh -s
java ${JVM_PARAMS} -jar $1 &

if [ "$WAIT_SERVER" = "true" ]; then
echo "Waiting for server to be ready..."
# wait until any HTTP response is received (connect succeeds)
until curl -sS http://localhost:8080 >/dev/null 2>&1; do
  sleep 0.5
done
fi

echo "-----------------------------------------"
echo "Starting wrk2"
echo "-----------------------------------------"

jbang wrk2@hyperfoil ${WRK_SETTINGS} http://localhost:8080/fruits

echo "-----------------------------------------"
echo "Stopped wrk2"
echo "-----------------------------------------"

# Kill the Java process (listening on 8080)
kill -TERM $(lsof -t -i:8080) &>/dev/null || true
${thisdir}/infra.sh -d
