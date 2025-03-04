#!/bin/bash
# Fail on error and unbound variables
set -eu

function main() {
  # Ensure GitHub Actions environment variables are set
  if [[ -z "${GITHUB_RUN_ID:-}" ]]; then
      echo "GITHUB_RUN_ID must be set."
      exit 1
  fi
  WORKFLOW_RUN_ID="${GITHUB_RUN_ID}"

  if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
      echo "Unable to identify repository. GITHUB_REPOSITORY must be set."
      exit 1
  fi
  REPOSITORY_NAME="${GITHUB_REPOSITORY}"

  if [[ -z "${GITHUB_SHA:-}" ]]; then
      echo -e "\033[33mWarning: Unable to identify commit SHA that triggered this workflow run.\033[0m"
  fi
  COMMIT_SHA="${GITHUB_SHA:-}"

  if [[ -z "${GITHUB_WORKFLOW:-}" ]]; then
      echo -e "\033[33mWarning: Unable to identify workflow name.\033[0m"
  fi
  WORKFLOW_NAME="${GITHUB_WORKFLOW:-"unknown"}"

  # Ensure GitHub CLI is authenticated
  if ! gh auth status &>/dev/null; then
      echo "GitHub CLI is not authenticated. Ensure GH_TOKEN is set."
      exit 1
  fi

  # Fetch jobs and steps ID and name, excluding current job
  echo "Fetching workflow run jobs information..."
  if ! JOBS_JSON=$(gh run view "${WORKFLOW_RUN_ID}" --json jobs -jq "
    .jobs[]
    | select(.name != env.GITHUB_JOB)
    | {job_id: .databaseId, job_name: .name, steps: [.steps[] | {step_id: .number, step_name: .name}]}" 2>&1); 
  then
      echo "Error fetching workflow jobs: ${JOBS_JSON}"
      exit 1
  fi

  # Validate JSON output
  if ! echo "${JOBS_JSON}" | jq empty 2>/dev/null; then
      echo "Invalid JSON received from GitHub CLI"
      echo "Raw output: ${JOBS_JSON}"
      exit 1
  fi

  JOBS_COUNT=$(echo "${JOBS_JSON}" | jq '.jobs | length')

  echo "Processing workflow: ${WORKFLOW_NAME} in ${REPOSITORY_NAME}"

  # Initialize jobs array and loop through json formatted jobs data
  JOB_INDEX=0
  
  # Process each job using indices instead of trying to iterate over JSON directly
  while [[ "${JOB_INDEX}" -lt "${JOBS_COUNT}" ]]; do
    # Extract single JSON-formatted job using index
    job=$(echo "${JOBS_JSON}" | jq -c ".jobs[${JOB_INDEX}]")
    JOB_ID=$(echo "${job}" | jq -r '.databaseId')
    JOB_NAME=$(echo "${job}" | jq -r '.name')
    
    echo "Processing job $((JOB_INDEX + 1)) of ${JOBS_COUNT}:"
    echo "${JOB_NAME} (ID: ${JOB_ID})"
    
    # Create directory for job logs if it doesn't exist
    JOB_DIR="/logs/${JOB_ID}_${JOB_NAME}"
    mkdir -p "${JOB_DIR}"

    # Fetch logs for this job
    echo "Fetching job logs..."
    JOB_LOGS=$(gh run view --job "${JOB_ID}" --log)

    # Write full job logs to file
    echo "${JOB_LOGS}" > "/logs/${JOB_DIR}/job-${JOB_ID}.log"

    echo "Processing job steps..."
    
    # Loop through each step in the job
    STEPS_COUNT=$(echo "${job}" | jq '.steps | length')
    STEP_INDEX=0

    while [[ "${STEP_INDEX}" -lt "${STEPS_COUNT}" ]]; do
      step=$(echo "${job}" | jq -c ".steps[${STEP_INDEX}]")
      STEP_NAME=$(echo "${step}" | jq -r '.name')
      STEP_NUMBER=$(echo "${step}" | jq -r '.number')

      echo "Processing step $((STEP_INDEX + 1)) of ${STEPS_COUNT}:"
      echo "Processing step: ${STEP_NAME}"

      STEP_LOG_PATTERN="${JOB_NAME}\t${STEP_NAME}"
      STEP_LOGS=$(echo "${JOB_LOGS}" | grep "^${STEP_LOG_PATTERN}") || echo "No logs found for ${STEP_LOG_PATTERN}"

      # Write step logs to file
      echo "${STEP_LOGS}" > "/logs/${JOB_DIR}/job-${JOB_ID}-step-${STEP_NUMBER}.log"
          
      STEP_INDEX=$((STEP_INDEX + 1))
    done
            
    JOB_INDEX=$((JOB_INDEX + 1))
  done

  # Print confirmation
  echo "Workflow jobs information written to directory /logs/${JOB_DIR}" 
}

# If the script is being executed directly (not sourced), run main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
