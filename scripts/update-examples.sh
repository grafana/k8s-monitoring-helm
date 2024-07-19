#!/bin/bash

scriptsDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

examples=$(find "${scriptsDir}/../examples" -mindepth 1 -maxdepth 1 -type d)
for example in $examples; do
  exampleName=$(basename "${example}")
  valuesFile="${example}/values.yaml"
  readmeFile="${example}/README.md"
  if [ ! -f "${valuesFile}" ] || [ ! -f "${readmeFile}" ]; then
    continue
  fi

  echo "Setting ${exampleName}'s README.md to use the current values.yaml file."
  startLine=$(grep -n '<!-- values file start -->' "${readmeFile}" | cut -d: -f1)
  endLine=$(grep -n '<!-- values file end -->' "${readmeFile}" | cut -d: -f1)
  if [ -z "${startLine}" ] || [ -z "${endLine}" ]; then
    continue
  fi

  head -n "${startLine}" < "${readmeFile}" > "${readmeFile}.tmp"
  # shellcheck disable=SC2129
  echo '```yaml' >> "${readmeFile}.tmp"
  cat "${valuesFile}" >> "${readmeFile}.tmp"
  echo '```' >> "${readmeFile}.tmp"
  tail -n +"${endLine}" < "${readmeFile}" >> "${readmeFile}.tmp"
  mv "${readmeFile}.tmp" "${readmeFile}"
done

numberOfExamples=$(echo "${examples}" | wc -l | xargs)
make -C "${scriptsDir}/.." -j "${numberOfExamples}" generate-example-outputs
