#!/bin/bash

usage() {
  echo "USAGE: test-runner.sh [--show-diffs] [--stop-on-failure] [test-dir]"
  echo ""
  echo "Runs the tests"
  echo ""
  echo "  --show-diffs      - Shows the differences from the expected value"
  echo "  --stop-on-failure - Stop running any more tests after the first failure"
  echo "  <test-dir>        - The test directory to test, default is to run all tests"
}

helmChartPath=.
examplesPath=${helmChartPath}/docs/examples

showDiffs=false
stopOnFailure=false

passed=0
count=0

RED="\033[31m"
GREEN="\033[32m"
ENDCOLOR="\033[0m"

while [ $# -gt 0 ]; do
  case "$1" in
    --show-diffs)
      showDiffs=true
      ;;
    --stop-on-failure)
      stopOnFailure=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unexpected argument: $1"
      usage
      exit 1
  esac
  shift
done

for inputFile in "${examplesPath}"/*/values.yaml
do
  testDir=$(dirname "${inputFile}")
  expectedOutputFile="${testDir}/output.yaml"

  count=$((count+1))
  output=$(helm template k8smon "${helmChartPath}" -f "${inputFile}")
  if diffFromExpected=$(diff <(echo "${output}") "${expectedOutputFile}"); then
    passed=$((passed+1))  
    echo -ne "${GREEN}*${ENDCOLOR}"
  else
    echo
    echo -e "${RED}test failed:${ENDCOLOR} ${inputFile}"

    if [ "${showDiffs}" == true ]; then
      echo "$diffFromExpected"
    fi

    if [ "${stopOnFailure}" == true ]; then
      exit 1
    fi
  fi

  count=$((count+1))
  if lintOutput=$(helm lint "${helmChartPath}" -f "${inputFile}"); then
    passed=$((passed+1))
    echo -ne "${GREEN}*${ENDCOLOR}"
  else
    echo
    echo -e "${RED}lint failed:${ENDCOLOR} ${inputFile}"

    if [ "${showDiffs}" == true ]; then
      echo "$lintOutput"
    fi

    if [ "${stopOnFailure}" == true ]; then
      exit 1
    fi
  fi
done

echo
echo

echo "$passed/$count"
if [ $passed == $count ]; then
  echo -e "${GREEN}All tests passed!${ENDCOLOR}"
  exit 0
fi

exit 1
