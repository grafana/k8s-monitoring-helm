#!/bin/bash
set -eo pipefail

function metrics_query {
  echo "Running PromQL query: ${PROMETHEUS_URL}?query=${1}..."
  result=$(curl -skX POST -u "${PROMETHEUS_USER}:${PROMETHEUS_PASS}" "${PROMETHEUS_URL}" --data-urlencode "query=${1}")
  status=$(echo $result | jq -r .status)
  if [ "${status}" != "success" ]; then
    echo "Query failed!"
    echo "$result"
    exit 1
  fi

  resultCount=$(echo $result | jq '.data.result | length')
  if [ "${resultCount}" -eq 0 ]; then
    echo "Query returned no results"
    echo "$result"
    exit 1
  fi
}

function logs_query {
  echo "Running LogQL query: ${LOKI_URL}?query=${1}..."
  result=$(curl -s --get -H "X-Scope-OrgID:${LOKI_TENANTID}" -u "${LOKI_USER}:${LOKI_PASS}" "${LOKI_URL}" --data-urlencode "query=${1}")
  status=$(echo $result | jq -r .status)
  if [ "${status}" != "success" ]; then
    echo "Query failed!"
    echo "$result"
    exit 1
  fi

  resultCount=$(echo $result | jq '.data.result | length')
  if [ "${resultCount}" -eq 0 ]; then
    echo "Query returned no results"
    echo "$result"
    exit 1
  fi
}

count=$(jq -r ".queries | length-1" "${1}")
for i in $(seq 0 "${count}"); do
  query=$(jq -r --argjson i "${i}" '.queries[$i].query' "${1}")
  type=$(jq -r --argjson i "${i}" '.queries[$i] | .type // "promql"' "${1}")

  case "${type}" in
    promql)
      metrics_query "${query}"
      ;;
    logql)
      logs_query "${query}"
      ;;
    *)
      echo "Query type ${type} is not yet supported in this test"
      ;;
  esac
done

echo "All queries passed!"