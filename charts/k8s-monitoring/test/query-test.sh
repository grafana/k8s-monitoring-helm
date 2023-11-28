#!/bin/bash

function metrics_query {
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

  case "${type}" in
    promql)
      if ! metrics_query "${query}"; then
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