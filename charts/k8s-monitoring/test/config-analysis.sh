#!/bin/bash

set -eo pipefail

AGENT_HOST="${AGENT_HOST:-http://localhost:8080}"
sources=$1

function discoveryRelabel() {
    local component=$1
    echo "  Discovery phase:"
    details=$(curl --get --silent --show-error "${AGENT_HOST}/api/v0/web/components/${component}")
    echo "    Component: ${component}"
    jq -r '"    Inputs: \(.referencesTo[0]) (\(.arguments[0].value.value | length))"' <(echo "${details}")
    jq -r '"    Outputs: \(.referencedBy[0]) (\(.exports[0].value.value | length))"' <(echo "${details}")
}

function prometheusScrape() {
    local component=$1
    echo "  Scrape phase:"
    details=$(curl --get --silent --show-error "${AGENT_HOST}/api/v0/web/components/${component}")
    echo "    Component: ${component}"

    inputCount=$(jq -r '.arguments[] | select(.name == "targets") | .value.value | length' <(echo "${details}"))
    echo "    Inputs: ${inputCount}"
    if [ "${inputCount}" -gt 0 ]; then
        for i in $(seq 1 "${inputCount}"); do
            jq -r --argjson i "${i}" '"    - \(.arguments[] | select(.name == "targets") | .value.value[$i-1].value[] | select(.key == "__address__") | .value.value)"' <(echo "${details}")
        done
    fi

    targetCount=$(jq -r '.debugInfo | length' <(echo "${details}"))
    echo "    Scrapes: ${targetCount}"
    if [ "${targetCount}" -gt 0 ]; then
        for i in $(seq 1 "${targetCount}"); do
            jq -r --argjson i "${i}" '"    - URL: \(.debugInfo[$i-1].body[] | select(.name == "url") | .value.value)"' <(echo "${details}")
            jq -r --argjson i "${i}" '"      Health: \(.debugInfo[$i-1].body[] | select(.name == "health") | .value.value)"' <(echo "${details}")
            jq -r --argjson i "${i}" '"      Last scrape: \(.debugInfo[$i-1].body[] | select(.name == "last_scrape") | .value.value) (\(.debugInfo[0].body[] | select(.name == "last_scrape_duration") | .value.value))"' <(echo "${details}")
            jq -r --argjson i "${i}" '"      Scrape error: \(.debugInfo[$i-1].body[] | select(.name == "last_error") | .value.value)"' <(echo "${details}")
        done
    fi
}

if [ -z "${AGENT_HOST}" ]; then
    echo "AGENT_HOST is not defined. Please set AGENT_HOST to the Grafana Agent host."
    exit 1
fi

if ! curl --get --silent --show-error "${AGENT_HOST}/api/v0/web/components" > /dev/null; then
    echo "Failed to send a request to the Agent. Check that AGENT_HOST is set correctly."
    exit 1
fi

systemCount=$(jq -r length-1 "${sources}")
for i in $(seq 0 "${systemCount}"); do
    jq -r --argjson i "${i}" '.[$i].name' "${sources}"

    componentCount=$(jq -r --argjson i "${i}" '.[$i].components | length-1' "${sources}")
    for j in $(seq 0 "${componentCount}"); do
        component=$(jq -r --argjson i "${i}" --argjson j "${j}" '.[$i].components[$j]' "${sources}")
        if [[ "${component}" == discovery.relabel.* ]]; then
            discoveryRelabel "${component}"
        fi
        if [[ "${component}" == prometheus.scrape.* ]]; then
            prometheusScrape "${component}"
        fi
    done
    echo
done
