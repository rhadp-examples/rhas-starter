#!/usr/bin/env bash
NAMESPACE=automotive-dev-operator-system

for name in $(oc get imagebuilds -n $NAMESPACE --no-headers -o custom-columns=:metadata.name); do
    oc delete imagebuild "$name" -n $NAMESPACE
    oc delete pod "$name" -n $NAMESPACE --ignore-not-found
done
