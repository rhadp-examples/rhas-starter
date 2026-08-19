#!/usr/bin/env bash
NAMESPACE=automotive-dev-operator-system

# Cleanup image builds. This will eventually also delete PipelineRuns and TasksRuns etc.
echo "Cleaning up image builds"

for name in $(oc get imagebuilds -n $NAMESPACE --no-headers -o custom-columns=:metadata.name); do
    oc delete imagebuild "$name" -n $NAMESPACE
    #oc delete pod "$name" -n $NAMESPACE --ignore-not-found
done
