#!/usr/bin/env bash

createGKECluster() {
  local clusterName=$1
  local clusterConfig=$2

  args=""
  location=$(yq eval '.args.location // ""' "${clusterConfig}")
  if [ -n "${location}" ]; then args="--location ${location}"; fi
  region=$(yq eval '.args.region // ""' "${clusterConfig}")
  if [ -n "${region}" ]; then args="--region ${region}"; fi
  zone=$(yq eval '.args.zone // ""' "${clusterConfig}")
  if [ -n "${zone}" ]; then args="--zone ${zone}"; fi

  if ! eval "gcloud container clusters list --format=\"value(name)\" ${args}" | grep -q "${clusterName}"; then
    args=$(yq eval -r -o=json '.args | to_entries | map("--" + .key + "=" + (.value | tostring)) | join(" ")' "${clusterConfig}")
    bashCommand="gcloud container clusters create \"${clusterName}\" ${args}"
    echo "${bashCommand}"
    eval "${bashCommand}"
  fi
}

createGKEAutopilotCluster() {
  local clusterName=$1
  local clusterConfig=$2

  args=""
  location=$(yq eval '.args.location // ""' "${clusterConfig}")
  if [ -n "${location}" ]; then args="--location ${location}"; fi
  region=$(yq eval '.args.region // ""' "${clusterConfig}")
  if [ -n "${region}" ]; then args="--region ${region}"; fi
  zone=$(yq eval '.args.zone // ""' "${clusterConfig}")
  if [ -n "${zone}" ]; then args="--zone ${zone}"; fi

  if ! eval "gcloud container clusters list --format=\"value(name)\" ${args}" | grep -q "${clusterName}"; then
    args=$(yq eval -r -o=json '.args | to_entries | map("--" + .key + "=" + (.value | tostring)) | join(" ")' "${clusterConfig}")
    bashCommand="gcloud container clusters create-auto \"${clusterName}\" ${args}"
    echo "${bashCommand}"
    eval "${bashCommand}"
  fi
}

deleteGKECluster() {
  local clusterName=$1
  local clusterConfig=$2

  args=""
  location=$(yq eval '.args.location // ""' "${clusterConfig}")
  if [ -n "${location}" ]; then args="--location ${location}"; fi
  region=$(yq eval '.args.region // ""' "${clusterConfig}")
  if [ -n "${region}" ]; then args="--region ${region}"; fi
  zone=$(yq eval '.args.zone // ""' "${clusterConfig}")
  if [ -n "${zone}" ]; then args="--zone ${zone}"; fi

  if eval "gcloud container clusters list --format=\"value(name)\" ${args}" | grep -q "${clusterName}"; then
    bashCommand="gcloud container clusters delete \"${clusterName}\" --quiet ${args}"
    echo "${bashCommand}"
    eval "${bashCommand}"
  fi
}