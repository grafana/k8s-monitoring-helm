#!/usr/bin/env bash

source "./scripts/includes/utils.sh"
source "./scripts/includes/logging.sh"

# check to see if alloy is installed
if [[ "$(command -v alloy || true)" = "" ]]; then
  emergency "alloy is required if running lint locally, see: (https://grafana.com/docs/alloy/latest/) or run: brew install alloy";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

# Initialize a flag variable
format="console"

# Loop through all arguments
for arg in "$@"
do
  if [[ "${arg}" == "--format=checkstyle" ]]; then
    # Set the flag to true if the specific argument is found
    format="checkstyle"
    break
  fi
done

if [[ "${format}" == "console" ]]; then
  # output the heading
  heading "Kubernetes Monitoring Helm" "Performing Alloy Lint"
fi

statusCode=0
checkstyle='<?xml version="1.0" encoding="utf-8"?><checkstyle version="4.3">'

while read -r file; do
  # add file to checkstyle output
  checkstyle="${checkstyle}<file name=\"${file}\">"
  message=$(alloy fmt "${file}" 2>&1)
  currentCode="$?"
  message=$(echo "${message}" | grep -v "Error: encountered errors during formatting")

  # if the current code is 0, output the file name for logging purposes
  if [[ "${currentCode}" == 0 ]]; then
    # output to console only if the format is console
    if [[ "${format}" == "console" ]]; then
      echo -e "\\x1b[32m${file}\\x1b[0m: no issues found"
    fi
    checkstyle="${checkstyle}</file>"
  else
    # output to console only if the format is console
    if [[ "${format}" == "console" ]]; then
      echo -e "\\x1b[31m${file}\\x1b[0m: issues found"
    fi
    # loop each found issue
    while IFS= read -r row; do
      # Process each line here
      line=$(echo "${row}" | awk -F ':' '{print $2}')
      column=$(echo "${row}" | awk -F ':' '{print $3}')
      error=$(echo "${row}" | cut -d':' -f4- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed -e 's/"/\&quot;/g' | xargs)
      checkstyle="${checkstyle}<error line=\"${line}\" column=\"${column}\" severity=\"error\" message=\"${error}\" source=\"alloy\"/>"
      # output to console only if the format is console
      if [[ "${format}" == "console" ]]; then
        echo "  - ${row}"
      fi
    done <<< "${message}"
    checkstyle="${checkstyle}</file>"
  fi
  # only override the statusCode if it is 0
  if [[ "${statusCode}" == 0 ]]; then
    statusCode="${currentCode}"
  fi
done < <(find . -type f -name "*.river" -not -path "./node_modules/*" -not -path "./.git/*" || true)

checkstyle="${checkstyle}</checkstyle>"

if [[ "${format}" == "checkstyle" ]]; then
  echo -n "${checkstyle}"
else
  echo ""
  echo ""
fi

# if the script was called by another, send a valid exit code
if [[ "${sourced}" == "1" ]]; then
  return "${statusCode}"
else
  exit "${statusCode}"
fi
