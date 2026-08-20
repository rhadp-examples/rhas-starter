#!/usr/bin/env bash
NAMESPACE=automotive-dev-operator-system

# Cleanup image builds. This will eventually also delete PipelineRuns and TasksRuns etc.
echo "Cleaning up image builds"

# get the GitHub repository name from the remote URL
GIT_REMOTE_URL=$(git remote get-url origin)
GIT_REPO=${GIT_REMOTE_URL#*github.com[:/]}
GIT_REPO=${GIT_REPO%.git}
# BUILDER_NAMESPACE normalization for use in kubernetes
BUILDER_NAMESPACE=buildspace-$(echo "$GIT_REPO" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9-]/-/g; s/-\+/-/g; s/^-//; s/-$//' | cut -c1-63)

echo "Cleaning up builder namespace: $BUILDER_NAMESPACE"
for name in $(oc get pipelineruns -n $BUILDER_NAMESPACE --no-headers -o custom-columns=:metadata.name); do
    oc delete pipelineruns "$name" -n $BUILDER_NAMESPACE
done

echo "---"

echo "Cleaning up namespace: $NAMESPACE"
for name in $(oc get imagebuilds -n $NAMESPACE --no-headers -o custom-columns=:metadata.name); do
    oc delete imagebuild "$name" -n $NAMESPACE
done
