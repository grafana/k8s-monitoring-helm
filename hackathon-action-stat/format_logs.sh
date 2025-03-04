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

  # Fetch workflow jobs information, excluding current job
  echo "Fetching workflow run jobs information..."
  if ! JOBS_JSON=$(gh run view "${WORKFLOW_RUN_ID}" --json jobs -q '{jobs: .jobs | map(select(.name != env.GITHUB_JOB))}' 2>&1); then
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

  # Initialize jobs array and look through json formatted jobs data
  JOBS_ARRAY=()
  COUNT=0

  for job in $(echo "${JOBS_JSON}" | jq -c '.jobs[]'); do
      COUNT=$((COUNT + 1))
      JOB_ID=$(echo "${job}" | jq -r '.databaseId')
      JOB_NAME=$(echo "${job}" | jq -r '.name')
      
      echo "Processing job ${COUNT} of ${JOBS_COUNT}:"
      echo "${JOB_NAME} (ID: ${JOB_ID})"
      
      # Fetch logs for this job
      echo "Fetching job logs..."
      # JOB_LOGS is the full logs for the job in text format, to be used for step extraction
      JOB_LOGS=$(gh run view --job "${JOB_ID}" --log)
      # JOB_LOGS_BASE64 is the full logs for the job in base64 format, to be used for job-level logs
      JOB_LOGS_BASE64=$(echo "${JOB_LOGS}" | base64 -w 0)
      
      # Process each step from the detailed job JSON
      echo "Processing job steps..."
      
      # Initialize steps array
      STEPS_ARRAY=()

      for step in $(echo "${job}" | jq -c '.steps[]'); do
          STEP_NAME=$(echo "${step}" | jq -r '.name')
          STEP_NUMBER=$(echo "${step}" | jq -r '.number')
          
          echo "Processing step: ${STEP_NAME}"
          
          # Extract logs for this specific step
          STEP_LOGS=$(extract_step_logs "${JOB_LOGS}" "${STEP_NAME}" "${STEP_NUMBER}")
          
          # Store step data with logs
          STEPS_ARRAY+=("$(jq -n \
              --argjson step "${step}" \
              --arg step_logs "${STEP_LOGS}" \
              '{step: $step, step_logs: $step_logs}')")
      done
      
      # Convert steps array to JSON
      STEPS_JSON=$(printf "%s\n" "${STEPS_ARRAY[@]}" | jq -s '.')
      
      # Store job data with both job-level and step-level logs
      JOBS_ARRAY+=("$(jq -n \
          --argjson job "${job}" \
          --arg jobs_full_logs "${JOB_LOGS_BASE64}" \
          --argjson steps "${STEPS_JSON}" \
          '{job: $job, jobs_full_logs: $jobs_full_logs, steps: $steps}')")
  done

  # Convert jobs array to JSON
  JOBS_JSON=$(printf "%s\n" "${JOBS_ARRAY[@]}" | jq -s '.')

  # Final JSON structure
  JSON_OUTPUT=$(jq -n \
      --arg repo "${REPOSITORY_NAME}" \
      --arg commit_sha "${COMMIT_SHA}" \
      --arg workflow "${WORKFLOW_NAME}" \
      --arg run_id "${WORKFLOW_RUN_ID}" \
      --argjson jobs "${JOBS_JSON}" \
      '{repository: $repo, commit_sha: $commit_sha, workflow: $workflow, workflow_id: $run_id, jobs: $jobs}')

  # Write to file
  echo "${JSON_OUTPUT}" > workflow_jobs.json

  # Print confirmation
  echo "Workflow jobs information written to workflow_jobs.json" 
}

# If the script is being executed directly (not sourced), run main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# Extract step logs
extract_step_logs() {
  local full_logs="$1"
  local step_name="$2"
  local step_number="$3"
  
  # Create pattern for step start and end
  local start_pattern="##[group]Run ${step_name}"
  local end_pattern="##[endgroup]"
  
  # If step name contains special characters, try matching with step number
  if [[ "${step_name}" =~ [\[\]\(\)\{\}\|\*\+\?\^\$] ]]; then
      start_pattern="##\\[group\\]Run step ${step_number}"
  fi
  
  # Extract logs between start and end patterns
  echo "${full_logs}" | awk -v start="${start_pattern}" -v end="${end_pattern}" '
      $0 ~ start {p=1; next}
      $0 ~ end {p=0}
      p {print}
  ' | base64 -w 0 || true
}
