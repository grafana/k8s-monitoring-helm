#!/bin/bash

if [ -z "${1}" ] || [ "${1}" == "-h" ]; then
  echo "USAGE: query-test.sh queries.json"
  echo "Run a set of queries against Prometheus, Loki, or Tempo"
  echo
  echo "Required environment variables:"
  echo "  If using any PromQL queries:"
  echo "  PROMETHEUS_URL - The query URL for your Prometheus service (e.g. localhost:9090/api/v1/query"
  echo "  PROMETHEUS_USER - The username for running PromQL queries"
  echo "  PROMETHEUS_PASS - The password for running PromQL queries"
  echo
  echo "  If using any LogQL queries:"
  echo "  LOKI_URL - The query URL for your Loki service (e.g. localhost:9090/api/v1/query"
  echo "  LOKI_USER - The username for running LogQL queries"
  echo "  LOKI_PASS - The password for running LogQL queries"
  echo
  echo "  If using any TraceQL queries:"
  echo "  TEMPO_URL - The query URL for your Tempo service (e.g. localhost:9090/api/v1/query"
  echo "  TEMPO_USER - The username for running TraceQL queries"
  echo "  TEMPO_PASS - The password for running TraceQL queries"
  echo
  echo "queries.json is the queries file, and should be in the format:"
  echo '{"queries": [<query>]}'
  echo
  echo "Each query has this format:"
  echo '{'
  echo '  "query": "<query string>",'
  echo '  "type": "[promql (default)|logql|traceql]",'
  echo '}'
  echo
  echo 'You can add an "expect" section to the query to validate the returned value'
  echo '  "expect": {'
  echo '    "operator": "[<, <=, ==, !=, =>, >]",'
  echo '    "value": <expected value>'
  echo '  }'
fi

function check_value {
  local actualValue=$1
  local expectedValue=$2
  local operator=$3

  set -x
  if test "! ${actualValue} ${operator} ${expectedValue}"; then
    echo "  Expected ${expectedValue} ${operator} ${expectedValue}"
    return 1
  fi
  set +x
  return 0
}

function metrics_query {
  if [ -z "${PROMETHEUS_URL}" ]; then
    echo "PROMETHEUS_URL is not defined. Unable to run PromQL queries!"
    return 1
  fi

  echo "Running PromQL query: ${PROMETHEUS_URL}?query=${1}..."
  result=$(curl -skX POST -u "${PROMETHEUS_USER}:${PROMETHEUS_PASS}" "${PROMETHEUS_URL}" --data-urlencode "query=${1}")
  status=$(echo "${result}" | jq -r .status)
  if [ "${status}" != "success" ]; then
    echo "Query failed!"
    echo "Response: ${result}"
    return 1
  fi

  resultCount=$(echo "${result}" | jq '.data.result | length')
  if [ "${resultCount}" -eq 0 ]; then
    echo "Query returned no results"
    echo "Result: ${result}"
    return 1
  fi

  if [ -n "${2}" ]; then
    check_value "$(echo "${result}" | jq -r '.data.result[0].value[1] | tostring')" "${2}" "${3}"
  fi
}

function logs_query {
  echo "Running LogQL query: ${LOKI_URL}?query=${1}..."
  result=$(curl -s --get -H "X-Scope-OrgID:${LOKI_TENANTID}" -u "${LOKI_USER}:${LOKI_PASS}" "${LOKI_URL}" --data-urlencode "query=${1}")
  status=$(echo "${result}" | jq -r .status)
  if [ "${status}" != "success" ]; then
    echo "Query failed!"
    echo "Response: ${result}"
    return 1
  fi

  resultCount=$(echo "${result}" | jq '.data.result | length')
  if [ "${resultCount}" -eq 0 ]; then
    echo "Query returned no results"
    echo "Result: ${result}"
    return 1
  fi
}

function traces_query {
  echo "Running TraceQL query: ${TEMPO_URL}?q=${1}..."
  result=$(curl -sk --get -u "${TEMPO_USER}:${TEMPO_PASS}" "${TEMPO_URL}" --data-urlencode "q=${1}")
  resultCount=$(echo "${result}" | jq '.traces | length')
  if [ "${resultCount}" -eq 0 ]; then
    echo "Query returned no results"
    echo "Result: ${result}"
    return 1
  fi
}

count=$(jq -r ".queries | length-1" "${1}")
for i in $(seq 0 "${count}"); do
  query=$(jq -r --argjson i "${i}" '.queries[$i].query' "${1}")
  type=$(jq -r --argjson i "${i}" '.queries[$i] | .type // "promql"' "${1}")
  expectedValue=$(jq -r --argjson i "${i}" '.queries[$i].expect.value | tostring' "${1}")
  expectedOperator=$(jq -r --argjson i "${i}" '.queries[$i].expect | .operator // "=="' "${1}")

  case "${type}" in
    promql)
      if ! metrics_query "${query}" "${expectedValue}" "${expectedOperator}"; then
        exit 1
      fi
      ;;
    logql)
      if ! logs_query "${query}"; then
        exit 1
      fi
      ;;
    traceql)
      if ! traces_query "${query}"; then
        exit 1
      fi
      ;;
    *)
      echo "Query type ${type} is not yet supported in this test"
      exit 1
      ;;
  esac
done

echo "All queries passed!"