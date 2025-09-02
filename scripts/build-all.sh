#!/usr/bin/env bash

set -euxo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && cd .. && pwd)

declare -a PROJECTS=("ActiveSpeakerSample" "CoreCallKitSample" "iOSCoreSample")
DESTINATION="platform=iOS Simulator,name=iPhone 16"

for project in "${PROJECTS[@]}"; do
  echo "--- Building and testing ${project} ---"
  PROJECT_DIR="${ROOT_DIR}/${project}"
  pushd "${PROJECT_DIR}" || exit 1
  
  if [ -d "${project}.xcworkspace" ]; then
    xcodebuild clean build \
      -workspace "${project}.xcworkspace" \
      -scheme "${project}" \
      -destination "${DESTINATION}"
  elif [ -f "${project}.xcodeproj/project.pbxproj" ]; then
    xcodebuild clean build \
      -project "${project}.xcodeproj" \
      -scheme "${project}" \
      -destination "${DESTINATION}"
  else
    echo "ERROR: Could not find project or workspace for ${project}" >&2
    exit 1
  fi
  
  popd || exit 1
  echo "--- Finished ${project} ---"
  echo ""
done

echo "All projects built and tested successfully!"
